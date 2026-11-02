<?php

namespace App\Controller;

use App\Repository\StudentReadRepository;
use App\Service\Export\ReportExportBuilder;
use App\Service\Export\SimpleReportXlsxWriter;
use App\Security\AcademicAccessScope;
use App\Service\Report\ReportFilterSet;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\ResponseHeaderBag;
use Symfony\Component\Routing\Attribute\Route;

final class ExportController extends AbstractController
{
    #[Route('/alumnos/exportar/excel', name: 'app_student_export_xlsx', methods: ['GET'])]
    public function studentsExcel(
        Request $request,
        StudentReadRepository $students,
        SimpleReportXlsxWriter $writer,
        AcademicAccessScope $scope,
    ): BinaryFileResponse {
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

        $rows = $students->searchPage(
            q: $q,
            careerId: $career !== '' ? $career : null,
            curriculumId: $curriculum !== '' ? $curriculum : null,
            status: $status !== '' ? $status : null,
            entryYear: $entryYear,
            progressMin: $progressMin,
            progressMax: $progressMax,
            order: $order,
            allowedStudentIds: $scope->studentIds(),
        );

        $context = [];
        if ($q !== '') {
            $context['Búsqueda'] = $q;
        }
        if ($career !== '') {
            foreach ($students->careers() as $item) {
                if ((string) $item['id'] === $career) {
                    $context['Carrera'] = (string) $item['name'];
                    break;
                }
            }
        }
        if ($curriculum !== '') {
            foreach ($students->curricula() as $item) {
                if ((string) $item['id'] === $curriculum) {
                    $context['Pensum'] = (string) $item['name'];
                    break;
                }
            }
        }
        if ($status !== '') {
            $context['Estado'] = ucfirst(mb_strtolower($status));
        }
        if ($entryYear !== null) {
            $context['Año de ingreso'] = (string) $entryYear;
        }
        if ($progressMin > 0 || $progressMax < 100) {
            $context['Avance curricular'] = sprintf('%d%% a %d%%', $progressMin, $progressMax);
        }

        $path = $writer->write(
            'Listado de estudiantes',
            'Listado_de_estudiantes_'.date('Ymd'),
            [
                ['key' => 'code', 'label' => 'Carné'],
                ['key' => 'fullName', 'label' => 'Estudiante'],
                ['key' => 'birthDate', 'label' => 'Fecha de nacimiento'],
                ['key' => 'career', 'label' => 'Carrera'],
                ['key' => 'curriculum', 'label' => 'Pensum'],
                ['key' => 'entryYear', 'label' => 'Año de ingreso'],
                ['key' => 'status', 'label' => 'Estado'],
                ['key' => 'progress', 'label' => 'Avance (%)'],
            ],
            $rows,
            $context,
        );

        $response = new BinaryFileResponse($path);
        $response->headers->set('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        $response->setContentDisposition(ResponseHeaderBag::DISPOSITION_ATTACHMENT, basename($path));
        $response->deleteFileAfterSend(true);

        return $response;
    }

    #[Route(
        '/reportes/{report}/excel',
        name: 'app_report_export_xlsx',
        methods: ['GET'],
        requirements: ['report' => 'alumnos-carrera|notas-carrera|notas-curso|notas-seccion|avance-estudiante|avance-ciclo|pendientes-repitencias']
    )]
    public function reportExcel(
        string $report,
        Request $request,
        SimpleReportXlsxWriter $writer,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): BinaryFileResponse {
        $data = $builder->build($report, $filterSet->fromRequest($request), $scope->studentIds());
        $path = $writer->write(
            $data['title'],
            $data['fileName'].'_'.date('Ymd'),
            $data['columns'],
            $data['rows'],
            $data['context'],
        );

        $response = new BinaryFileResponse($path);
        $response->headers->set('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        $response->setContentDisposition(ResponseHeaderBag::DISPOSITION_ATTACHMENT, basename($path));
        $response->deleteFileAfterSend(true);

        return $response;
    }

    #[Route(
        '/reportes/{report}/vista-previa',
        name: 'app_report_preview',
        methods: ['GET'],
        requirements: ['report' => 'alumnos-carrera|notas-carrera|notas-curso|notas-seccion|avance-estudiante|avance-ciclo|pendientes-repitencias']
    )]
    public function reportPreview(
        string $report,
        Request $request,
        ReportExportBuilder $builder,
        ReportFilterSet $filterSet,
        AcademicAccessScope $scope,
    ): Response {
        $data = $builder->build($report, $filterSet->fromRequest($request), $scope->studentIds());

        return $this->render('report/print_preview.html.twig', $data + [
            'query' => $request->query->all(),
            'generatedAt' => new \DateTimeImmutable(),
        ]);
    }

}
