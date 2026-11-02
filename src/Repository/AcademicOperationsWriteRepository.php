<?php

namespace App\Repository;

use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception as DbalException;
use Doctrine\DBAL\Types\Types;

final class AcademicOperationsWriteRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    public function createOffering(int $periodId, int $curriculumCourseId, int $sectionId): int
    {
        try {
            $period = $this->connection->fetchAssociative(
                'SELECT per_estado FROM sis_aca_periodo_academico WHERE per_id = :id',
                ['id' => $periodId],
            );
            if ($period === false) {
                throw new \RuntimeException('El período académico no existe.');
            }
            if ($period['per_estado'] === 'CERRADO') {
                throw new \RuntimeException('No se pueden crear ofertas en un período CERRADO.');
            }

            $course = $this->connection->fetchAssociative(
                <<<'SQL'
                SELECT pcu.pcu_id
                FROM sis_aca_pensum_curso pcu
                JOIN sis_aca_pensum p ON p.pen_id = pcu.pcu_pen_id
                JOIN sis_aca_curso c ON c.cur_id = pcu.pcu_cur_id
                WHERE pcu.pcu_id = :id
                  AND p.pen_activo
                  AND c.cur_activo
                SQL,
                ['id' => $curriculumCourseId],
            );
            if ($course === false) {
                throw new \RuntimeException('El curso del pensum no existe o no está disponible para oferta.');
            }

            $section = (bool) $this->connection->fetchOne(
                'SELECT 1 FROM sis_aca_seccion WHERE sec_id = :id AND sec_activo LIMIT 1',
                ['id' => $sectionId],
            );
            if (!$section) {
                throw new \RuntimeException('La sección no existe o está inactiva.');
            }

            return (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_oferta_curso (
                    ofe_per_id,
                    ofe_pcu_id,
                    ofe_sec_id,
                    ofe_activo
                ) VALUES (
                    :periodId,
                    :curriculumCourseId,
                    :sectionId,
                    :active
                )
                RETURNING ofe_id
                SQL,
                [
                    'periodId' => $periodId,
                    'curriculumCourseId' => $curriculumCourseId,
                    'sectionId' => $sectionId,
                    'active' => true,
                ],
                [
                    'active' => Types::BOOLEAN,
                ],
            );
        } catch (DbalException $e) {
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        }
    }

    public function createEnrollment(
        int $studentId,
        int $periodId,
        int $cycleId,
        int $sectionId,
    ): int {
        try {
            $program = $this->connection->fetchAssociative(
                <<<'SQL'
                SELECT epr_id, epr_pen_id
                FROM sis_aca_estudiante_programa
                WHERE epr_est_id = :studentId
                  AND epr_estado = 'ACTIVO'
                ORDER BY epr_fecha_inicio DESC, epr_id DESC
                LIMIT 1
                SQL,
                ['studentId' => $studentId],
            );
            if ($program === false) {
                throw new \RuntimeException('El estudiante no tiene un programa ACTIVO para inscribir.');
            }

            $period = $this->connection->fetchAssociative(
                'SELECT per_estado FROM sis_aca_periodo_academico WHERE per_id = :id',
                ['id' => $periodId],
            );
            if ($period === false) {
                throw new \RuntimeException('El período académico no existe.');
            }
            if ($period['per_estado'] === 'CERRADO') {
                throw new \RuntimeException('No se puede inscribir un estudiante en un período CERRADO.');
            }

            $cycleBelongs = (bool) $this->connection->fetchOne(
                <<<'SQL'
                SELECT 1
                FROM sis_aca_pensum_curso
                WHERE pcu_pen_id = :curriculumId
                  AND pcu_cic_id = :cycleId
                LIMIT 1
                SQL,
                [
                    'curriculumId' => (int) $program['epr_pen_id'],
                    'cycleId' => $cycleId,
                ],
            );
            if (!$cycleBelongs) {
                throw new \RuntimeException('El ciclo seleccionado no forma parte del pensum del estudiante.');
            }

            $section = (bool) $this->connection->fetchOne(
                'SELECT 1 FROM sis_aca_seccion WHERE sec_id = :id AND sec_activo LIMIT 1',
                ['id' => $sectionId],
            );
            if (!$section) {
                throw new \RuntimeException('La sección no existe o está inactiva.');
            }

            return (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_estudiante_periodo (
                    epe_epr_id,
                    epe_per_id,
                    epe_cic_id,
                    epe_sec_id,
                    epe_estado
                ) VALUES (
                    :programId,
                    :periodId,
                    :cycleId,
                    :sectionId,
                    'INSCRITO'
                )
                RETURNING epe_id
                SQL,
                [
                    'programId' => (int) $program['epr_id'],
                    'periodId' => $periodId,
                    'cycleId' => $cycleId,
                    'sectionId' => $sectionId,
                ],
            );
        } catch (DbalException $e) {
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        }
    }

    private function domainMessage(\Throwable $e): string
    {
        $message = strtolower($e->getMessage());

        if (str_contains($message, 'uq_ofe_per_pcu_sec')) {
            return 'Esa oferta ya existe para el período, curso y sección seleccionados.';
        }
        if (str_contains($message, 'uq_epe_epr_per')) {
            return 'El estudiante ya tiene una inscripción registrada en ese período.';
        }

        return 'No fue posible completar la operación académica. Verifica la combinación seleccionada.';
    }
}
