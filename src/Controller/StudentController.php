<?php

namespace App\Controller;

use App\Repository\AcademicOperationsReadRepository;
use App\Repository\AcademicOperationsWriteRepository;
use App\Repository\CurriculumReadRepository;
use App\Repository\StudentReadRepository;
use App\Repository\StudentWriteRepository;
use App\Repository\TeachingAssignmentReadRepository;
use App\Security\AcademicAccessScope;
use App\Security\AcademicUser;
use App\Ui\Paginator;
use App\Service\StudentPhotoStorage;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class StudentController extends AbstractController
{
    #[Route('/alumnos', name: 'app_student_index', methods: ['GET'])]
    public function index(Request $request, StudentReadRepository $students, AcademicAccessScope $scope): Response
    {
        $allowedStudentIds = $scope->studentIds();
        $q = trim((string) $request->query->get('q', ''));
        $career = trim((string) $request->query->get('career', ''));
        $curriculum = trim((string) $request->query->get('curriculum', ''));
        $status = strtoupper(trim((string) $request->query->get('status', '')));
        $entryYearRaw = trim((string) $request->query->get('entry_year', ''));
        $entryYear = ctype_digit($entryYearRaw) ? (int) $entryYearRaw : null;

        $progressMin = max(0, min(100, (int) $request->query->get('progress_min', 0)));
        $progressMax = max(0, min(100, (int) $request->query->get('progress_max', 100)));
        if ($progressMin > $progressMax) {
            [$progressMin, $progressMax] = [$progressMax, $progressMin];
        }

        $allowedOrders = ['apellidos-asc', 'apellidos-desc', 'nombre-asc', 'avance-desc', 'avance-asc', 'codigo-asc'];
        $order = (string) $request->query->get('orden', 'apellidos-asc');
        if (!\in_array($order, $allowedOrders, true)) {
            $order = 'apellidos-asc';
        }

        $availableStatuses = $students->statuses();
        if ($status !== '' && !\in_array($status, $availableStatuses, true)) {
            $status = '';
        }

        $filteredTotal = $students->countSearch(
            q: $q,
            careerId: $career !== '' ? $career : null,
            curriculumId: $curriculum !== '' ? $curriculum : null,
            status: $status !== '' ? $status : null,
            entryYear: $entryYear,
            progressMin: $progressMin,
            progressMax: $progressMax,
            allowedStudentIds: $allowedStudentIds,
        );

        $pager = Paginator::fromRequest($request, $filteredTotal);
        $items = $students->searchPage(
            q: $q,
            careerId: $career !== '' ? $career : null,
            curriculumId: $curriculum !== '' ? $curriculum : null,
            status: $status !== '' ? $status : null,
            entryYear: $entryYear,
            progressMin: $progressMin,
            progressMax: $progressMax,
            order: $order,
            limit: $pager->perPage,
            offset: $pager->offset(),
            allowedStudentIds: $allowedStudentIds,
        );

        $items = array_map(
            fn (array $student) => $student + [
                'url' => $this->generateUrl('app_student_show', ['id' => $student['id']]),
            ],
            $items,
        );

        return $this->render('student/index.html.twig', [
            'items' => $items,
            'q' => $q,
            'career' => $career,
            'curriculum' => $curriculum,
            'status' => $status,
            'entryYear' => $entryYear,
            'progressMin' => $progressMin,
            'progressMax' => $progressMax,
            'order' => $order,
            'total' => $students->count($allowedStudentIds),
            'filteredTotal' => $filteredTotal,
            'metrics' => $students->metrics($allowedStudentIds),
            'resultsCount' => $students->resultsCount($allowedStudentIds),
            'careers' => $students->careers(),
            'curricula' => $students->curricula(),
            'entryYears' => $students->entryYears(),
            'statuses' => $availableStatuses,
            'pager' => $pager,
        ]);
    }

    #[Route('/alumnos/nuevo', name: 'app_student_new', methods: ['GET', 'POST'])]
    public function create(
        Request $request,
        CurriculumReadRepository $catalog,
        StudentWriteRepository $write,
        StudentPhotoStorage $photos,
    ): Response {
        $careers = $catalog->careers();
        $curricula = $catalog->curricula();
        $errors = [];
        $form = [
            'firstNames' => '',
            'lastNames' => '',
            'birthDate' => '',
            'address' => '',
            'programStartDate' => '',
            'curriculumId' => 0,
            'careerFilter' => '',
        ];

        if ($request->isMethod('POST')) {
            $firstNames = trim((string) $request->request->get('firstNames', ''));
            $lastNames = trim((string) $request->request->get('lastNames', ''));
            $birthDate = trim((string) $request->request->get('birthDate', ''));
            $address = trim((string) $request->request->get('address', ''));
            $programStart = trim((string) $request->request->get('programStartDate', ''));
            $curriculumId = (int) $request->request->get('curriculumId', 0);
            $careerFilter = trim((string) $request->request->get('careerFilter', ''));

            $form = [
                'firstNames' => $firstNames,
                'lastNames' => $lastNames,
                'birthDate' => $birthDate,
                'address' => $address,
                'programStartDate' => $programStart,
                'curriculumId' => $curriculumId,
                'careerFilter' => $careerFilter,
            ];

            if ($firstNames === '' || $lastNames === '') {
                $errors[] = 'Nombres y apellidos son obligatorios.';
            }
            if (mb_strlen($address) > 255) {
                $errors[] = 'La dirección no puede exceder 255 caracteres.';
            }

            $birth = self::dateInput($birthDate);
            if ($birth === null) {
                $errors[] = 'La fecha de nacimiento no es válida.';
            } elseif ($birth > new \DateTimeImmutable('today')) {
                $errors[] = 'La fecha de nacimiento no puede estar en el futuro.';
            }

            $programStartDate = self::dateInput($programStart);
            if ($programStartDate === null) {
                $errors[] = 'La fecha de ingreso no es válida.';
            } elseif ($birth !== null && $programStartDate < $birth) {
                $errors[] = 'La fecha de ingreso no puede ser anterior a la fecha de nacimiento.';
            }

            if ($curriculumId <= 0 || $programStartDate === null || !$write->curriculumAvailableForDate($curriculumId, $programStart)) {
                $errors[] = 'Selecciona un pensum activo y vigente para la fecha de ingreso.';
            }

            $photo = $request->files->get('photo');
            if ($photo !== null && !$photo instanceof UploadedFile) {
                $errors[] = 'La fotografía recibida no es válida.';
            }

            if ($errors === []) {
                $photoPath = null;
                try {
                    if ($photo instanceof UploadedFile) {
                        $photoPath = $photos->store($photo);
                    }

                    $ids = $write->create(
                        $firstNames,
                        $lastNames,
                        $birthDate,
                        $address !== '' ? $address : null,
                        $curriculumId,
                        $programStart,
                        $photoPath,
                    );

                    $this->addFlash('success', sprintf('Estudiante registrado correctamente con carné %s.', $ids['code']));

                    return $this->redirectToRoute('app_student_show', ['id' => $ids['studentId']]);
                } catch (\RuntimeException $e) {
                    if ($photoPath !== null) {
                        $photos->delete($photoPath);
                    }
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('student/new.html.twig', [
            'careers' => $careers,
            'curricula' => $curricula,
            'errors' => $errors,
            'form' => $form,
        ]);
    }

    #[Route('/alumnos/{id}', name: 'app_student_show', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function show(
        int $id,
        StudentReadRepository $students,
        TeachingAssignmentReadRepository $assignments,
        AcademicAccessScope $scope,
    ): Response {
        if (!$scope->canViewStudent($id)) {
            throw $this->createAccessDeniedException('Este estudiante no está asignado a tu docencia.');
        }

        $student = $students->findProfile($id);
        if (!$student) {
            throw $this->createNotFoundException();
        }

        $canGradeStudent = false;
        if ($this->isGranted('ROLE_COORDINACION')) {
            $canGradeStudent = true;
        } elseif ($this->isGranted('ROLE_DOCENTE')) {
            $user = $this->getUser();
            $canGradeStudent = $user instanceof AcademicUser
                && $assignments->canGradeStudent($user->getId(), $id);
        }

        return $this->render('student/show.html.twig', [
            'vm' => $student,
            'results' => $students->results($id),
            'periods' => $students->periods($id),
            'canGradeStudent' => $canGradeStudent,
        ]);
    }

    #[Route('/alumnos/{id}/inscripcion', name: 'app_student_enrollment', methods: ['GET', 'POST'], requirements: ['id' => '\\d+'])]
    public function enrollment(
        int $id,
        Request $request,
        StudentReadRepository $students,
        AcademicOperationsReadRepository $academicRead,
        AcademicOperationsWriteRepository $academicWrite,
    ): Response {
        $student = $students->findProfile($id);
        if (!$student) {
            throw $this->createNotFoundException();
        }

        $program = $students->program($id);
        if (!$program) {
            throw $this->createNotFoundException('El estudiante no tiene programa académico asociado.');
        }

        $errors = [];
        $form = [
            'periodId' => '',
            'cycleId' => '',
            'sectionId' => '',
        ];

        if ($request->isMethod('POST')) {
            $form = [
                'periodId' => trim((string) $request->request->get('periodId', '')),
                'cycleId' => trim((string) $request->request->get('cycleId', '')),
                'sectionId' => trim((string) $request->request->get('sectionId', '')),
            ];

            foreach (['periodId' => 'período', 'cycleId' => 'ciclo', 'sectionId' => 'sección'] as $key => $label) {
                if (!ctype_digit($form[$key])) {
                    $errors[] = sprintf('Selecciona un %s válido.', $label);
                }
            }

            if ($errors === []) {
                try {
                    $academicWrite->createEnrollment(
                        $id,
                        (int) $form['periodId'],
                        (int) $form['cycleId'],
                        (int) $form['sectionId'],
                    );

                    $offerCount = $academicRead->matchingOfferCount(
                        (int) $program['curriculumId'],
                        (int) $form['periodId'],
                        (int) $form['sectionId'],
                    );

                    if ($offerCount > 0) {
                        $this->addFlash('success', sprintf(
                            'Inscripción creada correctamente. Hay %d oferta%s compatible%s con el pensum y la sección.',
                            $offerCount,
                            $offerCount === 1 ? '' : 's',
                            $offerCount === 1 ? '' : 's',
                        ));
                    } else {
                        $this->addFlash('warning', 'Inscripción creada, pero todavía no existen ofertas activas compatibles para ese período, pensum y sección.');
                    }

                    return $this->redirectToRoute('app_student_show', ['id' => $id]);
                } catch (\RuntimeException $e) {
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('student/enrollment.html.twig', [
            'vm' => $student,
            'program' => $program,
            'periods' => $students->periods($id),
            'availablePeriods' => $academicRead->availablePeriods(),
            'cycles' => $academicRead->cyclesForCurriculum((int) $program['curriculumId']),
            'sections' => $academicRead->sections(),
            'errors' => $errors,
            'form' => $form,
        ]);
    }

    #[Route('/alumnos/{id}/editar', name: 'app_student_edit', methods: ['GET', 'POST'], requirements: ['id' => '\\d+'])]
    public function edit(
        int $id,
        Request $request,
        CurriculumReadRepository $catalog,
        StudentReadRepository $students,
        StudentWriteRepository $write,
        StudentPhotoStorage $photos,
    ): Response {
        $student = $students->findProfile($id);
        if (!$student) {
            throw $this->createNotFoundException();
        }

        $program = $students->program($id);
        if (!$program) {
            throw $this->createNotFoundException('El estudiante no tiene programa académico asociado.');
        }

        $history = $students->academicHistory($id);
        $curricula = $catalog->curricula();
        $currentCurriculumId = (int) ($program['curriculumId'] ?? 0);
        if ($currentCurriculumId > 0 && !array_filter($curricula, fn (array $c) => (int) $c['id'] === $currentCurriculumId)) {
            $current = $catalog->curriculum($currentCurriculumId);
            if ($current) {
                array_unshift($curricula, $current);
            }
        }

        $errors = [];
        $form = [];

        if ($request->isMethod('POST')) {
            $firstNames = trim((string) $request->request->get('firstNames', ''));
            $lastNames = trim((string) $request->request->get('lastNames', ''));
            $birthDate = trim((string) $request->request->get('birthDate', ''));
            $address = trim((string) $request->request->get('address', ''));
            $programStart = trim((string) $request->request->get('programStartDate', ''));
            $curriculumId = (int) $request->request->get('curriculumId', 0);
            $careerFilter = trim((string) $request->request->get('careerFilter', ''));
            $programStatus = strtoupper(trim((string) $request->request->get('programStatus', 'ACTIVO')));

            $form = [
                'firstNames' => $firstNames,
                'lastNames' => $lastNames,
                'birthDate' => $birthDate,
                'address' => $address,
                'programStartDate' => $programStart,
                'curriculumId' => $curriculumId,
                'careerFilter' => $careerFilter,
                'programStatus' => $programStatus,
            ];

            if ($firstNames === '' || $lastNames === '') {
                $errors[] = 'Nombres y apellidos son obligatorios.';
            }
            if (mb_strlen($address) > 255) {
                $errors[] = 'La dirección no puede exceder 255 caracteres.';
            }

            $birth = self::dateInput($birthDate);
            if ($birth === null) {
                $errors[] = 'La fecha de nacimiento no es válida.';
            } elseif ($birth > new \DateTimeImmutable('today')) {
                $errors[] = 'La fecha de nacimiento no puede estar en el futuro.';
            }

            $programStartDate = self::dateInput($programStart);
            if ($programStartDate === null) {
                $errors[] = 'La fecha de ingreso no es válida.';
            } elseif ($birth !== null && $programStartDate < $birth) {
                $errors[] = 'La fecha de ingreso no puede ser anterior a la fecha de nacimiento.';
            }

            $sameCurriculum = $curriculumId === (int) ($program['curriculumId'] ?? 0);
            if ($curriculumId <= 0 || $programStartDate === null || !$write->curriculumAvailableForDate($curriculumId, $programStart, $sameCurriculum)) {
                $errors[] = 'El pensum seleccionado no es vigente para la fecha de ingreso.';
            }
            if (!\in_array($programStatus, ['ACTIVO', 'FINALIZADO', 'RETIRADO'], true)) {
                $errors[] = 'El estado del programa no es válido.';
            }
            if ($history['results'] > 0 && $curriculumId !== (int) ($program['curriculumId'] ?? 0)) {
                $errors[] = 'El pensum no puede cambiarse porque el estudiante ya tiene historial de calificaciones.';
            }

            $photo = $request->files->get('photo');
            if ($photo !== null && !$photo instanceof UploadedFile) {
                $errors[] = 'La fotografía recibida no es válida.';
            }

            if ($errors === []) {
                $previousPhotoPath = $student['photoPath'] ?? null;
                $photoPath = $previousPhotoPath;
                $newPhotoPath = null;

                try {
                    if ($photo instanceof UploadedFile) {
                        $newPhotoPath = $photos->store($photo);
                        $photoPath = $newPhotoPath;
                    }

                    $write->update(
                        $id,
                        $firstNames,
                        $lastNames,
                        $birthDate,
                        $address !== '' ? $address : null,
                        $curriculumId,
                        $programStart,
                        $programStatus,
                        $photoPath,
                    );

                    if ($newPhotoPath !== null && $previousPhotoPath !== null && $previousPhotoPath !== $newPhotoPath) {
                        $photos->delete($previousPhotoPath);
                    }

                    $this->addFlash('success', 'Ficha del estudiante actualizada correctamente.');

                    return $this->redirectToRoute('app_student_show', ['id' => $id]);
                } catch (\RuntimeException $e) {
                    if ($newPhotoPath !== null) {
                        $photos->delete($newPhotoPath);
                    }
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('student/edit.html.twig', [
            'vm' => $student,
            'program' => $program,
            'history' => $history,
            'careers' => $catalog->careers(),
            'curricula' => $curricula,
            'errors' => $errors,
            'form' => $form,
        ]);
    }

    #[Route('/alumnos/{id}/eliminar', name: 'app_student_delete', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function delete(
        int $id,
        StudentReadRepository $students,
        StudentWriteRepository $write,
        StudentPhotoStorage $photos,
    ): Response {
        $student = $students->findProfile($id);
        if (!$student) {
            throw $this->createNotFoundException();
        }
        try {
            $write->delete($id);
            $photos->delete($student['photoPath'] ?? null);
            $this->addFlash('success', 'Estudiante eliminado correctamente.');

            return $this->redirectToRoute('app_student_index');
        } catch (\RuntimeException $e) {
            $this->addFlash('danger', $e->getMessage());

            return $this->redirectToRoute('app_student_edit', ['id' => $id]);
        }
    }
    private static function dateInput(string $value): ?\DateTimeImmutable
    {
        if ($value === '') {
            return null;
        }

        $date = \DateTimeImmutable::createFromFormat('!Y-m-d', $value);
        if ($date === false || $date->format('Y-m-d') !== $value) {
            return null;
        }

        return $date;
    }

}
