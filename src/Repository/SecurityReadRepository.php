<?php

namespace App\Repository;

use Doctrine\DBAL\Connection;

final class SecurityReadRepository
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @return list<array{id:int,code:string,name:string,description:?string}> */
    public function roles(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT rol_id AS id, rol_codigo AS code, rol_nombre AS name, rol_descripcion AS description
            FROM sis_seg_rol
            WHERE rol_activo
            ORDER BY rol_nombre
            SQL
        );

        return array_map(static fn (array $row): array => [
            'id' => (int) $row['id'],
            'code' => (string) $row['code'],
            'name' => (string) $row['name'],
            'description' => $row['description'] !== null ? (string) $row['description'] : null,
        ], $rows);
    }

    /** @return list<array<string,mixed>> */
    public function users(): array
    {
        $rows = $this->connection->fetchAllAssociative(
            <<<'SQL'
            SELECT
                u.usu_id AS id,
                u.usu_correo AS email,
                u.usu_nombres AS "firstNames",
                u.usu_apellidos AS "lastNames",
                u.usu_foto_ruta AS "photoPath",
                u.usu_activo AS active,
                u.usu_ultimo_acceso_en AS "lastLogin",
                COALESCE(string_agg(r.rol_codigo, ',' ORDER BY r.rol_codigo) FILTER (WHERE r.rol_codigo IS NOT NULL), '') AS roles
            FROM sis_seg_usuario u
            LEFT JOIN sis_seg_usuario_rol ur ON ur.usr_usu_id = u.usu_id
            LEFT JOIN sis_seg_rol r ON r.rol_id = ur.usr_rol_id
            GROUP BY u.usu_id
            ORDER BY u.usu_activo DESC, u.usu_apellidos, u.usu_nombres
            SQL
        );

        foreach ($rows as &$row) {
            $row['id'] = (int) $row['id'];
            $row['active'] = (bool) $row['active'];
            $row['fullName'] = trim($row['firstNames'].' '.$row['lastNames']);
            $row['photoPath'] = $row['photoPath'] !== null ? (string) $row['photoPath'] : null;
            $row['initials'] = mb_strtoupper(
                mb_substr((string) $row['firstNames'], 0, 1)
                .mb_substr((string) $row['lastNames'], 0, 1)
            );
            $row['roles'] = $row['roles'] === '' ? [] : explode(',', (string) $row['roles']);
        }

        return $rows;
    }

    public function findUser(int $id): ?array
    {
        foreach ($this->users() as $user) {
            if ($user['id'] === $id) {
                return $user;
            }
        }

        return null;
    }
}
