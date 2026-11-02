<?php

namespace App\Repository;

use App\Service\InstitutionalCodeGenerator;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception as DbalException;

final class AcademicCalendarWriteRepository
{
    public function __construct(
        private readonly Connection $connection,
        private readonly InstitutionalCodeGenerator $codes,
    ) {
    }

    public function createYear(
        int $year,
        string $name,
        string $startDate,
        string $endDate,
    ): int {
        try {
            return (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_anio_lectivo (
                    anl_anio,
                    anl_nombre,
                    anl_fecha_inicio,
                    anl_fecha_fin,
                    anl_estado
                ) VALUES (
                    :year,
                    :name,
                    :startDate,
                    :endDate,
                    'PLANIFICADO'
                )
                RETURNING anl_id
                SQL,
                [
                    'year' => $year,
                    'name' => trim($name),
                    'startDate' => $startDate,
                    'endDate' => $endDate,
                ],
            );
        } catch (DbalException $e) {
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        }
    }

    public function createPeriod(
        int $yearId,
        int $number,
        string $startDate,
        string $endDate,
    ): int {
        $year = $this->connection->fetchAssociative(
            <<<'SQL'
            SELECT anl_fecha_inicio AS "startDate", anl_fecha_fin AS "endDate", anl_estado AS status
            FROM sis_aca_anio_lectivo
            WHERE anl_id = :id
            SQL,
            ['id' => $yearId],
        );

        if ($year === false) {
            throw new \RuntimeException('El año lectivo seleccionado no existe.');
        }
        if ($year['status'] === 'CERRADO') {
            throw new \RuntimeException('No se pueden agregar períodos a un año lectivo CERRADO.');
        }
        if ($startDate < $year['startDate'] || $endDate > $year['endDate']) {
            throw new \RuntimeException('Las fechas del período deben quedar dentro de las fechas del año lectivo.');
        }

        $name = match ($number) {
            1 => 'Semestre I',
            2 => 'Semestre II',
            default => throw new \RuntimeException('El semestre debe ser I o II.'),
        };

        try {
            // PER_POL_ID se omite intencionalmente: T3 asigna la política
            // vigente en PER_FECHA_INICIO antes de validar NOT NULL.
            return (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_periodo_academico (
                    per_anl_id,
                    per_numero,
                    per_nombre,
                    per_fecha_inicio,
                    per_fecha_fin,
                    per_estado
                ) VALUES (
                    :yearId,
                    :number,
                    :name,
                    :startDate,
                    :endDate,
                    'PLANIFICADO'
                )
                RETURNING per_id
                SQL,
                [
                    'yearId' => $yearId,
                    'number' => $number,
                    'name' => $name,
                    'startDate' => $startDate,
                    'endDate' => $endDate,
                ],
            );
        } catch (DbalException $e) {
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        }
    }

    public function transitionPeriod(int $periodId, string $target): void
    {
        if (!\in_array($target, ['ABIERTO', 'CERRADO'], true)) {
            throw new \RuntimeException('Estado de período no soportado.');
        }

        $this->connection->beginTransaction();

        try {
            $period = $this->connection->fetchAssociative(
                <<<'SQL'
                SELECT per_anl_id AS "yearId", per_estado AS status
                FROM sis_aca_periodo_academico
                WHERE per_id = :id
                FOR UPDATE
                SQL,
                ['id' => $periodId],
            );

            if ($period === false) {
                throw new \RuntimeException('El período académico no existe.');
            }

            $current = (string) $period['status'];
            $allowed = (($current === 'PLANIFICADO' || $current === 'CERRADO') && $target === 'ABIERTO')
                || ($current === 'ABIERTO' && $target === 'CERRADO');

            if (!$allowed) {
                throw new \RuntimeException(sprintf(
                    'Transición no permitida: %s → %s.',
                    $current,
                    $target,
                ));
            }

            if ($target === 'CERRADO') {
                $pending = (int) $this->connection->fetchOne(
                    <<<'SQL'
                    SELECT COUNT(*)
                    FROM sis_aca_vw_ingreso_notas
                    WHERE per_id = :id
                      AND epe_estado = 'INSCRITO'
                      AND ing_estado IN ('SIN_OFERTA', 'SIN_REGISTRO', 'PENDIENTE')
                    SQL,
                    ['id' => $periodId],
                );
                if ($pending > 0) {
                    throw new \RuntimeException(sprintf(
                        'El período no puede cerrarse: quedan %d curso%s sin resolución académica (sin oferta, sin registro o pendiente de nota).',
                        $pending,
                        $pending === 1 ? '' : 's',
                    ));
                }
            }

            $this->connection->update(
                'sis_aca_periodo_academico',
                ['per_estado' => $target],
                ['per_id' => $periodId],
            );

            if ($target === 'ABIERTO') {
                $this->connection->executeStatement(
                    "UPDATE sis_aca_anio_lectivo
                     SET anl_estado = 'ABIERTO'
                     WHERE anl_id = :id AND anl_estado <> 'ABIERTO'",
                    ['id' => (int) $period['yearId']],
                );
            }

            if ($target === 'CERRADO') {
                $stats = $this->connection->fetchAssociative(
                    <<<'SQL'
                    SELECT COUNT(*)::int AS total,
                           COUNT(*) FILTER (WHERE per_estado = 'CERRADO')::int AS closed
                    FROM sis_aca_periodo_academico
                    WHERE per_anl_id = :id
                    SQL,
                    ['id' => (int) $period['yearId']],
                ) ?: ['total' => 0, 'closed' => 0];

                if ((int) $stats['total'] >= 2 && (int) $stats['total'] === (int) $stats['closed']) {
                    $this->connection->update(
                        'sis_aca_anio_lectivo',
                        ['anl_estado' => 'CERRADO'],
                        ['anl_id' => (int) $period['yearId']],
                    );
                }
            }

            $this->connection->commit();
        } catch (DbalException $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    public function createPolicy(
        string $name,
        float $passingGrade,
        string $validFrom,
    ): int {
        $this->connection->beginTransaction();

        try {
            $code = $this->codes->nextPolicyCode($validFrom);
            $id = (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_politica_academica (
                    pol_codigo,
                    pol_nombre,
                    pol_nota_aprobacion,
                    pol_vigente_desde
                ) VALUES (
                    :code,
                    :name,
                    :passingGrade,
                    :validFrom
                )
                RETURNING pol_id
                SQL,
                [
                    'code' => $code,
                    'name' => trim($name),
                    'passingGrade' => $passingGrade,
                    'validFrom' => $validFrom,
                ],
            );
            $this->connection->commit();

            return $id;
        } catch (DbalException $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    private function domainMessage(\Throwable $e): string
    {
        $message = $e->getMessage();

        if (str_contains($message, 'UQ_ANL_ANIO') || str_contains(strtolower($message), 'uq_anl_anio')) {
            return 'Ya existe un año lectivo con ese año.';
        }
        if (str_contains(strtolower($message), 'uq_per_anl_numero')) {
            return 'Ese semestre ya existe dentro del año lectivo seleccionado.';
        }
        if (str_contains(strtolower($message), 'uq_pol_codigo')) {
            return 'Ya existe una política académica con ese código.';
        }
        if (str_contains(strtolower($message), 'uq_pol_vigente_desde')) {
            return 'Ya existe una política que inicia vigencia en esa fecha.';
        }
        if (str_contains($message, 'SA301')) {
            return 'No existe una política académica vigente para la fecha de inicio del período. Crea primero una política válida.';
        }
        if (str_contains($message, 'SA304')) {
            return 'La nueva política modificaría retroactivamente períodos ya registrados. Usa una fecha de vigencia posterior.';
        }

        return 'PostgreSQL rechazó la operación para proteger la integridad académica.';
    }
}
