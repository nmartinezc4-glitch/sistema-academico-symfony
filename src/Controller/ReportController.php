<?php

namespace App\Controller;

use App\Repository\ReportReadRepository;
use App\Security\AcademicAccessScope;
use App\Service\Export\ReportExportBuilder;
use App\Service\Report\ReportFilterSet;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class ReportController extends AbstractController
{
    private const REPORT_CATALOG = [
        ['title' => 'Alumnos por carrera', 'description' => 'Distribución de matrícula activa por carrera.', 'route' => 'app_report_students_career', 'badge' => 'Matrícula'],
        ['title' => 'Notas por carrera', 'description' => 'Promedios y aprobación por carrera.', 'route' => 'app_report_grades_career', 'badge' => 'Evaluación'],
        ['title' => 'Notas por curso', 'description' => 'Distribución de calificaciones por curso.', 'route' => 'app_report_grades_course', 'badge' => 'Evaluación'],
        ['title' => 'Notas por sección', 'description' => 'Comparativo de resultados por sección.', 'route' => 'app_report_grades_section', 'badge' => 'Evaluación'],
        ['title' => 'Avance por estudiante', 'description' => 'Progreso curricular individual.', 'route' => 'app_report_progress_student', 'badge' => 'Avance'],
        ['title' => 'Avance por ciclo', 'description' => 'Progreso agregado por ciclo y carrera.', 'route' => 'app_report_progress_cycle', 'badge' => 'Avance'],
        ['title' => 'Pendientes y repitencias', 'description' => 'Cursos pendientes y alertas de seguimiento.', 'route' => 'app_report_pending_repeats', 'badge' => 'Seguimiento'],
    ];

    #[Route('/reportes', name: 'app_report_index', methods: ['GET'])]
    public function index(ReportReadRepository $reports, AcademicAccessScope $scope): Response
    {
        $catalog = self::REPORT_CATALOG;
        if ($scope->isScopedTeacher()) {
            $allowed = [
                'app_report_grades_course',
                'app_report_grades_section',
                'app_report_progress_student',
                'app_report_pending_repeats',
            ];
            $catalog = array_values(array_filter(
                $catalog,
                static fn (array $item): bool => in_array($item['route'], $allowed, true),
            ));
        }

        return $this->render('report/index.html.twig', [
            'catalog' => $catalog,
            'metrics' => $reports->centerMetrics($scope->studentIds()),
        ]);
    }

    #[Route('/reportes/alumnos-carrera', name: 'app_report_students_career', methods: ['GET'])]
    public function studentsCareer(
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build('alumnos-carrera', $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/students_career.html.twig', [
            'students' => $data['rows'],
            'periods' => [],
        ]);
    }

    #[Route('/reportes/notas-carrera', name: 'app_report_grades_career', methods: ['GET'])]
    public function gradesCareer(
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build('notas-carrera', $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/grades_career.html.twig', [
            'rows' => $data['rows'],
            'periods' => [],
        ]);
    }

    #[Route('/reportes/notas-curso', name: 'app_report_grades_course', methods: ['GET'])]
    public function gradesCourse(
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build('notas-curso', $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/grades_course.html.twig', [
            'rows' => $data['rows'],
            'periods' => [],
        ]);
    }

    #[Route('/reportes/notas-seccion', name: 'app_report_grades_section', methods: ['GET'])]
    public function gradesSection(
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build('notas-seccion', $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/grades_section.html.twig', [
            'rows' => $data['rows'],
            'periods' => [],
        ]);
    }

    #[Route('/reportes/avance-estudiante', name: 'app_report_progress_student', methods: ['GET'])]
    public function progressStudent(
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build('avance-estudiante', $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/progress_student.html.twig', ['rows' => $data['rows']]);
    }

    #[Route('/reportes/avance-ciclo', name: 'app_report_progress_cycle', methods: ['GET'])]
    public function progressCycle(
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build('avance-ciclo', $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/progress_cycle.html.twig', ['rows' => $data['rows']]);
    }

    #[Route('/reportes/pendientes-repitencias', name: 'app_report_pending_repeats', methods: ['GET'])]
    public function pendingRepeats(
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build('pendientes-repitencias', $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/pending_repeats.html.twig', ['rows' => $data['rows']]);
    }
}
