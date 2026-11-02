<?php

namespace App\Controller;

use App\Repository\StudentReadRepository;
use App\Repository\StudentWriteRepository;
use App\Repository\TeachingAssignmentReadRepository;
use App\Security\AcademicUser;
use App\Security\GradeEntryVoter;
use App\Service\SecurityAuditLogger;
use App\Ui\Paginator;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class GradeController extends AbstractController
{
    #[Route('/evaluacion/notas', name: 'app_grade_entry', methods: ['GET', 'POST'])]
    public function entry(
        Request $request,
        StudentReadRepository $students,
        StudentWriteRepository $write,
        TeachingAssignmentReadRepository $assignments,
        SecurityAuditLogger $audit,
    ): Response {
        $user = $this->getUser();
        if (!$user instanceof AcademicUser) {
            throw $this->createAccessDeniedException();
        }

        $restrictedTeacher = $this->isGranted('ROLE_DOCENTE')
            && !$this->isGranted('ROLE_COORDINACION')
            && !$this->isGranted('ROLE_DIRECCION');
        $allowedStudentIds = $restrictedTeacher ? $assignments->studentIdsForUser($user->getId()) : null;
        $assignedOfferings = $restrictedTeacher ? $assignments->assignedOfferingsForUser($user->getId()) : [];

        $studentId = $this->resolveStudentId($request, $students, $assignments, $user, $restrictedTeacher);

        if ($studentId === null) {
            return $this->studentSelector($request, $students, $allowedStudentIds, $assignedOfferings);
        }

        if ($allowedStudentIds !== null && !$assignments->canGradeStudent($user->getId(), $studentId)) {
            $audit->log('NOTAS_ACCESO_DENEGADO', 'ESTUDIANTE', $studentId, [
                'reason' => 'STUDENT_OUTSIDE_ASSIGNED_OFFERINGS',
            ]);

            throw $this->createNotFoundException('El estudiante solicitado no está disponible en tus asignaciones docentes.');
        }

        $student = $students->findProfile($studentId);
        if (!$student) {
            throw $this->createNotFoundException();
        }

        $enrollments = $students->gradeEntryEnrollments($studentId);
        if ($restrictedTeacher) {
            $allowedEnrollmentIds = $assignments->enrollmentIdsForUser($user->getId(), $studentId);
            $enrollments = array_values(array_filter(
                $enrollments,
                static fn (array $row): bool => in_array((int) $row['enrollmentId'], $allowedEnrollmentIds, true),
            ));
        }
        if ($enrollments === []) {
            return $this->render('grade/entry.html.twig', [
                'vm' => $student,
                'enrollments' => [],
                'selectedEnrollment' => null,
                'currentRows' => [],
                'previousRows' => [],
                'otherRows' => [],
                'summary' => [
                    'rows' => 0,
                    'editable' => 0,
                    'graded' => 0,
                    'pending' => 0,
                    'blocked' => 0,
                ],
                'posted' => [],
                'formErrors' => [],
                'teacherMode' => $restrictedTeacher,
            ]);
        }

        $selectedEnrollment = $this->resolveEnrollment($request, $enrollments);
        $rows = $students->gradeEntryRows($studentId, (int) $selectedEnrollment['enrollmentId']);
        if ($restrictedTeacher) {
            $allowedOfferings = array_fill_keys($assignments->offeringIdsForUser($user->getId()), true);
            $rows = array_values(array_filter(
                $rows,
                static fn (array $row): bool => $row['offeringId'] !== null && isset($allowedOfferings[(int) $row['offeringId']]),
            ));
        }

        $posted = $request->isMethod('POST') ? $request->request->all('grades') : [];
        $formErrors = [];

        if ($request->isMethod('POST')) {
            $entries = $this->buildEntries($rows, $posted, $formErrors);

            if ($formErrors === []) {
                try {
                    foreach ($entries as $entry) {
                        $this->denyAccessUnlessGranted(GradeEntryVoter::EDIT, $entry['offeringId']);
                    }

                    $written = $write->saveGrades($entries);
                    if ($written > 0) {
                        $audit->log('NOTAS_GUARDADAS', 'ESTUDIANTE', $studentId, [
                            'enrollmentId' => (int) $selectedEnrollment['enrollmentId'],
                            'offeringIds' => array_values(array_map(
                                static fn (array $entry): int => $entry['offeringId'],
                                $entries,
                            )),
                            'written' => $written,
                        ]);
                    }
                    $this->addFlash(
                        'success',
                        $written > 0
                            ? sprintf('%d nota%s guardada%s correctamente.', $written, $written === 1 ? '' : 's', $written === 1 ? '' : 's')
                            : 'Sin cambios: las notas no se modificaron.',
                    );
                } catch (\RuntimeException $e) {
                    $formErrors[] = $e->getMessage();
                }
            }

            if ($formErrors === []) {
                return $this->redirectToRoute('app_grade_entry', [
                    'student' => $studentId,
                    'enrollment' => $selectedEnrollment['enrollmentId'],
                ]);
            }
        }

        $currentRows = [];
        $previousRows = [];
        $otherRows = [];

        foreach ($rows as $row) {
            match ($row['origin']) {
                'CICLO_ACTUAL' => $currentRows[] = $row,
                'CICLO_ANTERIOR' => $previousRows[] = $row,
                default => $otherRows[] = $row,
            };
        }

        return $this->render('grade/entry.html.twig', [
            'vm' => $student,
            'enrollments' => $enrollments,
            'selectedEnrollment' => $selectedEnrollment,
            'currentRows' => $currentRows,
            'previousRows' => $previousRows,
            'otherRows' => $otherRows,
            'summary' => $this->gradeSummary($rows),
            'posted' => $posted,
            'formErrors' => $formErrors,
            'teacherMode' => $restrictedTeacher,
        ]);
    }

    /**
     * @param list<int>|null $allowedStudentIds
     * @param list<array<string,mixed>> $assignedOfferings
     */
    private function studentSelector(
        Request $request,
        StudentReadRepository $students,
        ?array $allowedStudentIds,
        array $assignedOfferings,
    ): Response {
        $q = trim((string) $request->query->get('q', ''));
        $career = trim((string) $request->query->get('career', ''));

        if ($allowedStudentIds === null) {
            $filteredTotal = $students->countTranscriptSearch(
                q: $q,
                careerId: $career !== '' ? $career : null,
                history: 'with',
            );
            $pager = Paginator::fromRequest($request, $filteredTotal);
            $items = $students->searchTranscriptPage(
                q: $q,
                careerId: $career !== '' ? $career : null,
                history: 'with',
                order: 'apellidos-asc',
                limit: $pager->perPage,
                offset: $pager->offset(),
            );
            $totalWithEnrollment = $students->countTranscriptSearch(history: 'with');
        } else {
            // Docente: la autorización forma parte del SQL. Nunca recuperamos
            // el directorio global para filtrarlo posteriormente en PHP.
            $career = '';
            $filteredTotal = $students->countTranscriptSearchByIds($allowedStudentIds, $q);
            $pager = Paginator::fromRequest($request, $filteredTotal);
            $items = $students->searchTranscriptPageByIds(
                studentIds: $allowedStudentIds,
                q: $q,
                limit: $pager->perPage,
                offset: $pager->offset(),
            );
            $totalWithEnrollment = count($allowedStudentIds);
        }

        return $this->render('grade/index.html.twig', [
            'items' => $items,
            'q' => $q,
            'career' => $career,
            'careers' => $allowedStudentIds === null ? $students->careers() : [],
            'filteredTotal' => $filteredTotal,
            'totalWithEnrollment' => $totalWithEnrollment,
            'pager' => $pager,
            'teacherMode' => $allowedStudentIds !== null,
            'assignedOfferings' => $assignedOfferings,
        ]);
    }

    private function resolveStudentId(
        Request $request,
        StudentReadRepository $students,
        TeachingAssignmentReadRepository $assignments,
        AcademicUser $user,
        bool $restrictedTeacher,
    ): ?int {
        $raw = trim((string) $request->query->get('student', ''));
        if ($raw === '') {
            return null;
        }

        if (ctype_digit($raw)) {
            return (int) $raw;
        }

        $code = trim(explode('·', $raw)[0]);
        $id = $restrictedTeacher
            ? $assignments->studentIdFromCodeForUser($user->getId(), $code)
            : $students->idFromCode($code);

        if ($id === null) {
            throw $this->createNotFoundException('El estudiante solicitado no está disponible.');
        }

        return $id;
    }

    /**
     * @param list<array<string, mixed>> $enrollments
     *
     * @return array<string, mixed>
     */
    private function resolveEnrollment(Request $request, array $enrollments): array
    {
        $raw = trim((string) $request->query->get('enrollment', ''));
        if ($raw === '') {
            return $enrollments[0];
        }

        if (!ctype_digit($raw)) {
            throw $this->createNotFoundException('La inscripción académica indicada no es válida.');
        }

        $id = (int) $raw;
        foreach ($enrollments as $enrollment) {
            if ((int) $enrollment['enrollmentId'] === $id) {
                return $enrollment;
            }
        }

        throw $this->createNotFoundException('La inscripción no pertenece al estudiante seleccionado.');
    }

    /**
     * @param list<array<string, mixed>> $rows
     *
     * @return array{rows:int,editable:int,graded:int,pending:int,blocked:int}
     */
    private function gradeSummary(array $rows): array
    {
        return [
            'rows' => count($rows),
            'editable' => count(array_filter($rows, static fn (array $row): bool => $row['editable'])),
            'graded' => count(array_filter($rows, static fn (array $row): bool => $row['grade'] !== null)),
            'pending' => count(array_filter($rows, static fn (array $row): bool => $row['status'] === 'PENDIENTE')),
            'blocked' => count(array_filter($rows, static fn (array $row): bool => !$row['editable'])),
        ];
    }

    /**
     * @param list<array<string, mixed>> $rows
     * @param array<string, mixed>       $posted
     * @param list<string>               $formErrors
     *
     * @return list<array{enrollmentId:int, offeringId:int, grade:float|null}>
     */
    private function buildEntries(array $rows, array $posted, array &$formErrors): array
    {
        $editable = [];
        foreach ($rows as $row) {
            if ($row['editable'] && $row['offeringId'] !== null) {
                $editable[(int) $row['offeringId']] = $row;
            }
        }

        $entries = [];
        foreach ($posted as $offeringKey => $raw) {
            $offeringId = (int) $offeringKey;
            if (!isset($editable[$offeringId])) {
                $formErrors[] = sprintf(
                    'La oferta %d no admite edición para la inscripción seleccionada.',
                    $offeringId,
                );
                continue;
            }

            $raw = trim((string) $raw);
            if ($raw === '') {
                $grade = null;
            } elseif (!is_numeric($raw)) {
                $formErrors[] = sprintf(
                    'Nota inválida para %s.',
                    $editable[$offeringId]['courseCode'],
                );
                continue;
            } else {
                $grade = (float) $raw;
                if ($grade < 0.0 || $grade > 100.0) {
                    $formErrors[] = sprintf(
                        'La nota de %s debe estar entre 0 y 100.',
                        $editable[$offeringId]['courseCode'],
                    );
                    continue;
                }
            }

            $current = $editable[$offeringId]['grade'];
            if ($grade === $current || ($grade !== null && $current !== null && abs($grade - $current) < 0.005)) {
                continue;
            }

            $entries[] = [
                'enrollmentId' => (int) $editable[$offeringId]['enrollmentId'],
                'offeringId' => $offeringId,
                'grade' => $grade,
            ];
        }

        return $entries;
    }
}
