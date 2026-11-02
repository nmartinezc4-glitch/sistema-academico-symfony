<?php

namespace App\Repository;

use Doctrine\DBAL\Connection;

final class DashboardReadRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @return array<string, mixed> contrato exacto esperado por templates/dashboard/index.html.twig */
    public function dashboard(): array
    {
        $period = $this->currentPeriod();

        $totalResults = (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_aca_vw_reporte_notas');
        $graded = (int) $this->connection->fetchOne("SELECT COUNT(*) FROM sis_aca_vw_reporte_notas WHERE res_nota IS NOT NULL");
        $pending = (int) $this->connection->fetchOne("SELECT COUNT(*) FROM sis_aca_vw_reporte_notas WHERE res_nota IS NULL");
        $approved = (int) $this->connection->fetchOne("SELECT COUNT(*) FROM sis_aca_vw_reporte_notas WHERE res_estado = 'APROBADO'");

        $activeStudents = (int) $this->connection->fetchOne("SELECT COUNT(DISTINCT e.est_id) FROM sis_aca_estudiante e JOIN sis_aca_estudiante_programa ep ON ep.epr_est_id = e.est_id WHERE ep.epr_estado = 'ACTIVO'");
        $repeatStudents = (int) $this->connection->fetchOne("SELECT COUNT(DISTINCT est_id) FROM sis_aca_vw_reporte_notas WHERE res_estado = 'REPROBADO'");
        $pendingGradeRows = $pending;
        $noOfferingCourses = (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_aca_vw_ingreso_notas WHERE ofe_id IS NULL');

        $careerRows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT c.car_nombre AS career, COUNT(DISTINCT e.est_id) AS students
            FROM sis_aca_estudiante_programa ep
            JOIN sis_aca_estudiante e ON e.est_id = ep.epr_est_id
            JOIN sis_aca_pensum p ON p.pen_id = ep.epr_pen_id
            JOIN sis_aca_carrera c ON c.car_id = p.pen_car_id
            WHERE ep.epr_estado = 'ACTIVO'
            GROUP BY c.car_id, c.car_nombre ORDER BY students DESC
            SQL
        );

        $careerProgress = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT c.car_nombre AS career, ROUND(AVG(v.ava_porcentaje)::numeric, 1) AS percentage
            FROM sis_aca_vw_avance_pensum v
            JOIN sis_aca_carrera c ON c.car_id = v.car_id
            WHERE v.epr_estado = 'ACTIVO'
            GROUP BY c.car_id, c.car_nombre ORDER BY percentage DESC
            SQL
        );

        $periods = $this->periods();

        $colors = ['#C86F50', '#6F8558', '#C69A45', '#793B46', '#667E88'];
        $total = max(1, array_sum(array_column($careerRows, 'students')));
        $donut = [];
        $acc = 0.0;
        foreach ($careerRows as $i => $r) {
            $pct = round(100.0 * (int) $r['students'] / $total, 1);
            $donut[] = ['label' => $r['career'], 'value' => (int) $r['students'], 'pct' => $pct, 'color' => $colors[$i % count($colors)]];
            $acc += $pct;
        }
        // Ajuste del último segmento para sumar 100
        if ($donut !== []) {
            $diff = round(100.0 - $acc, 1);
            $donut[count($donut) - 1]['pct'] = round($donut[count($donut) - 1]['pct'] + $diff, 1);
        }

        $gradedPct = $totalResults > 0 ? round(100.0 * $graded / $totalResults, 1) : 0.0;
        $approvalPct = $graded > 0 ? round(100.0 * $approved / $graded, 1) : 0.0;

        return [
            'period' => $period,
            'activeStudents' => $activeStudents,
            'gradedPercentage' => $gradedPct,
            'approvalOnGraded' => $approvalPct,
            'pendingGrades' => $pendingGradeRows,
            'resultsTotal' => $totalResults,
            'resultsGraded' => $graded,
            'resultsPending' => $pending,
            'alerts' => [
                ['title' => 'Estudiantes con repitencia activa', 'count' => $repeatStudents, 'tone' => 'danger'],
                ['title' => 'Resultados pendientes de calificar', 'count' => $pendingGradeRows, 'tone' => 'warning'],
                ['title' => 'Cursos sin oferta activa', 'count' => $noOfferingCourses, 'tone' => 'info'],
            ],
            'careerBreakdown' => array_map(fn ($r) => ['career' => $r['career'], 'count' => (int) $r['students']], $careerRows),
            'careerProgress' => array_map(fn ($r) => ['career' => $r['career'], 'percentage' => (float) $r['percentage']], $careerProgress),
            'periods' => $periods,
            'donut' => $donut,
            'donutCss' => implode(', ', array_map(fn ($d, $i) => $d['color'] . ($i === 0 ? ' 0%' : '') . ' ' . round(array_sum(array_map(fn ($x) => $x['pct'], array_slice($donut, 0, $i + 1))), 1) . '%', $donut, array_keys($donut))),
        ];
    }


    /** @return array<string,mixed> */
    public function teacherDashboard(int $userId): array
    {
        $period = $this->currentPeriod();

        $offerings = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                o.ofe_id AS id,
                a.anl_anio || '-' || CASE p.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS period,
                p.per_estado AS "periodStatus",
                c.cur_codigo AS "courseCode",
                c.cur_nombre AS course,
                s.sec_codigo AS section,
                pen.pen_codigo AS curriculum,
                (
                    SELECT COUNT(DISTINCT e.est_id)
                    FROM sis_aca_estudiante_periodo ep
                    JOIN sis_aca_estudiante_programa pr
                      ON pr.epr_id = ep.epe_epr_id
                     AND pr.epr_pen_id = pc.pcu_pen_id
                    JOIN sis_aca_estudiante e ON e.est_id = pr.epr_est_id
                    WHERE ep.epe_per_id = o.ofe_per_id
                      AND ep.epe_sec_id = o.ofe_sec_id
                      AND ep.epe_estado = 'INSCRITO'
                )::int AS "studentsCount",
                (
                    SELECT COUNT(*)
                    FROM sis_aca_resultado_curso r
                    WHERE r.res_ofe_id = o.ofe_id
                )::int AS "resultsTotal",
                (
                    SELECT COUNT(*)
                    FROM sis_aca_resultado_curso r
                    WHERE r.res_ofe_id = o.ofe_id
                      AND r.res_nota IS NULL
                )::int AS "pendingCount"
            FROM sis_aca_docente_oferta d
            JOIN sis_aca_oferta_curso o ON o.ofe_id = d.dof_ofe_id AND o.ofe_activo
            JOIN sis_aca_periodo_academico p ON p.per_id = o.ofe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = p.per_anl_id
            JOIN sis_aca_pensum_curso pc ON pc.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_curso c ON c.cur_id = pc.pcu_cur_id
            JOIN sis_aca_pensum pen ON pen.pen_id = pc.pcu_pen_id
            JOIN sis_aca_seccion s ON s.sec_id = o.ofe_sec_id
            WHERE d.dof_usu_id = :userId
              AND d.dof_activo
            ORDER BY (p.per_estado = 'ABIERTO') DESC, a.anl_anio DESC, p.per_numero DESC, c.cur_codigo, s.sec_codigo
            SQL,
            ['userId' => $userId],
        );

        foreach ($offerings as &$offering) {
            $offering['id'] = (int) $offering['id'];
            $offering['studentsCount'] = (int) $offering['studentsCount'];
            $offering['resultsTotal'] = (int) $offering['resultsTotal'];
            $offering['pendingCount'] = (int) $offering['pendingCount'];
        }

        $assignedStudents = (int) $this->connection->fetchOne(
            <<<'SQL'
            SELECT COUNT(DISTINCT e.est_id)
            FROM sis_aca_docente_oferta d
            JOIN sis_aca_oferta_curso o ON o.ofe_id = d.dof_ofe_id AND o.ofe_activo
            JOIN sis_aca_pensum_curso pc ON pc.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_estudiante_periodo ep
              ON ep.epe_per_id = o.ofe_per_id
             AND ep.epe_sec_id = o.ofe_sec_id
             AND ep.epe_estado = 'INSCRITO'
            JOIN sis_aca_estudiante_programa pr
              ON pr.epr_id = ep.epe_epr_id
             AND pr.epr_pen_id = pc.pcu_pen_id
            JOIN sis_aca_estudiante e ON e.est_id = pr.epr_est_id
            WHERE d.dof_usu_id = :userId
              AND d.dof_activo
            SQL,
            ['userId' => $userId],
        );

        $resultMetrics = $this->connection->fetchAssociative(
            <<<'SQL'
            SELECT
                COUNT(r.res_id)::int AS total,
                COUNT(r.res_id) FILTER (WHERE r.res_nota IS NOT NULL)::int AS graded,
                COUNT(r.res_id) FILTER (WHERE r.res_nota IS NULL)::int AS pending,
                COUNT(r.res_id) FILTER (WHERE r.res_nota IS NOT NULL AND v.res_estado = 'APROBADO')::int AS approved
            FROM sis_aca_docente_oferta d
            JOIN sis_aca_resultado_curso r ON r.res_ofe_id = d.dof_ofe_id
            LEFT JOIN sis_aca_vw_reporte_notas v ON v.res_id = r.res_id
            WHERE d.dof_usu_id = :userId
              AND d.dof_activo
            SQL,
            ['userId' => $userId],
        ) ?: ['total' => 0, 'graded' => 0, 'pending' => 0, 'approved' => 0];

        $total = (int) $resultMetrics['total'];
        $graded = (int) $resultMetrics['graded'];
        $pending = (int) $resultMetrics['pending'];
        $approved = (int) $resultMetrics['approved'];

        return [
            'period' => $period,
            'assignedOfferings' => count($offerings),
            'assignedStudents' => $assignedStudents,
            'resultsTotal' => $total,
            'resultsGraded' => $graded,
            'resultsPending' => $pending,
            'gradedPercentage' => $total > 0 ? round(100.0 * $graded / $total, 1) : 0.0,
            'approvalOnGraded' => $graded > 0 ? round(100.0 * $approved / $graded, 1) : 0.0,
            'offerings' => $offerings,
        ];
    }

    /** @return array{year:?int, term:?string, status:?string}|null */
    private function currentPeriod(): ?array
    {
        $row = $this->connection->fetchAssociative(
            <<<SQL
            SELECT a.anl_anio AS year, pa.per_numero AS term, pa.per_estado AS status
            FROM sis_aca_periodo_academico pa
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            WHERE pa.per_estado = 'ABIERTO'
            ORDER BY a.anl_anio DESC, pa.per_numero DESC LIMIT 1
            SQL
        );
        if ($row === false) {
            $row = $this->connection->fetchAssociative(
                <<<SQL
                SELECT a.anl_anio AS year, pa.per_numero AS term, pa.per_estado AS status
                FROM sis_aca_periodo_academico pa
                JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
                ORDER BY a.anl_anio DESC, pa.per_numero DESC LIMIT 1
                SQL
            );
        }
        if ($row === false) {
            return null;
        }

        return ['year' => $row['year'] !== null ? (int) $row['year'] : null, 'term' => $row['term'] == 1 ? 'I' : 'II', 'status' => $row['status']];
    }

    /** @return list<array{label:string,year:int,term:string,status:string}> */
    private function periods(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT pa.per_numero AS term, pa.per_estado AS status, a.anl_anio AS year
            FROM sis_aca_periodo_academico pa
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            ORDER BY a.anl_anio, pa.per_numero
            SQL
        );
        foreach ($rows as &$r) {
            $r['label'] = $r['year'] . '-' . ($r['term'] == 1 ? 'I' : 'II');
            $r['term'] = $r['term'] == 1 ? 'I' : 'II';
            $r['year'] = (int) $r['year'];
        }

        return $rows;
    }
}
