<?php

namespace App\Repository;

use Doctrine\DBAL\Connection;

final class AcademicOperationsReadRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @return list<array<string,mixed>> */
    public function offeringCatalog(
        string $q = '',
        ?int $periodId = null,
        ?int $sectionId = null,
        string $status = 'all',
    ): array {
        $conditions = [];
        $params = [];

        if ($q !== '') {
            $conditions[] = '(cu.cur_codigo ILIKE :q OR cu.cur_nombre ILIKE :q OR p.pen_codigo ILIKE :q OR car.car_nombre ILIKE :q)';
            $params['q'] = '%'.$q.'%';
        }
        if ($periodId !== null) {
            $conditions[] = 'o.ofe_per_id = :periodId';
            $params['periodId'] = $periodId;
        }
        if ($sectionId !== null) {
            $conditions[] = 'o.ofe_sec_id = :sectionId';
            $params['sectionId'] = $sectionId;
        }
        if ($status === 'active') {
            $conditions[] = 'o.ofe_activo';
        } elseif ($status === 'inactive') {
            $conditions[] = 'NOT o.ofe_activo';
        }

        $where = $conditions === [] ? '' : 'WHERE '.implode(' AND ', $conditions);

        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT
                o.ofe_id AS id,
                o.ofe_per_id AS "periodId",
                o.ofe_pcu_id AS "curriculumCourseId",
                o.ofe_sec_id AS "sectionId",
                o.ofe_activo AS active,
                a.anl_anio || '-' || CASE pa.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS period,
                pa.per_estado AS "periodStatus",
                cu.cur_codigo AS "courseCode",
                cu.cur_nombre AS "courseName",
                p.pen_codigo AS "curriculumCode",
                p.pen_nombre AS curriculum,
                car.car_nombre AS career,
                c.cic_nombre AS cycle,
                s.sec_codigo AS section
            FROM sis_aca_oferta_curso o
            JOIN sis_aca_periodo_academico pa ON pa.per_id = o.ofe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            JOIN sis_aca_pensum_curso pcu ON pcu.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_curso cu ON cu.cur_id = pcu.pcu_cur_id
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = pcu.pcu_cic_id
            JOIN sis_aca_pensum p ON p.pen_id = pcu.pcu_pen_id
            JOIN sis_aca_carrera car ON car.car_id = p.pen_car_id
            JOIN sis_aca_seccion s ON s.sec_id = o.ofe_sec_id
            $where
            ORDER BY a.anl_anio DESC, pa.per_numero DESC, car.car_nombre, p.pen_codigo, s.sec_codigo, cu.cur_codigo
            SQL,
            $params,
        );

        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['periodId'] = (int) $row['periodId'];
            $row['curriculumCourseId'] = (int) $row['curriculumCourseId'];
            $row['sectionId'] = (int) $row['sectionId'];
            $row['active'] = (bool) $row['active'];
            $row['status'] = $row['active'] ? 'ACTIVO' : 'INACTIVO';
        }

        return $rows;
    }

    /** @return array{total:int,active:int,openPeriod:int,sections:int} */
    public function offeringMetrics(): array
    {
        $row = $this->connection->fetchAssociative(
            <<<'SQL'
            SELECT
                COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE o.ofe_activo)::int AS active,
                COUNT(*) FILTER (WHERE o.ofe_activo AND pa.per_estado = 'ABIERTO')::int AS "openPeriod",
                COUNT(DISTINCT o.ofe_sec_id)::int AS sections
            FROM sis_aca_oferta_curso o
            JOIN sis_aca_periodo_academico pa ON pa.per_id = o.ofe_per_id
            SQL
        ) ?: [];

        return [
            'total' => (int) ($row['total'] ?? 0),
            'active' => (int) ($row['active'] ?? 0),
            'openPeriod' => (int) ($row['openPeriod'] ?? 0),
            'sections' => (int) ($row['sections'] ?? 0),
        ];
    }

    /** @return list<array{id:int,label:string,status:string}> */
    public function availablePeriods(bool $includeClosed = false): array
    {
        $where = $includeClosed ? '' : "WHERE pa.per_estado <> 'CERRADO'";
        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT
                pa.per_id AS id,
                a.anl_anio || '-' || CASE pa.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS label,
                pa.per_estado AS status
            FROM sis_aca_periodo_academico pa
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            $where
            ORDER BY a.anl_anio DESC, pa.per_numero DESC
            SQL
        );

        return array_map(static fn (array $row): array => [
            'id' => (int) $row['id'],
            'label' => (string) $row['label'],
            'status' => (string) $row['status'],
        ], $rows);
    }

    /** @return list<array{id:int,code:string,name:string}> */
    public function sections(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            'SELECT sec_id AS id, sec_codigo AS code, sec_nombre AS name FROM sis_aca_seccion WHERE sec_activo ORDER BY sec_codigo'
        );

        return array_map(static fn (array $row): array => [
            'id' => (int) $row['id'],
            'code' => (string) $row['code'],
            'name' => (string) $row['name'],
        ], $rows);
    }

    /** @return list<array<string,mixed>> */
    public function curriculumCourses(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                pcu.pcu_id AS id,
                p.pen_id AS "curriculumId",
                p.pen_codigo AS "curriculumCode",
                p.pen_nombre AS curriculum,
                car.car_nombre AS career,
                cu.cur_codigo AS "courseCode",
                cu.cur_nombre AS "courseName",
                c.cic_nombre AS cycle,
                pcu.pcu_obligatorio AS required
            FROM sis_aca_pensum_curso pcu
            JOIN sis_aca_pensum p ON p.pen_id = pcu.pcu_pen_id
            JOIN sis_aca_carrera car ON car.car_id = p.pen_car_id
            JOIN sis_aca_curso cu ON cu.cur_id = pcu.pcu_cur_id
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = pcu.pcu_cic_id
            WHERE p.pen_activo AND cu.cur_activo AND c.cic_activo
            ORDER BY car.car_nombre, p.pen_codigo, c.cic_anio, c.cic_semestre, pcu.pcu_orden
            SQL
        );

        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['curriculumId'] = (int) $row['curriculumId'];
            $row['required'] = (bool) $row['required'];
        }

        return $rows;
    }

    /** @return list<array{id:int,label:string,year:int,term:int}> */
    public function cyclesForCurriculum(int $curriculumId): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT DISTINCT
                c.cic_id AS id,
                c.cic_nombre AS label,
                c.cic_anio AS year,
                c.cic_semestre AS term
            FROM sis_aca_pensum_curso pcu
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = pcu.pcu_cic_id
            WHERE pcu.pcu_pen_id = :curriculumId
              AND c.cic_activo
            ORDER BY c.cic_anio, c.cic_semestre
            SQL,
            ['curriculumId' => $curriculumId],
        );

        return array_map(static fn (array $row): array => [
            'id' => (int) $row['id'],
            'label' => (string) $row['label'],
            'year' => (int) $row['year'],
            'term' => (int) $row['term'],
        ], $rows);
    }

    public function matchingOfferCount(int $curriculumId, int $periodId, int $sectionId): int
    {
        return (int) $this->connection->fetchOne(
            <<<'SQL'
            SELECT COUNT(*)
            FROM sis_aca_oferta_curso o
            JOIN sis_aca_pensum_curso pcu ON pcu.pcu_id = o.ofe_pcu_id
            WHERE pcu.pcu_pen_id = :curriculumId
              AND o.ofe_per_id = :periodId
              AND o.ofe_sec_id = :sectionId
              AND o.ofe_activo
            SQL,
            [
                'curriculumId' => $curriculumId,
                'periodId' => $periodId,
                'sectionId' => $sectionId,
            ],
        );
    }
}
