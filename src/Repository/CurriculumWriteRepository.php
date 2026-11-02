<?php

namespace App\Repository;

use App\Service\InstitutionalCodeGenerator;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception as DbalException;
use Doctrine\DBAL\Types\Types;

final class CurriculumWriteRepository
{
    public function __construct(
        private readonly Connection $connection,
        private readonly InstitutionalCodeGenerator $codes,
    ) {
    }

    public function createPensum(
        int $careerId,
        string $name,
        string $validFrom,
        ?string $validUntil,
    ): int {
        $this->connection->beginTransaction();

        try {
            $career = $this->connection->fetchAssociative(
                'SELECT car_id, car_codigo, car_nombre FROM sis_aca_carrera WHERE car_id = :id AND car_activo FOR UPDATE',
                ['id' => $careerId],
            );
            if ($career === false) {
                throw new \RuntimeException('La carrera seleccionada no existe o está inactiva.');
            }

            $this->connection->fetchOne(
                'SELECT pg_advisory_xact_lock(hashtext(:key))',
                ['key' => 'sis_aca_pensum_version_'.$careerId],
            );

            $version = (int) $this->connection->fetchOne(
                'SELECT COALESCE(MAX(pen_version), 0) + 1 FROM sis_aca_pensum WHERE pen_car_id = :careerId',
                ['careerId' => $careerId],
            );
            $code = $this->codes->nextCurriculumCode((string) $career['car_codigo'], $validFrom, $version);

            $id = (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_pensum (
                    pen_car_id,
                    pen_codigo,
                    pen_nombre,
                    pen_version,
                    pen_vigente_desde,
                    pen_vigente_hasta,
                    pen_activo
                ) VALUES (
                    :careerId,
                    :code,
                    :name,
                    :version,
                    :validFrom,
                    :validUntil,
                    FALSE
                )
                RETURNING pen_id
                SQL,
                [
                    'careerId' => $careerId,
                    'code' => $code,
                    'name' => trim($name),
                    'version' => $version,
                    'validFrom' => $validFrom,
                    'validUntil' => $validUntil,
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

    public function addCourse(
        int $pensumId,
        int $courseId,
        int $cycleId,
        bool $required = true,
    ): int {
        $this->connection->beginTransaction();

        try {
            $pensum = $this->connection->fetchAssociative(
                'SELECT pen_id, pen_nombre FROM sis_aca_pensum WHERE pen_id = :id FOR UPDATE',
                ['id' => $pensumId],
            );
            if ($pensum === false) {
                throw new \RuntimeException('El pensum no existe.');
            }

            $this->assertStructureEditable($pensumId);

            $courseExists = (bool) $this->connection->fetchOne(
                'SELECT 1 FROM sis_aca_curso WHERE cur_id = :id AND cur_activo LIMIT 1',
                ['id' => $courseId],
            );
            if (!$courseExists) {
                throw new \RuntimeException('El curso seleccionado no existe o está inactivo.');
            }

            $cycleExists = (bool) $this->connection->fetchOne(
                'SELECT 1 FROM sis_aca_ciclo_curricular WHERE cic_id = :id AND cic_activo LIMIT 1',
                ['id' => $cycleId],
            );
            if (!$cycleExists) {
                throw new \RuntimeException('El ciclo curricular seleccionado no existe o está inactivo.');
            }

            $alreadyAssigned = (bool) $this->connection->fetchOne(
                'SELECT 1 FROM sis_aca_pensum_curso WHERE pcu_pen_id = :pensumId AND pcu_cur_id = :courseId LIMIT 1',
                ['pensumId' => $pensumId, 'courseId' => $courseId],
            );
            if ($alreadyAssigned) {
                throw new \RuntimeException('Ese curso ya forma parte del pensum.');
            }

            $order = (int) $this->connection->fetchOne(
                'SELECT COALESCE(MAX(pcu_orden), 0) + 1 FROM sis_aca_pensum_curso WHERE pcu_pen_id = :pensumId AND pcu_cic_id = :cycleId',
                ['pensumId' => $pensumId, 'cycleId' => $cycleId],
            );

            $id = (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_pensum_curso (
                    pcu_pen_id,
                    pcu_cur_id,
                    pcu_cic_id,
                    pcu_obligatorio,
                    pcu_orden
                ) VALUES (
                    :pensumId,
                    :courseId,
                    :cycleId,
                    :required,
                    :order
                )
                RETURNING pcu_id
                SQL,
                [
                    'pensumId' => $pensumId,
                    'courseId' => $courseId,
                    'cycleId' => $cycleId,
                    'required' => $required,
                    'order' => $order,
                ],
                [
                    'required' => Types::BOOLEAN,
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

    public function activate(int $pensumId): void
    {
        $this->connection->beginTransaction();

        try {
            $pensum = $this->connection->fetchAssociative(
                'SELECT pen_id, pen_activo FROM sis_aca_pensum WHERE pen_id = :id FOR UPDATE',
                ['id' => $pensumId],
            );
            if ($pensum === false) {
                throw new \RuntimeException('El pensum no existe.');
            }
            if ((bool) $pensum['pen_activo']) {
                $this->connection->commit();

                return;
            }

            $missingCycles = $this->connection->fetchFirstColumn(
                <<<'SQL'
                SELECT c.cic_nombre
                FROM sis_aca_ciclo_curricular c
                WHERE c.cic_activo
                  AND NOT EXISTS (
                      SELECT 1
                      FROM sis_aca_pensum_curso pcu
                      WHERE pcu.pcu_pen_id = :id
                        AND pcu.pcu_cic_id = c.cic_id
                        AND pcu.pcu_obligatorio
                  )
                ORDER BY c.cic_anio, c.cic_semestre
                SQL,
                ['id' => $pensumId],
            );
            if ($missingCycles !== []) {
                throw new \RuntimeException(
                    'El pensum no puede activarse: falta al menos un curso obligatorio en '.implode(', ', $missingCycles).'.',
                );
            }

            $this->connection->executeStatement(
                'UPDATE sis_aca_pensum SET pen_activo = TRUE WHERE pen_id = :id',
                ['id' => $pensumId],
            );

            $this->connection->commit();
        } catch (DbalException $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    private function assertStructureEditable(int $pensumId): void
    {
        $assignedPrograms = (int) $this->connection->fetchOne(
            'SELECT COUNT(*) FROM sis_aca_estudiante_programa WHERE epr_pen_id = :id',
            ['id' => $pensumId],
        );

        if ($assignedPrograms > 0) {
            throw new \RuntimeException(
                'La estructura de este pensum está protegida porque ya fue asignado a estudiantes. Crea una nueva versión para cambiar sus cursos.',
            );
        }
    }

    private function domainMessage(\Throwable $e): string
    {
        $message = $e->getMessage();

        if (str_contains($message, 'uq_pen_codigo')) {
            return 'Ya existe un pensum con ese código.';
        }
        if (str_contains($message, 'uq_pen_car_version')) {
            return 'No fue posible reservar la siguiente versión de la carrera. Intenta nuevamente.';
        }
        if (str_contains($message, 'uq_pcu_pen_cur')) {
            return 'Ese curso ya forma parte del pensum.';
        }
        if (str_contains($message, 'uq_pcu_pen_cic_orden')) {
            return 'No fue posible asignar el orden del curso dentro del ciclo. Intenta nuevamente.';
        }
        if (str_contains($message, 'ck_pen_vigencia')) {
            return 'La vigencia del pensum no es válida.';
        }

        $text = preg_replace('/\s+/', ' ', trim($message)) ?? $message;

        return 'No fue posible completar la operación. '.$text;
    }
}
