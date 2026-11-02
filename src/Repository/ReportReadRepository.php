<?php

namespace App\Repository;

use Doctrine\DBAL\ArrayParameterType;
use Doctrine\DBAL\Connection;

final class ReportReadRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @param list<int>|null $allowedStudentIds @return array{students:int,results:int,openPeriods:int,activePrograms:int} */
    public function centerMetrics(?array $allowedStudentIds = null): array
    {
        if ($allowedStudentIds === null) {
            $row = $this->connection->fetchAssociative(
                <<<'SQL'
                SELECT
                    (SELECT COUNT(*) FROM sis_aca_estudiante)::int AS students,
                    (SELECT COUNT(*) FROM sis_aca_resultado_curso)::int AS results,
                    (SELECT COUNT(*) FROM sis_aca_periodo_academico WHERE per_estado = 'ABIERTO')::int AS "openPeriods",
                    (SELECT COUNT(*) FROM sis_aca_estudiante_programa WHERE epr_estado = 'ACTIVO')::int AS "activePrograms"
                SQL
            ) ?: [];
        } else {
            $ids = array_values(array_unique(array_map('intval', $allowedStudentIds)));
            if ($ids === []) {
                return [
                    'students' => 0,
                    'results' => 0,
                    'openPeriods' => (int) $this->connection->fetchOne("SELECT COUNT(*) FROM sis_aca_periodo_academico WHERE per_estado = 'ABIERTO'"),
                    'activePrograms' => 0,
                ];
            }

            $row = $this->connection->fetchAssociative(
                <<<'SQL'
                SELECT
                    (SELECT COUNT(*) FROM sis_aca_estudiante WHERE est_id IN (:studentIds))::int AS students,
                    (SELECT COUNT(*) FROM sis_aca_vw_resultado_estudiante WHERE est_id IN (:resultIds))::int AS results,
                    (SELECT COUNT(*) FROM sis_aca_periodo_academico WHERE per_estado = 'ABIERTO')::int AS "openPeriods",
                    (SELECT COUNT(*) FROM sis_aca_estudiante_programa WHERE epr_estado = 'ACTIVO' AND epr_est_id IN (:programIds))::int AS "activePrograms"
                SQL,
                [
                    'studentIds' => $ids,
                    'resultIds' => $ids,
                    'programIds' => $ids,
                ],
                [
                    'studentIds' => ArrayParameterType::INTEGER,
                    'resultIds' => ArrayParameterType::INTEGER,
                    'programIds' => ArrayParameterType::INTEGER,
                ],
            ) ?: [];
        }

        return [
            'students' => (int) ($row['students'] ?? 0),
            'results' => (int) ($row['results'] ?? 0),
            'openPeriods' => (int) ($row['openPeriods'] ?? 0),
            'activePrograms' => (int) ($row['activePrograms'] ?? 0),
        ];
    }

    /**
     * Filas de notas para reportes. Misma fuente para alumnos/carrera,
     * notas por carrera, por curso y por sección.
     *
     * @return list<array<string, mixed>>
     */
    public function gradesReportRows(array $filters = [], ?array $allowedStudentIds = null): array
    {
        $where = '';
        $params = [];
        $types = [];
        if ($allowedStudentIds !== null) {
            $ids = array_values(array_unique(array_map('intval', $allowedStudentIds)));
            if ($ids === []) {
                return [];
            }
            $where = ' WHERE v.est_id IN (:ids)';
            $params['ids'] = $ids;
            $types['ids'] = ArrayParameterType::INTEGER;
        }

        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT v.est_nombre_completo AS student, v.est_codigo AS code,
                   v.car_nombre AS career, v.cur_nombre AS course, v.cur_codigo AS "courseCode",
                   v.sec_codigo AS section,
                   v.anl_anio || ' · ' || v.per_nombre AS period,
                   v.res_nota AS grade, v.res_estado AS status, v.res_numero_intento AS attempt
            FROM sis_aca_vw_reporte_notas v
            {$where}
            ORDER BY v.anl_anio, v.car_nombre, v.cur_codigo, v.est_codigo
            SQL,
            $params,
            $types,
        );
        foreach ($rows as &$r) {
            $r['grade'] = $r['grade'] !== null ? (float) $r['grade'] : null;
        }

        return array_values(array_filter($rows, static function (array $row) use ($filters): bool {
            if (($filters['periodo'] ?? '') !== '' && $row['period'] !== $filters['periodo']) {
                return false;
            }
            if (($filters['carrera'] ?? '') !== '' && $row['career'] !== $filters['carrera']) {
                return false;
            }
            if (($filters['curso'] ?? '') !== '' && $row['course'] !== $filters['curso']) {
                return false;
            }
            if (($filters['seccion'] ?? '') !== '' && $row['section'] !== $filters['seccion']) {
                return false;
            }
            if (($filters['estado'] ?? '') !== '' && $row['status'] !== $filters['estado']) {
                return false;
            }

            return true;
        }));
    }

    /** @return list<array<string, mixed>> */
    public function studentsByCareer(): array
    {
        return $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT car.car_id AS careerId, car.car_nombre AS career, ep.epr_estado AS status,
                   COUNT(DISTINCT e.est_id) AS students
            FROM sis_aca_estudiante_programa ep
            JOIN sis_aca_estudiante e ON e.est_id = ep.epr_est_id
            JOIN sis_aca_pensum p ON p.pen_id = ep.epr_pen_id
            JOIN sis_aca_carrera car ON car.car_id = p.pen_car_id
            GROUP BY car.car_id, car.car_nombre, ep.epr_estado
            ORDER BY car.car_nombre, ep.epr_estado
            SQL
        );
    }

    /** @return list<array<string, mixed>> */
    public function progressByCycle(array $filters = [], ?array $allowedStudentIds = null): array
    {
        $where = '';
        $params = [];
        $types = [];
        if ($allowedStudentIds !== null) {
            $ids = array_values(array_unique(array_map('intval', $allowedStudentIds)));
            if ($ids === []) {
                return [];
            }
            $where = ' WHERE v.est_id IN (:ids)';
            $params['ids'] = $ids;
            $types['ids'] = ArrayParameterType::INTEGER;
        }

        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT v.car_nombre AS career, v.pen_nombre AS curriculum, v.cic_nombre AS cycle,
                   ROUND(AVG(v.ava_porcentaje)::numeric, 1) AS progress,
                   COUNT(DISTINCT v.est_id) AS students,
                   MODE() WITHIN GROUP (ORDER BY v.ava_estado_ciclo) AS cycleStatus
            FROM sis_aca_vw_avance_ciclo v
            {$where}
            GROUP BY v.car_nombre, v.pen_nombre, v.cic_nombre, v.cic_anio, v.cic_semestre
            ORDER BY v.cic_anio, v.cic_semestre
            SQL,
            $params,
            $types,
        );

        return array_values(array_filter($rows, static function (array $row) use ($filters): bool {
            if (($filters['carrera'] ?? '') !== '' && $row['career'] !== $filters['carrera']) {
                return false;
            }
            if (($filters['pensum'] ?? '') !== '' && $row['curriculum'] !== $filters['pensum']) {
                return false;
            }
            if (($filters['ciclo'] ?? '') !== '' && $row['cycle'] !== $filters['ciclo']) {
                return false;
            }

            return true;
        }));
    }

    /** @return list<array<string, mixed>> pendientes y repitencias (cursos no aprobados) */
    public function pendingAndRepeats(array $filters = [], ?array $allowedStudentIds = null): array
    {
        $scopeSql = '';
        $params = [];
        $types = [];
        if ($allowedStudentIds !== null) {
            $ids = array_values(array_unique(array_map('intval', $allowedStudentIds)));
            if ($ids === []) {
                return [];
            }
            $scopeSql = ' AND v.est_id IN (:ids)';
            $params['ids'] = $ids;
            $types['ids'] = ArrayParameterType::INTEGER;
        }

        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT v.est_nombre_completo AS student, v.cur_nombre AS course,
                   v.anl_anio || ' · ' || v.per_nombre AS period,
                   v.res_numero_intento AS attempt, v.res_estado AS status,
                   CASE WHEN v.res_estado = 'REPROBADO' THEN 'REPITENCIA' ELSE 'PENDIENTE' END AS "alertType",
                   CASE WHEN v.res_estado = 'REPROBADO' THEN 'Requiere seguimiento' ELSE 'Nota sin calificar' END AS note
            FROM sis_aca_vw_reporte_notas v
            WHERE v.res_estado IN ('REPROBADO', 'PENDIENTE')
            {$scopeSql}
            ORDER BY v.anl_anio DESC, v.car_nombre, v.est_codigo
            SQL,
            $params,
            $types,
        );

        return array_values(array_filter($rows, static function (array $row) use ($filters): bool {
            if (($filters['periodo'] ?? '') !== '' && $row['period'] !== $filters['periodo']) {
                return false;
            }
            if (($filters['estado'] ?? '') !== '' && $row['status'] !== $filters['estado']) {
                return false;
            }
            if (($filters['alerta'] ?? '') !== '' && $row['alertType'] !== $filters['alerta']) {
                return false;
            }

            $needle = mb_strtolower(trim((string) ($filters['q'] ?? '')));
            if ($needle !== '' && !str_contains(mb_strtolower((string) $row['student']), $needle)) {
                return false;
            }

            return true;
        }));
    }

    public function currentPeriodLabel(): ?string
    {
        $row = $this->connection->fetchAssociative(
            <<<SQL
            SELECT a.anl_anio AS year, pa.per_numero AS term
            FROM sis_aca_periodo_academico pa
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            WHERE pa.per_estado = 'ABIERTO'
            ORDER BY a.anl_anio DESC, pa.per_numero DESC LIMIT 1
            SQL
        );
        if ($row === false) {
            return null;
        }

        return $row['year'] . '-' . ($row['term'] == 1 ? 'I' : 'II');
    }

    public function policies(): array
    {
        return $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT pol_codigo AS code, pol_nombre AS name, pol_nota_aprobacion AS "passingGrade",
                   pol_vigente_desde AS "validFrom", pol_vigente_hasta AS "validUntil"
            FROM sis_aca_vw_politica_vigente
            ORDER BY pol_vigente_desde DESC
            SQL
        );
    }
}
