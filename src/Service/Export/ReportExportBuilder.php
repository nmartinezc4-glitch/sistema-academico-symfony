<?php

namespace App\Service\Export;

use App\Repository\ReportReadRepository;
use App\Repository\StudentReadRepository;

final class ReportExportBuilder
{
    public function __construct(
        private readonly ReportReadRepository $reports,
        private readonly StudentReadRepository $students,
    ) {
    }

    /**
     * @param array<string,string> $filters
     * @param list<int>|null $allowedStudentIds
     * @return array{
     *   title:string,
     *   fileName:string,
     *   columns:list<array{key:string,label:string}>,
     *   rows:list<array<string,mixed>>,
     *   context:array<string,string>,
     *   backRoute:string,
     *   orientation:string
     * }
     */
    public function build(string $report, array $filters, ?array $allowedStudentIds): array
    {
        [$title, $fileName, $columns, $rows, $backRoute] = match ($report) {
            'alumnos-carrera' => [
                'Alumnos por carrera',
                'Alumnos_por_carrera',
                [
                    ['key' => 'code', 'label' => 'Carné'],
                    ['key' => 'fullName', 'label' => 'Estudiante'],
                    ['key' => 'career', 'label' => 'Carrera'],
                    ['key' => 'curriculum', 'label' => 'Pensum'],
                    ['key' => 'status', 'label' => 'Estado'],
                    ['key' => 'progress', 'label' => 'Avance (%)'],
                ],
                $this->filterStudents(
                    $this->students->searchPage(allowedStudentIds: $allowedStudentIds),
                    $filters,
                ),
                'app_report_students_career',
            ],
            'notas-carrera', 'notas-curso', 'notas-seccion' => [
                match ($report) {
                    'notas-curso' => 'Notas por curso',
                    'notas-seccion' => 'Notas por sección',
                    default => 'Notas por carrera',
                },
                match ($report) {
                    'notas-curso' => 'Notas_por_curso',
                    'notas-seccion' => 'Notas_por_seccion',
                    default => 'Notas_por_carrera',
                },
                [
                    ['key' => 'code', 'label' => 'Carné'],
                    ['key' => 'student', 'label' => 'Estudiante'],
                    ['key' => 'career', 'label' => 'Carrera'],
                    ['key' => 'courseCode', 'label' => 'Código de curso'],
                    ['key' => 'course', 'label' => 'Curso'],
                    ['key' => 'section', 'label' => 'Sección'],
                    ['key' => 'period', 'label' => 'Período'],
                    ['key' => 'grade', 'label' => 'Nota'],
                    ['key' => 'status', 'label' => 'Estado'],
                    ['key' => 'attempt', 'label' => 'Intento'],
                ],
                $this->reports->gradesReportRows($filters, $allowedStudentIds),
                match ($report) {
                    'notas-curso' => 'app_report_grades_course',
                    'notas-seccion' => 'app_report_grades_section',
                    default => 'app_report_grades_career',
                },
            ],
            'avance-estudiante' => [
                'Avance curricular por estudiante',
                'Avance_por_estudiante',
                [
                    ['key' => 'code', 'label' => 'Carné'],
                    ['key' => 'student', 'label' => 'Estudiante'],
                    ['key' => 'career', 'label' => 'Carrera'],
                    ['key' => 'curriculum', 'label' => 'Pensum'],
                    ['key' => 'approved', 'label' => 'Cursos aprobados'],
                    ['key' => 'pending', 'label' => 'Cursos pendientes'],
                    ['key' => 'repeats', 'label' => 'Repitencias'],
                    ['key' => 'progress', 'label' => 'Avance (%)'],
                ],
                $this->filterProgressStudents(array_map(static fn (array $student): array => [
                    'student' => $student['fullName'],
                    'code' => $student['code'],
                    'career' => $student['career'],
                    'curriculum' => $student['curriculum'],
                    'progress' => $student['progress'],
                    'approved' => $student['approved'],
                    'pending' => $student['pending'],
                    'repeats' => $student['repeats'],
                ], $this->students->searchPage(allowedStudentIds: $allowedStudentIds)), $filters),
                'app_report_progress_student',
            ],
            'avance-ciclo' => [
                'Avance curricular por ciclo',
                'Avance_por_ciclo',
                [
                    ['key' => 'cycle', 'label' => 'Ciclo'],
                    ['key' => 'career', 'label' => 'Carrera'],
                    ['key' => 'curriculum', 'label' => 'Pensum'],
                    ['key' => 'students', 'label' => 'Estudiantes'],
                    ['key' => 'progress', 'label' => 'Avance (%)'],
                    ['key' => 'cycleStatus', 'label' => 'Estado'],
                ],
                $this->reports->progressByCycle($filters, $allowedStudentIds),
                'app_report_progress_cycle',
            ],
            'pendientes-repitencias' => [
                'Pendientes y repitencias',
                'Pendientes_y_repitencias',
                [
                    ['key' => 'student', 'label' => 'Estudiante'],
                    ['key' => 'course', 'label' => 'Curso'],
                    ['key' => 'period', 'label' => 'Período'],
                    ['key' => 'attempt', 'label' => 'Intento'],
                    ['key' => 'status', 'label' => 'Estado'],
                    ['key' => 'alertType', 'label' => 'Seguimiento'],
                ],
                $this->reports->pendingAndRepeats($filters, $allowedStudentIds),
                'app_report_pending_repeats',
            ],
            default => throw new \InvalidArgumentException('Reporte no soportado.'),
        };

        return [
            'title' => $title,
            'fileName' => $fileName,
            'columns' => $columns,
            'rows' => $rows,
            'context' => $this->humanContext($filters),
            'backRoute' => $backRoute,
            'orientation' => 'landscape',
        ];
    }

    /** @param list<array<string,mixed>> $rows @param array<string,string> $filters */
    private function filterStudents(array $rows, array $filters): array
    {
        $needle = mb_strtolower($filters['q'] ?? '');

        return array_values(array_filter($rows, static function (array $row) use ($filters, $needle): bool {
            if (($filters['carrera'] ?? '') !== '' && ($row['career'] ?? '') !== $filters['carrera']) {
                return false;
            }
            if (($filters['estado'] ?? '') !== '' && ($row['status'] ?? '') !== $filters['estado']) {
                return false;
            }
            if ($needle !== '') {
                $haystack = mb_strtolower(($row['fullName'] ?? '').' '.($row['code'] ?? ''));
                if (!str_contains($haystack, $needle)) {
                    return false;
                }
            }

            return true;
        }));
    }

    /** @param list<array<string,mixed>> $rows @param array<string,string> $filters */
    private function filterProgressStudents(array $rows, array $filters): array
    {
        $needle = mb_strtolower($filters['q'] ?? '');

        return array_values(array_filter($rows, static function (array $row) use ($filters, $needle): bool {
            if (($filters['carrera'] ?? '') !== '' && ($row['career'] ?? '') !== $filters['carrera']) {
                return false;
            }
            if (($filters['pensum'] ?? '') !== '' && ($row['curriculum'] ?? '') !== $filters['pensum']) {
                return false;
            }
            if ($needle !== '') {
                $haystack = mb_strtolower(($row['student'] ?? '').' '.($row['code'] ?? ''));
                if (!str_contains($haystack, $needle)) {
                    return false;
                }
            }

            return true;
        }));
    }

    /** @param array<string,string> $filters @return array<string,string> */
    private function humanContext(array $filters): array
    {
        $labels = [
            'periodo' => 'Período',
            'carrera' => 'Carrera',
            'curso' => 'Curso',
            'seccion' => 'Sección',
            'estado' => 'Estado',
            'alerta' => 'Tipo de seguimiento',
            'pensum' => 'Pensum',
            'ciclo' => 'Ciclo',
            'q' => 'Búsqueda',
        ];

        $context = [];
        foreach ($labels as $key => $label) {
            if (($filters[$key] ?? '') !== '') {
                $context[$label] = $filters[$key];
            }
        }

        return $context;
    }
}
