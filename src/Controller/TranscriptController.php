<?php

namespace App\Controller;

use App\Repository\StudentReadRepository;
use App\Repository\TeachingAssignmentReadRepository;
use App\Security\AcademicAccessScope;
use App\Security\AcademicUser;
use App\Ui\Paginator;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class TranscriptController extends AbstractController
{
    #[Route('/expedientes', name: 'app_transcript_index', methods: ['GET'])]
    public function index(Request $request, StudentReadRepository $students, AcademicAccessScope $scope): Response
    {
        $allowedStudentIds = $scope->studentIds();
        $q = trim((string) $request->query->get('q', ''));
        $career = trim((string) $request->query->get('career', ''));
        $curriculum = trim((string) $request->query->get('curriculum', ''));
        $status = strtoupper(trim((string) $request->query->get('status', '')));
        $entryYearRaw = trim((string) $request->query->get('entry_year', ''));
        $entryYear = ctype_digit($entryYearRaw) ? (int) $entryYearRaw : null;

        $history = strtolower(trim((string) $request->query->get('history', 'all')));
        if (!\in_array($history, ['all', 'with', 'without'], true)) {
            $history = 'all';
        }

        $allowedOrders = ['apellidos-asc', 'codigo-asc', 'avance-desc', 'historial-desc'];
        $order = (string) $request->query->get('orden', 'apellidos-asc');
        if (!\in_array($order, $allowedOrders, true)) {
            $order = 'apellidos-asc';
        }

        $availableStatuses = $students->statuses();
        if ($status !== '' && !\in_array($status, $availableStatuses, true)) {
            $status = '';
        }

        $filteredTotal = $students->countTranscriptSearch(
            q: $q,
            careerId: $career !== '' ? $career : null,
            curriculumId: $curriculum !== '' ? $curriculum : null,
            status: $status !== '' ? $status : null,
            entryYear: $entryYear,
            history: $history,
            allowedStudentIds: $allowedStudentIds,
        );

        $pager = Paginator::fromRequest($request, $filteredTotal);

        return $this->render('transcript/index.html.twig', [
            'items' => $students->searchTranscriptPage(
                q: $q,
                careerId: $career !== '' ? $career : null,
                curriculumId: $curriculum !== '' ? $curriculum : null,
                status: $status !== '' ? $status : null,
                entryYear: $entryYear,
                history: $history,
                order: $order,
                limit: $pager->perPage,
                offset: $pager->offset(),
                allowedStudentIds: $allowedStudentIds,
            ),
            'q' => $q,
            'career' => $career,
            'curriculum' => $curriculum,
            'status' => $status,
            'entryYear' => $entryYear,
            'historyFilter' => $history,
            'order' => $order,
            'total' => $students->count($allowedStudentIds),
            'filteredTotal' => $filteredTotal,
            'metrics' => $students->transcriptMetrics($allowedStudentIds),
            'careers' => $students->careers(),
            'curricula' => $students->curricula(),
            'entryYears' => $students->entryYears(),
            'statuses' => $availableStatuses,
            'pager' => $pager,
        ]);
    }

    #[Route('/expedientes/{id}', name: 'app_transcript_show', methods: ['GET'], requirements: ['id' => '\\d+'])]
    public function show(
        int $id,
        StudentReadRepository $students,
        TeachingAssignmentReadRepository $assignments,
        AcademicAccessScope $scope,
    ): Response {
        if (!$scope->canViewStudent($id)) {
            throw $this->createAccessDeniedException('Este expediente no pertenece a un estudiante asignado a tu docencia.');
        }

        $student = $students->findProfile($id);
        if (!$student) {
            throw $this->createNotFoundException();
        }

        $periods = $students->periods($id);
        $results = $students->results($id);

        $resultsByPeriod = [];
        foreach ($results as $result) {
            $resultsByPeriod[(string) $result['period']][] = $result;
        }

        $history = [];
        foreach ($periods as $period) {
            $periodResults = $resultsByPeriod[(string) $period['periodLabel']] ?? [];
            $graded = array_values(array_filter(
                $periodResults,
                static fn (array $row): bool => $row['grade'] !== null,
            ));
            $average = $graded === []
                ? null
                : array_sum(array_map(static fn (array $row): float => (float) $row['grade'], $graded)) / count($graded);

            $history[] = $period + [
                'results' => $periodResults,
                'totalResults' => count($periodResults),
                'gradedResults' => count($graded),
                'average' => $average,
                'approvedResults' => count(array_filter(
                    $periodResults,
                    static fn (array $row): bool => $row['status'] === 'APROBADO',
                )),
                'failedResults' => count(array_filter(
                    $periodResults,
                    static fn (array $row): bool => $row['status'] === 'REPROBADO',
                )),
                'pendingResults' => count(array_filter(
                    $periodResults,
                    static fn (array $row): bool => $row['status'] === 'PENDIENTE',
                )),
            ];
        }

        $canGradeStudent = false;
        if ($this->isGranted('ROLE_COORDINACION')) {
            $canGradeStudent = true;
        } elseif ($this->isGranted('ROLE_DOCENTE')) {
            $user = $this->getUser();
            $canGradeStudent = $user instanceof AcademicUser
                && $assignments->canGradeStudent($user->getId(), $id);
        }

        return $this->render('transcript/show.html.twig', [
            'vm' => $student,
            'history' => $history,
            'totalResults' => count($results),
            'canGradeStudent' => $canGradeStudent,
        ]);
    }
}
