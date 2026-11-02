<?php

namespace App\Repository;

use App\Service\InstitutionalCodeGenerator;
use Doctrine\DBAL\Connection;

final class StudentWriteRepository
{
    public function __construct(
        private readonly Connection $connection,
        private readonly InstitutionalCodeGenerator $codes,
    ) {
    }

    public function codeExists(string $code, ?int $exceptStudentId = null): bool
    {
        $sql = 'SELECT 1 FROM sis_aca_estudiante WHERE est_codigo = :code';
        $params = ['code' => $code];
        if ($exceptStudentId !== null) {
            $sql .= ' AND est_id <> :id';
            $params['id'] = $exceptStudentId;
        }

        return (bool) $this->connection->fetchOne($sql.' LIMIT 1', $params);
    }

    public function curriculumAvailableForDate(int $id, string $programStartDate, bool $allowInactive = false): bool
    {
        $activeClause = $allowInactive ? '' : 'AND pen_activo';

        return (bool) $this->connection->fetchOne(
            "SELECT 1
             FROM sis_aca_pensum
             WHERE pen_id = :id
               {$activeClause}
               AND pen_vigente_desde <= :startDate
               AND (pen_vigente_hasta IS NULL OR :startDate <= pen_vigente_hasta)
             LIMIT 1",
            ['id' => $id, 'startDate' => $programStartDate],
        );
    }

    /**
     * Genera el carné dentro de la misma transacción del alta.
     * El lock transaccional por año evita que dos altas concurrentes reciban
     * el mismo correlativo.
     *
     * @return array{studentId:int, programId:int, code:string}
     */
    public function create(
        string $firstNames,
        string $lastNames,
        string $birthDate,
        ?string $address,
        int $curriculumId,
        string $programStartDate,
        ?string $photoPath = null,
        string $programStatus = 'ACTIVO',
    ): array {
        $this->connection->beginTransaction();

        try {
            if (!$this->curriculumAvailableForDate($curriculumId, $programStartDate)) {
                throw new \RuntimeException('El pensum seleccionado no está activo o no es vigente para la fecha de ingreso.');
            }

            $code = $this->codes->nextStudentCode($programStartDate);

            $studentId = (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_estudiante (
                    est_codigo,
                    est_nombres,
                    est_apellidos,
                    est_fecha_nacimiento,
                    est_direccion,
                    est_foto_ruta,
                    est_activo
                ) VALUES (
                    :code,
                    :firstNames,
                    :lastNames,
                    :birthDate,
                    :address,
                    :photoPath,
                    TRUE
                )
                RETURNING est_id
                SQL,
                [
                    'code' => $code,
                    'firstNames' => $firstNames,
                    'lastNames' => $lastNames,
                    'birthDate' => $birthDate,
                    'address' => $address !== '' ? $address : null,
                    'photoPath' => $photoPath,
                ],
            );

            if ($studentId <= 0) {
                throw new \RuntimeException('No fue posible obtener el identificador del estudiante recién creado.');
            }

            $programId = (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_estudiante_programa (
                    epr_est_id,
                    epr_pen_id,
                    epr_fecha_inicio,
                    epr_estado
                ) VALUES (
                    :studentId,
                    :curriculumId,
                    :programStartDate,
                    :programStatus
                )
                RETURNING epr_id
                SQL,
                [
                    'studentId' => $studentId,
                    'curriculumId' => $curriculumId,
                    'programStartDate' => $programStartDate,
                    'programStatus' => $programStatus,
                ],
            );

            if ($programId <= 0) {
                throw new \RuntimeException('No fue posible obtener el identificador del programa académico recién creado.');
            }

            $this->connection->commit();

            return [
                'studentId' => $studentId,
                'programId' => $programId,
                'code' => $code,
            ];
        } catch (\Doctrine\DBAL\Exception $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    /**
     * Actualiza los datos editables. El carné no se modifica: es identidad
     * generada por el sistema y permanece estable durante toda la trayectoria.
     */
    public function update(
        int $studentId,
        string $firstNames,
        string $lastNames,
        string $birthDate,
        ?string $address,
        int $curriculumId,
        string $programStartDate,
        string $programStatus,
        ?string $photoPath = null,
    ): void {
        $program = $this->connection->fetchAssociative(
            'SELECT epr_id, epr_pen_id, epr_fecha_fin FROM sis_aca_estudiante_programa WHERE epr_est_id = :id ORDER BY (epr_estado = \'ACTIVO\') DESC, epr_fecha_inicio DESC LIMIT 1',
            ['id' => $studentId],
        );
        if ($program === false) {
            throw new \RuntimeException('El estudiante no tiene programa académico asociado.');
        }

        $sameCurriculum = (int) $program['epr_pen_id'] === $curriculumId;
        if (!$this->curriculumAvailableForDate($curriculumId, $programStartDate, $sameCurriculum)) {
            throw new \RuntimeException('El pensum seleccionado no es vigente para la fecha de ingreso indicada.');
        }

        $endDate = $programStatus === 'ACTIVO'
            ? null
            : ($program['epr_fecha_fin'] ?? date('Y-m-d'));

        $this->connection->beginTransaction();
        try {
            $this->connection->update('sis_aca_estudiante', [
                'est_nombres' => $firstNames,
                'est_apellidos' => $lastNames,
                'est_fecha_nacimiento' => $birthDate,
                'est_direccion' => $address !== '' ? $address : null,
                'est_foto_ruta' => $photoPath,
                'est_activo' => $programStatus !== 'RETIRADO' ? 'true' : 'false',
            ], ['est_id' => $studentId]);

            $this->connection->update('sis_aca_estudiante_programa', [
                'epr_pen_id' => $curriculumId,
                'epr_fecha_inicio' => $programStartDate,
                'epr_estado' => $programStatus,
                'epr_fecha_fin' => $endDate,
            ], ['epr_id' => (int) $program['epr_id']]);

            $this->connection->commit();
        } catch (\Doctrine\DBAL\Exception $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    /** @param list<array{enrollmentId:int,offeringId:int,grade:float|null}> $entries */
    public function saveGrades(array $entries): int
    {
        if ($entries === []) {
            return 0;
        }

        $this->connection->beginTransaction();
        try {
            $written = 0;
            foreach ($entries as $entry) {
                $existingId = $this->connection->fetchOne(
                    'SELECT res_id FROM sis_aca_resultado_curso WHERE res_epe_id = :epe AND res_ofe_id = :ofe FOR UPDATE',
                    ['epe' => $entry['enrollmentId'], 'ofe' => $entry['offeringId']],
                );
                $grade = $entry['grade'];
                $gradedAt = $grade === null ? null : (new \DateTimeImmutable())->format('Y-m-d H:i:sP');

                if ($existingId === false) {
                    if ($grade === null) {
                        continue;
                    }
                    $this->connection->insert('sis_aca_resultado_curso', [
                        'res_epe_id' => $entry['enrollmentId'],
                        'res_ofe_id' => $entry['offeringId'],
                        'res_nota' => $grade,
                        'res_calificado_en' => $gradedAt,
                    ]);
                } else {
                    $this->connection->update('sis_aca_resultado_curso', [
                        'res_nota' => $grade,
                        'res_calificado_en' => $gradedAt,
                    ], ['res_id' => (int) $existingId]);
                }
                ++$written;
            }

            $this->connection->commit();

            return $written;
        } catch (\Doctrine\DBAL\Exception $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    public function delete(int $studentId): void
    {
        $this->connection->beginTransaction();
        try {
            $student = $this->connection->fetchAssociative(
                'SELECT est_id FROM sis_aca_estudiante WHERE est_id = :id FOR UPDATE',
                ['id' => $studentId],
            );
            if ($student === false) {
                throw new \RuntimeException('El estudiante no existe.');
            }

            $periods = (int) $this->connection->fetchOne(
                'SELECT COUNT(*) FROM sis_aca_estudiante_periodo ep
                 JOIN sis_aca_estudiante_programa pr ON pr.epr_id = ep.epe_epr_id
                 WHERE pr.epr_est_id = :id',
                ['id' => $studentId],
            );
            if ($periods > 0) {
                throw new \RuntimeException('La ficha no puede eliminarse porque ya tiene historial académico. Utiliza el estado RETIRADO para conservar la trazabilidad.');
            }

            $this->connection->executeStatement('DELETE FROM sis_aca_estudiante_programa WHERE epr_est_id = :id', ['id' => $studentId]);
            $this->connection->executeStatement('DELETE FROM sis_aca_estudiante WHERE est_id = :id', ['id' => $studentId]);
            $this->connection->commit();
        } catch (\Doctrine\DBAL\Exception $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    private function domainMessage(\Throwable $e): string
    {
        $sqlState = null;
        for ($t = $e; $t !== null; $t = $t->getPrevious()) {
            if ($t instanceof \Doctrine\DBAL\Driver\Exception && method_exists($t, 'getSQLState')) {
                $sqlState = $t->getSQLState();
            }
            if ($sqlState === null && preg_match('/SQLSTATE\[([A-Z0-9]{5})\]/', $t->getMessage(), $m)) {
                $sqlState = $m[1];
            }
        }

        $text = $e->getMessage();
        $pos = strripos($text, 'ERROR:');
        if ($pos !== false) {
            $text = substr($text, $pos + 6);
        }
        $text = preg_replace('/\s+/', ' ', trim($text)) ?? $text;
        $text = trim(preg_replace('/\s*(DETAIL|HINT|CONTEXT):.*$/i', '', $text)) ?? $text;
        $text = preg_replace('/^\d+\s+/', '', $text) ?? $text;

        $prefix = is_string($sqlState) && str_starts_with($sqlState, 'SA') ? '['.$sqlState.'] ' : '';

        return $prefix !== '' || $text !== ''
            ? $prefix.($text !== '' ? $text : 'La regla académica rechazó la operación.')
            : 'No fue posible completar la operación.';
    }
}
