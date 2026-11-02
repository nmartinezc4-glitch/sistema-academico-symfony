<?php

namespace App\Controller;

use App\Repository\DashboardReadRepository;
use App\Security\AcademicUser;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class DashboardController extends AbstractController
{
    #[Route('/', name: 'app_dashboard', methods: ['GET'])]
    public function index(DashboardReadRepository $dashboard): Response
    {
        $user = $this->getUser();
        if (!$user instanceof AcademicUser) {
            throw $this->createAccessDeniedException();
        }

        $isCoordination = $this->isGranted('ROLE_COORDINACION');
        $isDirection = $this->isGranted('ROLE_DIRECCION');
        $isTeacher = $this->isGranted('ROLE_DOCENTE');

        if ($this->isGranted('ROLE_GESTION_USUARIOS') && !$isCoordination && !$isDirection && !$isTeacher) {
            return $this->redirectToRoute('app_security_user_index');
        }

        if ($isCoordination) {
            $vm = $dashboard->dashboard();
            if ($vm['period'] === null) {
                $vm['period'] = ['year' => null, 'term' => 'II', 'status' => null];
            }

            return $this->render('dashboard/index.html.twig', ['vm' => $vm]);
        }

        if ($isDirection) {
            $vm = $dashboard->dashboard();
            if ($vm['period'] === null) {
                $vm['period'] = ['year' => null, 'term' => 'II', 'status' => null];
            }

            return $this->render('dashboard/direction.html.twig', ['vm' => $vm]);
        }

        if ($isTeacher) {
            $vm = $dashboard->teacherDashboard($user->getId());
            if ($vm['period'] === null) {
                $vm['period'] = ['year' => null, 'term' => 'II', 'status' => null];
            }

            return $this->render('dashboard/teacher.html.twig', ['vm' => $vm]);
        }

        throw $this->createAccessDeniedException('Tu perfil no tiene acceso al panel académico.');
    }
}
