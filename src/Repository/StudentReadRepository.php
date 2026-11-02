<?php

namespace App\Repository;

use Doctrine\DBAL\ArrayParameterType;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Types\Types;

final class StudentReadRepository
{
    private const ORDER_BY = [
        'apellidos-asc' => '"lastNames" ASC, "firstNames" ASC, code ASC',
        'apellidos-desc' => '"lastNames" DESC, "firstNames" DESC, code ASC',
        'nombre-asc' => '"firstNames" ASC, "lastNames" ASC, code ASC',
        'avance-desc' => 'progress DESC, "lastNames" ASC, "firstNames" ASC',
        'avance-asc' => 'progress ASC, "lastNames" ASC, "firstNames" ASC',
        'codigo-asc' => 'code ASC',
    ];

    public function __construct(private readonly Connection $connection)
    {
    }

    /**
     * Compatibilidad con consumidores anteriores. Para listados HTTP nuevos
     * preferir searchPage() + countSearch().
     *
     * @return list<array<string, mixed>>
     */
    public function search(string $q = '', ?string $careerId = null, ?string $status = null): array
    {
        return $this->searchPage(
            q: $q,
            careerId: $careerId,
            status: $status,
        );
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function searchPage(
        string $q = '',
        ?string $careerId = null,
        ?string $curriculumId = null,
        ?string $status = null,
        ?int $entryYear = null,
        int $progressMin = 0,
        int $progressMax = 100,
        string $order = 'apellidos-asc',
        ?int $limit = null,
        int $offset = 0,
        ?array $allowedStudentIds = null,
    ): array {
        [$where, $params, $types] = $this->buildFilters(
            $q,
            $careerId,
            $curriculumId,
            $status,
            $entryYear,
            $progressMin,
            $progressMax,
            $allowedStudentIds,
        );

        $orderBy = self::ORDER_BY[$order] ?? self::ORDER_BY['apellidos-asc'];

        $sql = $this->studentDatasetSql()
            . "\nSELECT * FROM student_dataset"
            . $where
            . "\nORDER BY " . $orderBy;

        if ($limit !== null) {
            $sql .= "\nLIMIT :limit OFFSET :offset";
            $params['limit'] = max(1, $limit);
            $params['offset'] = max(0, $offset);
            $types['limit'] = Types::INTEGER;
            $types['offset'] = Types::INTEGER;
        }

        $rows = $this->connection->fetchAllAssociative($sql, $params, $types);

        return array_map($this->normalizeRow(...), $rows);
    }

    public function countSearch(
        string $q = '',
        ?string $careerId = null,
        ?string $curriculumId = null,
        ?string $status = null,
        ?int $entryYear = null,
        int $progressMin = 0,
        int $progressMax = 100,
        ?array $allowedStudentIds = null,
    ): int {
        [$where, $params, $types] = $this->buildFilters(
            $q,
            $careerId,
            $curriculumId,
            $status,
            $entryYear,
            $progressMin,
            $progressMax,
            $allowedStudentIds,
        );

        return (int) $this->connection->fetchOne(
            $this->studentDatasetSql() . "\nSELECT COUNT(*) FROM student_dataset" . $where,
            $params,
            $types,
        );
    }

    /** @param list<int>|null $allowedStudentIds */
    public function count(?array $allowedStudentIds = null): int
    {
        return $this->countSearch(allowedStudentIds: $allowedStudentIds);
    }

    public function idFromCode(string $code): ?int
    {
        $id = $this->connection->fetchOne(
            'SELECT est_id FROM sis_aca_estudiante WHERE est_codigo = :code LIMIT 1',
            ['code' => $code],
        );

        return $id === false ? null : (int) $id;
    }

    /** @param list<int>|null $allowedStudentIds @return array{total:int, active:int, inactive:int, retired:int, avgProgress:float} */
    public function metrics(?array $allowedStudentIds = null): array
    {
        [$where, $params, $types] = $this->buildFilters('', null, null, null, null, 0, 100, $allowedStudentIds);

        $row = $this->connection->fetchAssociative(
            $this->studentDatasetSql() . <<<'SQL'

SELECT
    COUNT(*)::int AS total,
    COUNT(*) FILTER (WHERE status = 'ACTIVO')::int AS active,
    COUNT(*) FILTER (WHERE status <> 'ACTIVO')::int AS inactive,
    COUNT(*) FILTER (WHERE status = 'RETIRADO')::int AS retired,
    COALESCE(AVG(progress) FILTER (WHERE status = 'ACTIVO'), 0) AS "avgProgress"
FROM student_dataset
SQL
            .$where,
            $params,
            $types,
        ) ?: [];

        return [
            'total' => (int) ($row['total'] ?? 0),
            'active' => (int) ($row['active'] ?? 0),
            'inactive' => (int) ($row['inactive'] ?? 0),
            'retired' => (int) ($row['retired'] ?? 0),
            'avgProgress' => (float) ($row['avgProgress'] ?? 0),
        ];
    }

    public function findProfile(int $id): ?array
    {
        $row = $this->connection->fetchAssociative(
            $this->studentDatasetSql() . "\nSELECT * FROM student_dataset WHERE id = :id LIMIT 1",
            ['id' => $id],
            ['id' => Types::INTEGER],
        );

        if ($row === false) {
            return null;
        }

        $row = $this->normalizeRow($row);
        $current = $this->currentPeriod($id);
        $row['currentPeriod'] = $current['periodLabel'] ?? null;
        $row['currentPeriodStatus'] = $current['periodStatus'] ?? null;
        $row['section'] = $current['section'] ?? null;
        $row['cycle'] = $current['cycle'] ?? null;
        $row['enrollmentStatus'] = $current['enrollmentStatus'] ?? 'SIN_REGISTRO';

        return $row;
    }

    private function entryYear(int $id): ?int
    {
        $v = $this->connection->fetchOne(
            'SELECT EXTRACT(YEAR FROM MIN(epr_fecha_inicio))::int FROM sis_aca_estudiante_programa WHERE epr_est_id = :id',
            ['id' => $id],
        );

        return $v !== false && $v !== null ? (int) $v : null;
    }

    private function currentPeriod(int $id): ?array
    {
        $row = $this->connection->fetchAssociative(
            <<<SQL
            SELECT a.anl_anio || '-' || CASE pa.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS "periodLabel",
                   c.cic_nombre AS cycle, s.sec_codigo AS section, ep.epe_estado AS "enrollmentStatus",
                   pa.per_estado AS "periodStatus"
            FROM sis_aca_estudiante_periodo ep
            JOIN sis_aca_periodo_academico pa ON pa.per_id = ep.epe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = ep.epe_cic_id
            JOIN sis_aca_seccion s ON s.sec_id = ep.epe_sec_id
            JOIN sis_aca_estudiante_programa epr ON epr.epr_id = ep.epe_epr_id
            WHERE epr.epr_est_id = :id
            ORDER BY a.anl_anio DESC, pa.per_numero DESC
            LIMIT 1
            SQL,
            ['id' => $id],
        );

        return $row === false ? null : $row;
    }

    /** @return list<array<string, mixed>> */
    public function periods(int $id): array
    {
        return $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT a.anl_anio || '-' || CASE pa.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS "periodLabel",
                   a.anl_anio AS year, pa.per_numero AS term, c.cic_nombre AS cycle,
                   s.sec_codigo AS section, ep.epe_estado AS "enrollmentStatus",
                   pa.per_estado AS "periodStatus"
            FROM sis_aca_estudiante_periodo ep
            JOIN sis_aca_periodo_academico pa ON pa.per_id = ep.epe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = ep.epe_cic_id
            JOIN sis_aca_seccion s ON s.sec_id = ep.epe_sec_id
            JOIN sis_aca_estudiante_programa epr ON epr.epr_id = ep.epe_epr_id
            WHERE epr.epr_est_id = :id
            ORDER BY a.anl_anio, pa.per_numero
            SQL,
            ['id' => $id],
        );
    }

    /** @return list<array<string, mixed>> */
    public function results(int $id): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT v.anl_anio || '-' || CASE v.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS period,
                   v.cur_codigo AS "courseCode", v.cur_nombre AS "courseName",
                   CASE WHEN v.pcu_obligatorio THEN 'OBLIGATORIO' ELSE 'OPTATIVO' END AS required,
                   v.sec_codigo AS section, v.res_nota AS grade, v.res_estado AS status,
                   v.res_numero_intento AS attempt
            FROM sis_aca_vw_resultado_estudiante v
            WHERE v.est_id = :id
            ORDER BY v.anl_anio, v.per_numero, v.res_numero_intento
            SQL,
            ['id' => $id],
        );

        foreach ($rows as &$row) {
            $row['grade'] = $row['grade'] !== null ? (float) $row['grade'] : null;
        }

        return $rows;
    }

    /** @return list<array<string, mixed>> */
    public function gradeEntryEnrollments(int $studentId): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                ep.epe_id AS "enrollmentId",
                a.anl_anio AS year,
                pa.per_numero AS term,
                a.anl_anio || '-' || CASE pa.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS "periodLabel",
                pa.per_estado AS "periodStatus",
                ep.epe_estado AS "enrollmentStatus",
                c.cic_nombre AS cycle,
                s.sec_codigo AS section
            FROM sis_aca_estudiante_periodo ep
            JOIN sis_aca_estudiante_programa epr ON epr.epr_id = ep.epe_epr_id
            JOIN sis_aca_periodo_academico pa ON pa.per_id = ep.epe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
            JOIN sis_aca_ciclo_curricular c ON c.cic_id = ep.epe_cic_id
            JOIN sis_aca_seccion s ON s.sec_id = ep.epe_sec_id
            WHERE epr.epr_est_id = :studentId
            ORDER BY a.anl_anio DESC, pa.per_numero DESC, ep.epe_id DESC
            SQL,
            ['studentId' => $studentId],
        );

        foreach ($rows as &$row) {
            $row['enrollmentId'] = (int) $row['enrollmentId'];
            $row['year'] = (int) $row['year'];
            $row['term'] = (int) $row['term'];
        }

        return $rows;
    }

    /** @return list<array<string, mixed>> */
    public function gradeEntryRows(int $studentId, int $enrollmentId): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT
                   v.epe_id AS "enrollmentId",
                   v.pcu_id AS "curriculumCourseId",
                   v.cur_codigo AS "courseCode",
                   v.cur_nombre AS "courseName",
                   CASE WHEN v.pcu_obligatorio THEN 'OBLIGATORIO' ELSE 'OPTATIVO' END AS required,
                   v.ing_origen AS origin,
                   v.pcu_cic_nombre AS "originalCycle",
                   v.ofe_id AS "offeringId",
                   v.ofe_activo AS "offeringActive",
                   v.res_nota AS grade,
                   v.ing_estado AS status,
                   v.ing_editable AS editable,
                   v.ing_motivo_bloqueo AS "blockReason",
                   v.res_id AS "resultId"
            FROM sis_aca_vw_ingreso_notas v
            WHERE v.est_id = :studentId
              AND v.epe_id = :enrollmentId
            ORDER BY
                CASE v.ing_origen
                    WHEN 'CICLO_ACTUAL' THEN 1
                    WHEN 'CICLO_ANTERIOR' THEN 2
                    ELSE 3
                END,
                v.pcu_orden,
                v.cur_codigo
            SQL,
            [
                'studentId' => $studentId,
                'enrollmentId' => $enrollmentId,
            ],
        );

        foreach ($rows as &$row) {
            $row['grade'] = $row['grade'] !== null ? (float) $row['grade'] : null;
            $row['editable'] = (bool) $row['editable'];
            $row['offeringId'] = $row['offeringId'] !== null ? (int) $row['offeringId'] : null;
            $row['enrollmentId'] = (int) $row['enrollmentId'];
            $row['offeringActive'] = $row['offeringActive'] !== null ? (bool) $row['offeringActive'] : false;
            $row['statusLabel'] = \App\Ui\UiState\StatusCatalog::label((string) $row['status']);
            $row['blockMessage'] = $row['blockReason'] !== null && $row['blockReason'] !== ''
                ? \App\Ui\UiState\StatusCatalog::blockMessage((string) $row['blockReason'])
                : null;
            $row['originLabel'] = match ($row['origin']) {
                'CICLO_ACTUAL' => 'Ciclo actual',
                'CICLO_ANTERIOR' => 'Ciclo anterior',
                default => 'Otro ciclo',
            };
        }

        return $rows;
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function searchTranscriptPage(
        string $q = '',
        ?string $careerId = null,
        ?string $curriculumId = null,
        ?string $status = null,
        ?int $entryYear = null,
        string $history = 'all',
        string $order = 'apellidos-asc',
        ?int $limit = null,
        int $offset = 0,
        ?array $allowedStudentIds = null,
    ): array {
        [$where, $params, $types] = $this->buildFilters(
            $q,
            $careerId,
            $curriculumId,
            $status,
            $entryYear,
            0,
            100,
            $allowedStudentIds,
        );

        $where = $this->appendHistoryFilter($where, $history);

        $orders = [
            'apellidos-asc' => '"lastNames" ASC, "firstNames" ASC, code ASC',
            'codigo-asc' => 'code ASC',
            'avance-desc' => 'progress DESC, "lastNames" ASC, "firstNames" ASC',
            'historial-desc' => '"resultsCount" DESC, "periodsCount" DESC, "lastNames" ASC',
        ];
        $orderBy = $orders[$order] ?? $orders['apellidos-asc'];

        $sql = $this->transcriptDatasetSql()
            . "\nSELECT * FROM transcript_dataset"
            . $where
            . "\nORDER BY ".$orderBy;

        if ($limit !== null) {
            $sql .= "\nLIMIT :limit OFFSET :offset";
            $params['limit'] = max(1, $limit);
            $params['offset'] = max(0, $offset);
            $types['limit'] = Types::INTEGER;
            $types['offset'] = Types::INTEGER;
        }

        $rows = $this->connection->fetchAllAssociative($sql, $params, $types);

        return array_map(function (array $row): array {
            $row = $this->normalizeRow($row);
            $row['periodsCount'] = (int) ($row['periodsCount'] ?? 0);
            $row['resultsCount'] = (int) ($row['resultsCount'] ?? 0);

            return $row;
        }, $rows);
    }


    /**
     * Búsqueda de estudiantes restringida a un conjunto autorizado.
     * Se usa para el rol docente: el filtro de autorización se aplica en SQL,
     * no después de recuperar el directorio institucional.
     *
     * @param list<int> $studentIds
     *
     * @return list<array<string,mixed>>
     */
    public function searchTranscriptPageByIds(
        array $studentIds,
        string $q = '',
        ?int $limit = null,
        int $offset = 0,
    ): array {
        if ($studentIds === []) {
            return [];
        }

        $params = ['studentIds' => array_values(array_unique(array_map('intval', $studentIds)))];
        $types = ['studentIds' => ArrayParameterType::INTEGER];
        $where = ['id IN (:studentIds)'];

        $q = trim($q);
        if ($q !== '') {
            $where[] = '(code ILIKE :q OR "firstNames" ILIKE :q OR "lastNames" ILIKE :q OR "fullName" ILIKE :q)';
            $params['q'] = '%'.$q.'%';
        }

        $sql = $this->transcriptDatasetSql()
            ."\nSELECT * FROM transcript_dataset"
            ."\nWHERE ".implode("\n  AND ", $where)
            ."\nORDER BY \"lastNames\" ASC, \"firstNames\" ASC, code ASC";

        if ($limit !== null) {
            $sql .= "\nLIMIT :limit OFFSET :offset";
            $params['limit'] = max(1, $limit);
            $params['offset'] = max(0, $offset);
            $types['limit'] = Types::INTEGER;
            $types['offset'] = Types::INTEGER;
        }

        $rows = $this->connection->fetchAllAssociative($sql, $params, $types);

        return array_map(function (array $row): array {
            $row = $this->normalizeRow($row);
            $row['periodsCount'] = (int) ($row['periodsCount'] ?? 0);
            $row['resultsCount'] = (int) ($row['resultsCount'] ?? 0);

            return $row;
        }, $rows);
    }

    /**
     * @param list<int> $studentIds
     */
    public function countTranscriptSearchByIds(array $studentIds, string $q = ''): int
    {
        if ($studentIds === []) {
            return 0;
        }

        $params = ['studentIds' => array_values(array_unique(array_map('intval', $studentIds)))];
        $types = ['studentIds' => ArrayParameterType::INTEGER];
        $where = ['id IN (:studentIds)'];

        $q = trim($q);
        if ($q !== '') {
            $where[] = '(code ILIKE :q OR "firstNames" ILIKE :q OR "lastNames" ILIKE :q OR "fullName" ILIKE :q)';
            $params['q'] = '%'.$q.'%';
        }

        return (int) $this->connection->fetchOne(
            $this->transcriptDatasetSql()
            ."\nSELECT COUNT(*) FROM transcript_dataset"
            ."\nWHERE ".implode("\n  AND ", $where),
            $params,
            $types,
        );
    }

    public function countTranscriptSearch(
        string $q = '',
        ?string $careerId = null,
        ?string $curriculumId = null,
        ?string $status = null,
        ?int $entryYear = null,
        string $history = 'all',
        ?array $allowedStudentIds = null,
    ): int {
        [$where, $params, $types] = $this->buildFilters(
            $q,
            $careerId,
            $curriculumId,
            $status,
            $entryYear,
            0,
            100,
            $allowedStudentIds,
        );

        $where = $this->appendHistoryFilter($where, $history);

        return (int) $this->connection->fetchOne(
            $this->transcriptDatasetSql()."\nSELECT COUNT(*) FROM transcript_dataset".$where,
            $params,
            $types,
        );
    }

    /** @param list<int>|null $allowedStudentIds @return array{total:int, withHistory:int, withoutHistory:int, results:int} */
    public function transcriptMetrics(?array $allowedStudentIds = null): array
    {
        [$where, $params, $types] = $this->buildFilters('', null, null, null, null, 0, 100, $allowedStudentIds);

        $row = $this->connection->fetchAssociative(
            $this->transcriptDatasetSql().<<<'SQL'

SELECT
    COUNT(*)::int AS total,
    COUNT(*) FILTER (WHERE "periodsCount" > 0)::int AS "withHistory",
    COUNT(*) FILTER (WHERE "periodsCount" = 0)::int AS "withoutHistory",
    COALESCE(SUM("resultsCount"), 0)::int AS results
FROM transcript_dataset
SQL
            .$where,
            $params,
            $types,
        ) ?: [];

        return [
            'total' => (int) ($row['total'] ?? 0),
            'withHistory' => (int) ($row['withHistory'] ?? 0),
            'withoutHistory' => (int) ($row['withoutHistory'] ?? 0),
            'results' => (int) ($row['results'] ?? 0),
        ];
    }

    /** @param list<int>|null $allowedStudentIds */
    public function resultsCount(?array $allowedStudentIds = null): int
    {
        if ($allowedStudentIds === null) {
            return (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_aca_resultado_curso');
        }

        $ids = array_values(array_unique(array_map('intval', $allowedStudentIds)));
        if ($ids === []) {
            return 0;
        }

        return (int) $this->connection->fetchOne(
            'SELECT COUNT(*) FROM sis_aca_vw_resultado_estudiante WHERE est_id IN (:ids)',
            ['ids' => $ids],
            ['ids' => ArrayParameterType::INTEGER],
        );
    }

    /** Programa vigente del estudiante (el ACTIVO, o el más reciente si no hay activo). */
    public function program(int $studentId): ?array
    {
        $row = $this->connection->fetchAssociative(
            <<<SQL
            SELECT epr_id AS id, epr_pen_id AS "curriculumId",
                   epr_fecha_inicio AS "startDate", epr_estado AS status
            FROM sis_aca_estudiante_programa
            WHERE epr_est_id = :id
            ORDER BY (epr_estado = 'ACTIVO') DESC, epr_fecha_inicio DESC, epr_id DESC
            LIMIT 1
            SQL,
            ['id' => $studentId],
        );

        if ($row === false) {
            return null;
        }

        $row['id'] = (int) $row['id'];
        $row['curriculumId'] = (int) $row['curriculumId'];
        $row['startDate'] = $row['startDate'] instanceof \DateTimeInterface
            ? $row['startDate']->format('Y-m-d')
            : (string) $row['startDate'];

        return $row;
    }

    /** @return array{periods:int, results:int} */
    public function academicHistory(int $studentId): array
    {
        $periods = (int) $this->connection->fetchOne(
            'SELECT COUNT(*) FROM sis_aca_estudiante_periodo e JOIN sis_aca_estudiante_programa p ON p.epr_id = e.epe_epr_id WHERE p.epr_est_id = :id',
            ['id' => $studentId],
        );
        $results = (int) $this->connection->fetchOne(
            'SELECT COUNT(*) FROM sis_aca_resultado_curso r JOIN sis_aca_estudiante_periodo e ON e.epe_id = r.res_epe_id JOIN sis_aca_estudiante_programa p ON p.epr_id = e.epe_epr_id WHERE p.epr_est_id = :id',
            ['id' => $studentId],
        );

        return ['periods' => $periods, 'results' => $results];
    }

    /** @return list<array{id:int,name:string}> */
    public function careers(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            'SELECT car_id AS id, car_nombre AS name FROM sis_aca_carrera WHERE car_activo ORDER BY car_nombre',
        );

        return array_map(
            fn (array $row) => ['id' => (int) $row['id'], 'name' => $row['name']],
            $rows,
        );
    }

    /** @return list<array{id:int,careerId:int,name:string,code:string}> */
    public function curricula(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<SQL
            SELECT pen_id AS id, pen_car_id AS "careerId", pen_nombre AS name, pen_codigo AS code
            FROM sis_aca_pensum
            WHERE pen_activo
            ORDER BY pen_nombre, pen_codigo
            SQL,
        );

        return array_map(
            fn (array $row) => [
                'id' => (int) $row['id'],
                'careerId' => (int) $row['careerId'],
                'name' => (string) $row['name'],
                'code' => (string) $row['code'],
            ],
            $rows,
        );
    }

    /** @return list<int> */
    public function entryYears(): array
    {
        $rows = $this->connection->fetchFirstColumn(
            <<<SQL
            SELECT DISTINCT EXTRACT(YEAR FROM epr_fecha_inicio)::int AS entry_year
            FROM sis_aca_estudiante_programa
            WHERE epr_fecha_inicio IS NOT NULL
            ORDER BY entry_year DESC
            SQL,
        );

        return array_map('intval', $rows);
    }

    /** @return list<string> */
    public function statuses(): array
    {
        $rows = $this->connection->fetchFirstColumn(
            $this->studentDatasetSql() . "\nSELECT DISTINCT status FROM student_dataset ORDER BY status",
        );

        return array_values(array_filter(array_map('strval', $rows)));
    }

    private function studentDatasetSql(): string
    {
        return <<<'SQL'
WITH current_program AS (
    SELECT
        ep.*,
        ROW_NUMBER() OVER (
            PARTITION BY ep.epr_est_id
            ORDER BY
                (ep.epr_estado = 'ACTIVO') DESC,
                ep.epr_fecha_inicio DESC NULLS LAST,
                ep.epr_id DESC
        ) AS rn
    FROM sis_aca_estudiante_programa ep
),
first_program AS (
    SELECT
        epr_est_id AS est_id,
        MIN(epr_fecha_inicio) AS first_start
    FROM sis_aca_estudiante_programa
    GROUP BY epr_est_id
),
student_dataset AS (
    SELECT
        e.est_id AS id,
        e.est_codigo AS code,
        e.est_nombres AS "firstNames",
        e.est_apellidos AS "lastNames",
        e.est_nombres || ' ' || e.est_apellidos AS "fullName",
        e.est_fecha_nacimiento AS "birthDate",
        e.est_direccion AS address,
        e.est_foto_ruta AS "photoPath",
        e.est_activo AS active,
        CASE
            WHEN cp.epr_estado IS NOT NULL THEN cp.epr_estado
            WHEN e.est_activo THEN 'ACTIVO'
            ELSE 'INACTIVO'
        END AS status,
        cp.epr_estado AS "programStatus",
        c.car_id AS "careerId",
        c.car_nombre AS career,
        p.pen_id AS "curriculumId",
        p.pen_nombre AS curriculum,
        p.pen_codigo AS "curriculumCode",
        EXTRACT(YEAR FROM fp.first_start)::int AS "entryYear",
        COALESCE(v.ava_porcentaje, 0) AS progress,
        COALESCE(v.ava_cursos_aprobados, 0) AS approved,
        COALESCE(v.ava_cursos_pendientes, 0) AS pending,
        COALESCE(v.ava_cursos_obligatorios, 0) AS required,
        (
            SELECT COUNT(*)
            FROM sis_aca_vw_resultado_estudiante vr
            WHERE vr.est_id = e.est_id
              AND vr.res_estado = 'REPROBADO'
        )::int AS repeats
    FROM sis_aca_estudiante e
    LEFT JOIN current_program cp
        ON cp.epr_est_id = e.est_id
       AND cp.rn = 1
    LEFT JOIN sis_aca_pensum p
        ON p.pen_id = cp.epr_pen_id
    LEFT JOIN sis_aca_carrera c
        ON c.car_id = p.pen_car_id
    LEFT JOIN sis_aca_vw_avance_pensum v
        ON v.epr_id = cp.epr_id
    LEFT JOIN first_program fp
        ON fp.est_id = e.est_id
)
SQL;
    }

    private function transcriptDatasetSql(): string
    {
        return $this->studentDatasetSql().<<<'SQL'
,
transcript_history AS (
    SELECT
        epr.epr_est_id AS est_id,
        COUNT(DISTINCT ep.epe_id)::int AS periods_count,
        COUNT(r.res_id)::int AS results_count
    FROM sis_aca_estudiante_programa epr
    LEFT JOIN sis_aca_estudiante_periodo ep
        ON ep.epe_epr_id = epr.epr_id
    LEFT JOIN sis_aca_resultado_curso r
        ON r.res_epe_id = ep.epe_id
    GROUP BY epr.epr_est_id
),
latest_period AS (
    SELECT *
    FROM (
        SELECT
            epr.epr_est_id AS est_id,
            a.anl_anio || '-' || CASE pa.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS last_period,
            pa.per_estado AS last_period_status,
            ep.epe_estado AS last_enrollment_status,
            c.cic_nombre AS last_cycle,
            s.sec_codigo AS last_section,
            ROW_NUMBER() OVER (
                PARTITION BY epr.epr_est_id
                ORDER BY a.anl_anio DESC, pa.per_numero DESC, ep.epe_id DESC
            ) AS rn
        FROM sis_aca_estudiante_periodo ep
        JOIN sis_aca_estudiante_programa epr ON epr.epr_id = ep.epe_epr_id
        JOIN sis_aca_periodo_academico pa ON pa.per_id = ep.epe_per_id
        JOIN sis_aca_anio_lectivo a ON a.anl_id = pa.per_anl_id
        JOIN sis_aca_ciclo_curricular c ON c.cic_id = ep.epe_cic_id
        JOIN sis_aca_seccion s ON s.sec_id = ep.epe_sec_id
    ) ranked
    WHERE rn = 1
),
transcript_dataset AS (
    SELECT
        sd.*,
        COALESCE(th.periods_count, 0)::int AS "periodsCount",
        COALESCE(th.results_count, 0)::int AS "resultsCount",
        lp.last_period AS "lastPeriod",
        lp.last_period_status AS "lastPeriodStatus",
        lp.last_enrollment_status AS "lastEnrollmentStatus",
        lp.last_cycle AS "lastCycle",
        lp.last_section AS "lastSection"
    FROM student_dataset sd
    LEFT JOIN transcript_history th ON th.est_id = sd.id
    LEFT JOIN latest_period lp ON lp.est_id = sd.id
)
SQL;
    }

    private function appendHistoryFilter(string $where, string $history): string
    {
        $clause = match ($history) {
            'with' => '"periodsCount" > 0',
            'without' => '"periodsCount" = 0',
            default => null,
        };

        if ($clause === null) {
            return $where;
        }

        return $where === ''
            ? "\nWHERE ".$clause
            : $where."\n  AND ".$clause;
    }

    /**
     * @return array{0:string,1:array<string,mixed>,2:array<string,string>}
     */
    private function buildFilters(
        string $q,
        ?string $careerId,
        ?string $curriculumId,
        ?string $status,
        ?int $entryYear,
        int $progressMin,
        int $progressMax,
        ?array $allowedStudentIds = null,
    ): array {
        $clauses = [];
        $params = [];
        $types = [];

        $q = trim($q);
        if ($q !== '') {
            $clauses[] = '(code ILIKE :q OR "firstNames" ILIKE :q OR "lastNames" ILIKE :q OR "fullName" ILIKE :q)';
            $params['q'] = '%' . $q . '%';
        }

        if ($careerId !== null && $careerId !== '') {
            $clauses[] = '"careerId" = :careerId';
            $params['careerId'] = (int) $careerId;
            $types['careerId'] = Types::INTEGER;
        }

        if ($curriculumId !== null && $curriculumId !== '') {
            $clauses[] = '"curriculumId" = :curriculumId';
            $params['curriculumId'] = (int) $curriculumId;
            $types['curriculumId'] = Types::INTEGER;
        }

        if ($status !== null && $status !== '') {
            $clauses[] = 'status = :status';
            $params['status'] = $status;
        }

        if ($entryYear !== null) {
            $clauses[] = '"entryYear" = :entryYear';
            $params['entryYear'] = $entryYear;
            $types['entryYear'] = Types::INTEGER;
        }

        if ($allowedStudentIds !== null) {
            $ids = array_values(array_unique(array_map('intval', $allowedStudentIds)));
            if ($ids === []) {
                $clauses[] = '1 = 0';
            } else {
                $clauses[] = 'id IN (:allowedStudentIds)';
                $params['allowedStudentIds'] = $ids;
                $types['allowedStudentIds'] = ArrayParameterType::INTEGER;
            }
        }

        $progressMin = max(0, min(100, $progressMin));
        $progressMax = max(0, min(100, $progressMax));
        if ($progressMin > $progressMax) {
            [$progressMin, $progressMax] = [$progressMax, $progressMin];
        }

        if ($progressMin > 0) {
            $clauses[] = 'progress >= :progressMin';
            $params['progressMin'] = $progressMin;
            $types['progressMin'] = Types::INTEGER;
        }

        if ($progressMax < 100) {
            $clauses[] = 'progress <= :progressMax';
            $params['progressMax'] = $progressMax;
            $types['progressMax'] = Types::INTEGER;
        }

        $where = $clauses === [] ? '' : "\nWHERE " . implode("\n  AND ", $clauses);

        return [$where, $params, $types];
    }

    /** @param array<string, mixed> $row */
    private function normalizeRow(array $row): array
    {
        $row['id'] = (int) $row['id'];
        $row['active'] = (bool) $row['active'];
        $row['careerId'] = $row['careerId'] !== null ? (int) $row['careerId'] : null;
        $row['curriculumId'] = $row['curriculumId'] !== null ? (int) $row['curriculumId'] : null;
        $row['entryYear'] = $row['entryYear'] !== null ? (int) $row['entryYear'] : null;
        $row['progress'] = (float) ($row['progress'] ?? 0);
        $row['approved'] = (int) ($row['approved'] ?? 0);
        $row['pending'] = (int) ($row['pending'] ?? 0);
        $row['required'] = (int) ($row['required'] ?? 0);
        $row['repeats'] = (int) ($row['repeats'] ?? 0);

        return $row;
    }
}
