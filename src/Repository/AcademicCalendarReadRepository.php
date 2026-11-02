<?php

namespace App\Repository;

use Doctrine\DBAL\Connection;

final class AcademicCalendarReadRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @return list<array<string,mixed>> */
    public function calendar(): array
    {
        $years = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                anl_id AS id,
                anl_anio AS year,
                anl_nombre AS name,
                anl_fecha_inicio AS "startDate",
                anl_fecha_fin AS "endDate",
                anl_estado AS status
            FROM sis_aca_anio_lectivo
            ORDER BY anl_anio DESC
            SQL
        );

        $periods = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                p.per_id AS id,
                p.per_anl_id AS "yearId",
                p.per_numero AS number,
                p.per_nombre AS name,
                p.per_fecha_inicio AS "startDate",
                p.per_fecha_fin AS "endDate",
                p.per_estado AS status,
                pol.pol_codigo AS "policyCode",
                pol.pol_nombre AS "policyName",
                pol.pol_nota_aprobacion AS "passingGrade"
            FROM sis_aca_periodo_academico p
            JOIN sis_aca_politica_academica pol ON pol.pol_id = p.per_pol_id
            ORDER BY p.per_fecha_inicio DESC, p.per_numero DESC
            SQL
        );

        $byYear = [];
        foreach ($periods as $period) {
            $period['id'] = (int) $period['id'];
            $period['yearId'] = (int) $period['yearId'];
            $period['number'] = (int) $period['number'];
            $period['passingGrade'] = (float) $period['passingGrade'];
            $period['label'] = $period['number'] === 1 ? 'Semestre I' : ($period['number'] === 2 ? 'Semestre II' : $period['name']);
            $byYear[$period['yearId']][] = $period;
        }

        foreach ($years as &$year) {
            $year['id'] = (int) $year['id'];
            $year['year'] = (int) $year['year'];
            $year['periods'] = $byYear[$year['id']] ?? [];
        }

        return $years;
    }

    /** @return array{years:int,periods:int,open:int,planned:int,closed:int} */
    public function metrics(): array
    {
        $row = $this->connection->fetchAssociative(
            <<<'SQL'
            SELECT
                (SELECT COUNT(*) FROM sis_aca_anio_lectivo)::int AS years,
                COUNT(*)::int AS periods,
                COUNT(*) FILTER (WHERE per_estado = 'ABIERTO')::int AS open,
                COUNT(*) FILTER (WHERE per_estado = 'PLANIFICADO')::int AS planned,
                COUNT(*) FILTER (WHERE per_estado = 'CERRADO')::int AS closed
            FROM sis_aca_periodo_academico
            SQL
        ) ?: [];

        return [
            'years' => (int) ($row['years'] ?? 0),
            'periods' => (int) ($row['periods'] ?? 0),
            'open' => (int) ($row['open'] ?? 0),
            'planned' => (int) ($row['planned'] ?? 0),
            'closed' => (int) ($row['closed'] ?? 0),
        ];
    }

    /** @return list<array{id:int,year:int,name:string,startDate:string,endDate:string,status:string}> */
    public function years(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                anl_id AS id,
                anl_anio AS year,
                anl_nombre AS name,
                anl_fecha_inicio AS "startDate",
                anl_fecha_fin AS "endDate",
                anl_estado AS status
            FROM sis_aca_anio_lectivo
            ORDER BY anl_anio DESC
            SQL
        );

        return array_map(static fn (array $row): array => [
            'id' => (int) $row['id'],
            'year' => (int) $row['year'],
            'name' => (string) $row['name'],
            'startDate' => (string) $row['startDate'],
            'endDate' => (string) $row['endDate'],
            'status' => (string) $row['status'],
        ], $rows);
    }

    /** @return list<array<string,mixed>> */
    public function policies(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                pol_id AS id,
                pol_codigo AS code,
                pol_nombre AS name,
                pol_nota_aprobacion AS "passingGrade",
                pol_vigente_desde AS "validFrom",
                pol_vigente_hasta AS "validUntil"
            FROM sis_aca_vw_politica_linea_tiempo
            ORDER BY pol_vigente_desde DESC
            SQL
        );

        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['passingGrade'] = (float) $row['passingGrade'];
        }

        return $rows;
    }
}
