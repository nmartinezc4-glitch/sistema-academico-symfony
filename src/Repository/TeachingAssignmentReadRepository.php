<?php

namespace App\Repository;

use Doctrine\DBAL\Connection;

final class TeachingAssignmentReadRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @return list<array{id:int,name:string,email:string}> */
    public function teachers(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT DISTINCT u.usu_id AS id,
                   trim(u.usu_nombres || ' ' || u.usu_apellidos) AS name,
                   u.usu_correo AS email
            FROM sis_seg_usuario u
            JOIN sis_seg_usuario_rol ur ON ur.usr_usu_id = u.usu_id
            JOIN sis_seg_rol r ON r.rol_id = ur.usr_rol_id
            WHERE u.usu_activo
              AND r.rol_activo
              AND r.rol_codigo = 'ROLE_DOCENTE'
            ORDER BY name
            SQL
        );
        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
        }

        return $rows;
    }

    /** @return list<array<string,mixed>> */
    public function offerings(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT o.ofe_id AS id,
                   a.anl_anio || '-' || CASE p.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS period,
                   c.cur_codigo AS "courseCode",
                   c.cur_nombre AS course,
                   s.sec_codigo AS section,
                   pen.pen_codigo AS curriculum
            FROM sis_aca_oferta_curso o
            JOIN sis_aca_periodo_academico p ON p.per_id = o.ofe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = p.per_anl_id
            JOIN sis_aca_pensum_curso pc ON pc.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_curso c ON c.cur_id = pc.pcu_cur_id
            JOIN sis_aca_pensum pen ON pen.pen_id = pc.pcu_pen_id
            JOIN sis_aca_seccion s ON s.sec_id = o.ofe_sec_id
            WHERE o.ofe_activo
              AND p.per_estado IN ('PLANIFICADO', 'ABIERTO')
            ORDER BY a.anl_anio DESC, p.per_numero DESC, c.cur_codigo, s.sec_codigo
            SQL
        );
        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
        }

        return $rows;
    }

    /** @return list<array<string,mixed>> */
    public function assignments(): array
    {
        return $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT d.dof_usu_id AS "userId",
                   d.dof_ofe_id AS "offeringId",
                   trim(u.usu_nombres || ' ' || u.usu_apellidos) AS teacher,
                   u.usu_correo AS email,
                   a.anl_anio || '-' || CASE p.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS period,
                   c.cur_codigo AS "courseCode",
                   c.cur_nombre AS course,
                   s.sec_codigo AS section,
                   d.dof_activo AS active
            FROM sis_aca_docente_oferta d
            JOIN sis_seg_usuario u ON u.usu_id = d.dof_usu_id
            JOIN sis_aca_oferta_curso o ON o.ofe_id = d.dof_ofe_id
            JOIN sis_aca_periodo_academico p ON p.per_id = o.ofe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = p.per_anl_id
            JOIN sis_aca_pensum_curso pc ON pc.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_curso c ON c.cur_id = pc.pcu_cur_id
            JOIN sis_aca_seccion s ON s.sec_id = o.ofe_sec_id
            ORDER BY d.dof_activo DESC, period DESC, teacher, c.cur_codigo
            SQL
        );
    }

    /** @return list<int> */
    public function offeringIdsForUser(int $userId): array
    {
        return array_map('intval', $this->connection->fetchFirstColumn(
            'SELECT dof_ofe_id FROM sis_aca_docente_oferta WHERE dof_usu_id = :id AND dof_activo',
            ['id' => $userId],
        ));
    }

    public function canGradeStudent(int $userId, int $studentId): bool
    {
        return (bool) $this->connection->fetchOne(
            <<<'SQL'
            SELECT 1
            FROM sis_aca_docente_oferta d
            JOIN sis_aca_oferta_curso o
              ON o.ofe_id = d.dof_ofe_id
             AND o.ofe_activo
            JOIN sis_aca_pensum_curso pc
              ON pc.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_estudiante_periodo ep
              ON ep.epe_per_id = o.ofe_per_id
             AND ep.epe_sec_id = o.ofe_sec_id
             AND ep.epe_estado = 'INSCRITO'
            JOIN sis_aca_estudiante_programa pr
              ON pr.epr_id = ep.epe_epr_id
             AND pr.epr_pen_id = pc.pcu_pen_id
            WHERE d.dof_usu_id = :userId
              AND d.dof_activo
              AND pr.epr_est_id = :studentId
            LIMIT 1
            SQL,
            ['userId' => $userId, 'studentId' => $studentId],
        );
    }


    public function studentIdFromCodeForUser(int $userId, string $code): ?int
    {
        $id = $this->connection->fetchOne(
            <<<'SQL'
            SELECT DISTINCT e.est_id
            FROM sis_aca_docente_oferta d
            JOIN sis_aca_oferta_curso o
              ON o.ofe_id = d.dof_ofe_id
             AND o.ofe_activo
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
              AND e.est_codigo = :code
            LIMIT 1
            SQL,
            ['userId' => $userId, 'code' => trim($code)],
        );

        return $id === false ? null : (int) $id;
    }

    /** @return list<int> */
    public function studentIdsForUser(int $userId): array
    {
        return array_map('intval', $this->connection->fetchFirstColumn(
            <<<'SQL'
            SELECT DISTINCT e.est_id
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
            WHERE d.dof_usu_id = :id
              AND d.dof_activo
            ORDER BY e.est_id
            SQL,
            ['id' => $userId],
        ));
    }

    /** @return list<int> */
    public function enrollmentIdsForUser(int $userId, int $studentId): array
    {
        return array_map('intval', $this->connection->fetchFirstColumn(
            <<<'SQL'
            SELECT DISTINCT ep.epe_id
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
            WHERE d.dof_usu_id = :userId
              AND d.dof_activo
              AND pr.epr_est_id = :studentId
            ORDER BY ep.epe_id DESC
            SQL,
            ['userId' => $userId, 'studentId' => $studentId],
        ));
    }

    /** @return list<array<string,mixed>> */
    public function assignedOfferingsForUser(int $userId): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                o.ofe_id AS id,
                a.anl_anio || '-' || CASE p.per_numero WHEN 1 THEN 'I' ELSE 'II' END AS period,
                p.per_estado AS "periodStatus",
                c.cur_codigo AS "courseCode",
                c.cur_nombre AS course,
                s.sec_codigo AS section,
                pen.pen_codigo AS curriculum,
                COUNT(DISTINCT e.est_id)::int AS "studentsCount"
            FROM sis_aca_docente_oferta d
            JOIN sis_aca_oferta_curso o ON o.ofe_id = d.dof_ofe_id AND o.ofe_activo
            JOIN sis_aca_periodo_academico p ON p.per_id = o.ofe_per_id
            JOIN sis_aca_anio_lectivo a ON a.anl_id = p.per_anl_id
            JOIN sis_aca_pensum_curso pc ON pc.pcu_id = o.ofe_pcu_id
            JOIN sis_aca_curso c ON c.cur_id = pc.pcu_cur_id
            JOIN sis_aca_pensum pen ON pen.pen_id = pc.pcu_pen_id
            JOIN sis_aca_seccion s ON s.sec_id = o.ofe_sec_id
            LEFT JOIN sis_aca_estudiante_periodo ep
              ON ep.epe_per_id = o.ofe_per_id
             AND ep.epe_sec_id = o.ofe_sec_id
             AND ep.epe_estado = 'INSCRITO'
            LEFT JOIN sis_aca_estudiante_programa pr
              ON pr.epr_id = ep.epe_epr_id
             AND pr.epr_pen_id = pc.pcu_pen_id
            LEFT JOIN sis_aca_estudiante e ON e.est_id = pr.epr_est_id
            WHERE d.dof_usu_id = :userId
              AND d.dof_activo
            GROUP BY o.ofe_id, a.anl_anio, p.per_numero, p.per_estado, c.cur_codigo, c.cur_nombre, s.sec_codigo, pen.pen_codigo
            ORDER BY (p.per_estado = 'ABIERTO') DESC, a.anl_anio DESC, p.per_numero DESC, c.cur_codigo, s.sec_codigo
            SQL,
            ['userId' => $userId],
        );

        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['studentsCount'] = (int) $row['studentsCount'];
        }

        return $rows;
    }

    public function canEditOffering(int $userId, int $offeringId): bool
    {
        return (bool) $this->connection->fetchOne(
            'SELECT 1 FROM sis_aca_docente_oferta WHERE dof_usu_id = :userId AND dof_ofe_id = :offeringId AND dof_activo LIMIT 1',
            ['userId' => $userId, 'offeringId' => $offeringId],
        );
    }
}
