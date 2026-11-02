<?php

namespace App\Repository;

use Doctrine\DBAL\Connection;

final class CurriculumReadRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @return list<array<string,mixed>> */
    public function careerCatalog(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            'SELECT car_id AS id, car_codigo AS code, car_nombre AS name, car_descripcion AS description, car_activo AS active FROM sis_aca_carrera ORDER BY car_nombre'
        );
        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['active'] = (bool) $row['active'];
            $row['status'] = $row['active'] ? 'ACTIVO' : 'INACTIVO';
        }

        return $rows;
    }

    /** @return list<array<string,mixed>> */
    public function courseCatalog(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            'SELECT cur_id AS id, cur_codigo AS code, cur_nombre AS name, cur_descripcion AS description, cur_activo AS active FROM sis_aca_curso ORDER BY cur_codigo'
        );
        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['active'] = (bool) $row['active'];
            $row['status'] = $row['active'] ? 'ACTIVO' : 'INACTIVO';
        }

        return $rows;
    }

    /** @return list<array<string,mixed>> */
    public function sectionCatalog(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            'SELECT sec_id AS id, sec_codigo AS code, sec_nombre AS name, sec_activo AS active FROM sis_aca_seccion ORDER BY sec_codigo'
        );
        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['active'] = (bool) $row['active'];
            $row['status'] = $row['active'] ? 'ACTIVO' : 'INACTIVO';
        }

        return $rows;
    }

    /** @return list<array{id:int,code:string,name:string}> */
    public function careers(): array
    {
        return $this->connection->fetchAllAssociative(
            'SELECT car_id AS id, car_codigo AS code, car_nombre AS name FROM sis_aca_carrera WHERE car_activo ORDER BY car_nombre'
        );
    }

    /** @return list<array<string, mixed>> código y nombre de todos los cursos activos */
    public function courses(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            'SELECT cur_id AS id, cur_codigo AS code, cur_nombre AS name FROM sis_aca_curso WHERE cur_activo ORDER BY cur_codigo'
        );

        return $rows;
    }

    /** @return list<array<string, mixed>> pensums por carrera */
    public function curricula(): array
    {
        return $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT p.pen_id AS id, p.pen_codigo AS code, p.pen_nombre AS name,
                   p.pen_version AS version,
                   p.pen_vigente_desde AS "validFrom",
                   p.pen_vigente_hasta AS "validUntil",
                   c.car_id AS "careerId", c.car_nombre AS career
            FROM sis_aca_pensum p
            JOIN sis_aca_carrera c ON c.car_id = p.pen_car_id
            WHERE p.pen_activo
            ORDER BY c.car_nombre, p.pen_vigente_desde
            SQL
        );
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function searchCurriculaPage(
        string $q = '',
        ?string $careerId = null,
        string $status = 'all',
        string $order = 'career-asc',
        ?int $limit = null,
        int $offset = 0,
    ): array {
        [$where, $params] = $this->curriculumFilters($q, $careerId, $status);

        $orders = [
            'career-asc' => 'c.car_nombre ASC, p.pen_vigente_desde DESC, p.pen_nombre ASC',
            'name-asc' => 'p.pen_nombre ASC, c.car_nombre ASC',
            'newest' => 'p.pen_vigente_desde DESC, c.car_nombre ASC',
            'courses-desc' => '"courseCount" DESC, c.car_nombre ASC, p.pen_nombre ASC',
        ];
        $orderBy = $orders[$order] ?? $orders['career-asc'];

        $sql = <<<SQL
        SELECT
            p.pen_id AS id,
            p.pen_codigo AS code,
            p.pen_nombre AS name,
            p.pen_version AS version,
            p.pen_vigente_desde AS "validFrom",
            p.pen_vigente_hasta AS "validUntil",
            p.pen_activo AS active,
            c.car_id AS "careerId",
            c.car_nombre AS career,
            COUNT(DISTINCT pc.pcu_id)::int AS "courseCount",
            COUNT(DISTINCT pc.pcu_cic_id)::int AS "cycleCount",
            COUNT(DISTINCT ep.epr_est_id) FILTER (WHERE ep.epr_estado = 'ACTIVO')::int AS "activeStudents"
        FROM sis_aca_pensum p
        JOIN sis_aca_carrera c ON c.car_id = p.pen_car_id
        LEFT JOIN sis_aca_pensum_curso pc ON pc.pcu_pen_id = p.pen_id
        LEFT JOIN sis_aca_estudiante_programa ep ON ep.epr_pen_id = p.pen_id
        $where
        GROUP BY
            p.pen_id, p.pen_codigo, p.pen_nombre, p.pen_version,
            p.pen_vigente_desde, p.pen_vigente_hasta, p.pen_activo,
            c.car_id, c.car_nombre
        ORDER BY $orderBy
        SQL;

        if ($limit !== null) {
            $sql .= "\nLIMIT :limit OFFSET :offset";
            $params['limit'] = max(1, $limit);
            $params['offset'] = max(0, $offset);
        }

        $rows = $this->connection->fetchAllAssociative($sql, $params);

        return array_map([$this, 'normalizeCurriculumRow'], $rows);
    }

    public function countCurriculaSearch(
        string $q = '',
        ?string $careerId = null,
        string $status = 'all',
    ): int {
        [$where, $params] = $this->curriculumFilters($q, $careerId, $status);

        return (int) $this->connection->fetchOne(
            <<<SQL
            SELECT COUNT(*)
            FROM sis_aca_pensum p
            JOIN sis_aca_carrera c ON c.car_id = p.pen_car_id
            $where
            SQL,
            $params,
        );
    }

    /** @return array{total:int,active:int,inactive:int,courses:int} */
    public function curriculumMetrics(): array
    {
        $row = $this->connection->fetchAssociative(
            <<<SQL
            SELECT
                COUNT(DISTINCT p.pen_id)::int AS total,
                COUNT(DISTINCT p.pen_id) FILTER (WHERE p.pen_activo)::int AS active,
                COUNT(DISTINCT p.pen_id) FILTER (WHERE NOT p.pen_activo)::int AS inactive,
                COUNT(DISTINCT pc.pcu_id)::int AS courses
            FROM sis_aca_pensum p
            LEFT JOIN sis_aca_pensum_curso pc ON pc.pcu_pen_id = p.pen_id
            SQL
        ) ?: [];

        return [
            'total' => (int) ($row['total'] ?? 0),
            'active' => (int) ($row['active'] ?? 0),
            'inactive' => (int) ($row['inactive'] ?? 0),
            'courses' => (int) ($row['courses'] ?? 0),
        ];
    }

    public function curriculum(int $id): ?array
    {
        $pen = $this->connection->fetchAssociative(
            <<<SQL
            SELECT p.pen_id AS id, p.pen_codigo AS code, p.pen_nombre AS name,
                   p.pen_version AS version, p.pen_vigente_desde, p.pen_vigente_hasta,
                   p.pen_activo AS active, c.car_id AS "careerId", c.car_nombre AS career
            FROM sis_aca_pensum p
            JOIN sis_aca_carrera c ON c.car_id = p.pen_car_id
            WHERE p.pen_id = :id
            SQL,
            ['id' => $id],
        );
        if ($pen === false) {
            return null;
        }
        $pen['id'] = (int) $pen['id'];
        $pen['active'] = (bool) $pen['active'];
        $pen['careerId'] = (int) $pen['careerId'];
        $pen['validity'] = $pen['pen_vigente_hasta'] !== null
            ? 'Vigente hasta ' . (new \DateTimeImmutable($pen['pen_vigente_hasta']))->format('Y')
            : 'Vigente sin fecha de fin';
        $pen['cycles'] = $this->cycles($id);

        $courses = array_merge(...array_map(
            static fn (array $cycle): array => $cycle['courses'],
            $pen['cycles'],
        ));
        $required = count(array_filter(
            $courses,
            static fn (array $course): bool => $course['required'] === 'OBLIGATORIO',
        ));
        $years = array_values(array_unique(array_map(
            static fn (array $cycle): int => (int) $cycle['year'],
            $pen['cycles'],
        )));

        $pen['summary'] = [
            'courses' => count($courses),
            'required' => $required,
            'optional' => count($courses) - $required,
            'cycles' => count($pen['cycles']),
            'years' => count($years),
            'requiredPct' => count($courses) > 0 ? (int) round($required / count($courses) * 100) : 0,
            'activeStudents' => (int) $this->connection->fetchOne(
                "SELECT COUNT(DISTINCT epr_est_id) FROM sis_aca_estudiante_programa WHERE epr_pen_id = :id AND epr_estado = 'ACTIVO'",
                ['id' => $id],
            ),
            'assignedPrograms' => (int) $this->connection->fetchOne(
                "SELECT COUNT(*) FROM sis_aca_estudiante_programa WHERE epr_pen_id = :id",
                ['id' => $id],
            ),
        ];
        $pen['structureLocked'] = $pen['summary']['assignedPrograms'] > 0;

        return $pen;
    }

    /** @return list<array<string, mixed>> */
    private function cycles(int $pensumId): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT c.cic_id AS id, c.cic_nombre AS label, c.cic_anio AS year, c.cic_semestre AS term,
                   pcu.pcu_id AS "curriculumCourseId", cu.cur_codigo AS code, cu.cur_nombre AS name,
                   CASE WHEN pcu.pcu_obligatorio THEN 'OBLIGATORIO' ELSE 'OPTATIVO' END AS required,
                   pcu.pcu_orden AS "order"
            FROM sis_aca_pensum_curso pcu
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = pcu.pcu_cic_id
            JOIN sis_aca_curso cu ON cu.cur_id = pcu.pcu_cur_id
            WHERE pcu.pcu_pen_id = :id
            ORDER BY c.cic_anio, c.cic_semestre, pcu.pcu_orden
            SQL,
            ['id' => $pensumId],
        );

        $byCycle = [];
        foreach ($rows as $r) {
            $cid = $r['id'];
            if (!isset($byCycle[$cid])) {
                $byCycle[$cid] = ['id' => (int) $r['id'], 'label' => $r['label'], 'year' => (int) $r['year'], 'term' => (int) $r['term'], 'courses' => []];
            }
            $byCycle[$cid]['courses'][] = [
                'curriculumCourseId' => (int) $r['curriculumCourseId'],
                'code' => $r['code'],
                'name' => $r['name'],
                'required' => $r['required'],
                'order' => (int) $r['order'],
            ];
        }

        return array_values($byCycle);
    }

    /** @return list<array{id:int,label:string,year:int,term:int}> */
    public function availableCycles(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            'SELECT cic_id AS id, cic_nombre AS label, cic_anio AS year, cic_semestre AS term FROM sis_aca_ciclo_curricular WHERE cic_activo ORDER BY cic_anio, cic_semestre'
        );

        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['year'] = (int) $row['year'];
            $row['term'] = (int) $row['term'];
        }

        return $rows;
    }

    /** @return list<array{id:int,code:string,name:string}> */
    public function sections(): array
    {
        return $this->connection->fetchAllAssociative(
            'SELECT sec_id AS id, sec_codigo AS code, sec_nombre AS name FROM sis_aca_seccion WHERE sec_activo ORDER BY sec_codigo'
        );
    }

    /** @return list<array<string, mixed>> ofertas activas con período, curso, carrera y sección */
    public function offerings(): array
    {
        return $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT o.ofe_id AS id,
                   a.anl_anio || '-' || CASE pa.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS periodo,
                   cu.cur_codigo AS "courseCode", cu.cur_nombre AS "courseName",
                   car.car_nombre AS career, s.sec_codigo AS section,
                   c.cic_nombre AS cycle,
                   CASE WHEN o.ofe_activo THEN 'ACTIVO' ELSE 'INACTIVA' END AS status
            FROM sis_aca_oferta_curso o
            JOIN sis_aca_periodo_academico pa ON pa.per_id = o.ofe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            JOIN sis_aca_pensum_curso pcu ON pcu.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_curso cu ON cu.cur_id = pcu.pcu_cur_id
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = pcu.pcu_cic_id
            JOIN sis_aca_pensum p ON p.pen_id = pcu.pcu_pen_id
            JOIN sis_aca_carrera car ON car.car_id = p.pen_car_id
            JOIN sis_aca_seccion s ON s.sec_id = o.ofe_sec_id
            ORDER BY a.anl_anio, pa.per_numero, cu.cur_codigo
            SQL
        );
    }

    /** @return list<array<string, mixed>> */
    public function periods(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT pa.per_id AS id, a.anl_anio AS year, pa.per_numero AS term,
                   pa.per_estado AS status
            FROM sis_aca_periodo_academico pa
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            ORDER BY a.anl_anio, pa.per_numero
            SQL
        );
        foreach ($rows as &$r) {
            $r['label'] = $r['year'] . '-' . ($r['term'] == 1 ? 'I' : 'II');
            $r['term'] = $r['term'] == 1 ? 'I' : 'II';
        }

        return $rows;
    }

    /** @return array{0:string,1:array<string,mixed>} */
    private function curriculumFilters(string $q, ?string $careerId, string $status): array
    {
        $conditions = [];
        $params = [];

        if ($q !== '') {
            $conditions[] = "(p.pen_codigo ILIKE :q OR p.pen_nombre ILIKE :q OR c.car_nombre ILIKE :q)";
            $params['q'] = '%'.$q.'%';
        }
        if ($careerId !== null && ctype_digit($careerId)) {
            $conditions[] = 'c.car_id = :careerId';
            $params['careerId'] = (int) $careerId;
        }
        if ($status === 'active') {
            $conditions[] = 'p.pen_activo';
        } elseif ($status === 'inactive') {
            $conditions[] = 'NOT p.pen_activo';
        }

        return [
            $conditions === [] ? '' : 'WHERE '.implode(' AND ', $conditions),
            $params,
        ];
    }

    /** @param array<string,mixed> $row @return array<string,mixed> */
    private function normalizeCurriculumRow(array $row): array
    {
        $row['id'] = (int) $row['id'];
        $row['careerId'] = (int) $row['careerId'];
        $row['active'] = (bool) $row['active'];
        $row['courseCount'] = (int) ($row['courseCount'] ?? 0);
        $row['cycleCount'] = (int) ($row['cycleCount'] ?? 0);
        $row['activeStudents'] = (int) ($row['activeStudents'] ?? 0);

        return $row;
    }

}
