<?php

namespace App\Controller;

use App\Repository\SecurityReadRepository;
use App\Repository\SecurityWriteRepository;
use App\Security\AcademicUser;
use App\Service\UserPhotoStorage;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[IsGranted('ROLE_GESTION_USUARIOS')]
final class SecurityAdminController extends AbstractController
{
    #[Route('/configuracion/usuarios', name: 'app_security_user_index', methods: ['GET'])]
    public function index(SecurityReadRepository $read): Response
    {
        return $this->render('security/user_index.html.twig', [
            'users' => $read->users(),
            'roles' => $read->roles(),
        ]);
    }

    #[Route('/configuracion/usuarios/nuevo', name: 'app_security_user_new', methods: ['GET', 'POST'])]
    public function create(
        Request $request,
        SecurityReadRepository $read,
        SecurityWriteRepository $write,
        UserPhotoStorage $photos,
    ): Response {
        $form = [
            'email' => '',
            'firstNames' => '',
            'lastNames' => '',
            'roleIds' => [],
            'photoPath' => null,
        ];
        $errors = [];

        if ($request->isMethod('POST')) {
            $form = [
                'email' => trim((string) $request->request->get('email', '')),
                'firstNames' => trim((string) $request->request->get('firstNames', '')),
                'lastNames' => trim((string) $request->request->get('lastNames', '')),
                'roleIds' => array_values(array_filter(array_map('intval', $request->request->all('roleIds')))),
                'photoPath' => null,
            ];
            $password = (string) $request->request->get('password', '');
            $confirmation = (string) $request->request->get('passwordConfirm', '');
            $photo = $request->files->get('photo');

            if ($password !== $confirmation) {
                $errors[] = 'La confirmación de contraseña no coincide.';
            }
            if ($photo !== null && !$photo instanceof UploadedFile) {
                $errors[] = 'La fotografía recibida no es válida.';
            }

            if ($errors === []) {
                $photoPath = null;
                try {
                    if ($photo instanceof UploadedFile) {
                        $photoPath = $photos->store($photo);
                    }

                    $write->createUser(
                        $form['email'],
                        $form['firstNames'],
                        $form['lastNames'],
                        $password,
                        $form['roleIds'],
                        $photoPath,
                    );
                    $this->addFlash('success', 'Usuario institucional creado correctamente.');

                    return $this->redirectToRoute('app_security_user_index');
                } catch (\RuntimeException $e) {
                    if ($photoPath !== null) {
                        $photos->delete($photoPath);
                    }
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('security/user_form.html.twig', [
            'mode' => 'create',
            'form' => $form,
            'roles' => $read->roles(),
            'errors' => $errors,
        ]);
    }

    #[Route('/configuracion/usuarios/{id}/editar', name: 'app_security_user_edit', methods: ['GET', 'POST'], requirements: ['id' => '\\d+'])]
    public function edit(
        int $id,
        Request $request,
        SecurityReadRepository $read,
        SecurityWriteRepository $write,
        UserPhotoStorage $photos,
    ): Response {
        $user = $read->findUser($id);
        if ($user === null) {
            throw $this->createNotFoundException();
        }

        $roles = $read->roles();
        $roleMap = [];
        foreach ($roles as $role) {
            $roleMap[$role['code']] = $role['id'];
        }

        $form = [
            'email' => $user['email'],
            'firstNames' => $user['firstNames'],
            'lastNames' => $user['lastNames'],
            'active' => $user['active'],
            'photoPath' => $user['photoPath'],
            'roleIds' => array_values(array_filter(array_map(
                static fn (string $code): ?int => $roleMap[$code] ?? null,
                $user['roles'],
            ))),
        ];
        $errors = [];

        if ($request->isMethod('POST')) {
            $form = [
                'email' => trim((string) $request->request->get('email', '')),
                'firstNames' => trim((string) $request->request->get('firstNames', '')),
                'lastNames' => trim((string) $request->request->get('lastNames', '')),
                'active' => $request->request->getBoolean('active'),
                'photoPath' => $user['photoPath'],
                'roleIds' => array_values(array_filter(array_map('intval', $request->request->all('roleIds')))),
            ];
            $newPassword = trim((string) $request->request->get('password', ''));
            $confirmation = trim((string) $request->request->get('passwordConfirm', ''));
            $photo = $request->files->get('photo');
            $removePhoto = $request->request->getBoolean('removePhoto');

            if ($newPassword !== $confirmation) {
                $errors[] = 'La confirmación de contraseña no coincide.';
            }
            if ($photo !== null && !$photo instanceof UploadedFile) {
                $errors[] = 'La fotografía recibida no es válida.';
            }

            if ($errors === []) {
                $previousPhotoPath = $user['photoPath'];
                $photoPath = $removePhoto ? null : $previousPhotoPath;
                $newPhotoPath = null;

                try {
                    if ($photo instanceof UploadedFile) {
                        $newPhotoPath = $photos->store($photo);
                        $photoPath = $newPhotoPath;
                    }

                    $actor = $this->getUser();
                    $write->updateUser(
                        $id,
                        $form['email'],
                        $form['firstNames'],
                        $form['lastNames'],
                        $form['active'],
                        $form['roleIds'],
                        $newPassword !== '' ? $newPassword : null,
                        $photoPath,
                        $actor instanceof AcademicUser ? $actor->getId() : null,
                    );

                    if ($previousPhotoPath !== null && $previousPhotoPath !== $photoPath) {
                        $photos->delete($previousPhotoPath);
                    }

                    $this->addFlash('success', 'Usuario actualizado correctamente.');

                    return $this->redirectToRoute('app_security_user_index');
                } catch (\RuntimeException $e) {
                    if ($newPhotoPath !== null) {
                        $photos->delete($newPhotoPath);
                    }
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('security/user_form.html.twig', [
            'mode' => 'edit',
            'user' => $user,
            'form' => $form,
            'roles' => $roles,
            'errors' => $errors,
        ]);
    }
}
