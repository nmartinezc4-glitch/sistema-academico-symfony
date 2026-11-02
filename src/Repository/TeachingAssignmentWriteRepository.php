<?php

namespace App\Repository;

use App\Service\SecurityAuditLogger;
use Doctrine\DBAL\Connection;

final class TeachingAssignmentWriteRepository
{
    public function __construct(
        private readonly Connection $connection,
        private readonly SecurityAuditLogger $audit,
    ) {
    }

    public function assign(int $userId, int $offeringId): void
    {
        $teacher = (bool) $this->connection->fetchOne(
            <<<'SQL'
            SELECT 1
            FROM sis_seg_usuario u
            JOIN sis_seg_usuario_rol ur ON ur.usr_usu_id = u.usu_id
            JOIN sis_seg_rol r ON r.rol_id = ur.usr_rol_id
            WHERE u.usu_id = :id AND u.usu_activo AND r.rol_codigo = 'ROLE_DOCENTE' AND r.rol_activo
            LIMIT 1
            SQL,
            ['id' => $userId],
        );
        if (!$teacher) {
            throw new \RuntimeException('El usuario seleccionado no tiene un rol Docente activo.');
        }

        $offering = (bool) $this->connection->fetchOne(
            'SELECT 1 FROM sis_aca_oferta_curso WHERE ofe_id = :id AND ofe_activo LIMIT 1',
            ['id' => $offeringId],
        );
        if (!$offering) {
            throw new \RuntimeException('La oferta seleccionada no existe o está inactiva.');
        }

        $this->connection->executeStatement(
            <<<'SQL'
            INSERT INTO sis_aca_docente_oferta (dof_usu_id, dof_ofe_id, dof_activo)
            VALUES (:userId, :offeringId, TRUE)
            ON CONFLICT (dof_usu_id, dof_ofe_id)
            DO UPDATE SET dof_activo = TRUE, dof_actualizado_en = now()
            SQL,
            compact('userId', 'offeringId'),
        );

        $this->audit->log('DOCENTE_OFERTA_ASIGNADA', 'OFERTA', $offeringId, ['teacherUserId' => $userId]);
    }

    public function remove(int $userId, int $offeringId): void
    {
        $this->connection->update(
            'sis_aca_docente_oferta',
            ['dof_activo' => false, 'dof_actualizado_en' => (new \DateTimeImmutable())->format('Y-m-d H:i:sP')],
            ['dof_usu_id' => $userId, 'dof_ofe_id' => $offeringId],
        );

        $this->audit->log('DOCENTE_OFERTA_RETIRADA', 'OFERTA', $offeringId, ['teacherUserId' => $userId]);
    }
}
