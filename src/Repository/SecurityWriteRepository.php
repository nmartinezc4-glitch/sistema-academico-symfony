<?php

namespace App\Repository;

use App\Security\AcademicUser;
use App\Service\SecurityAuditLogger;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception as DbalException;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

final class SecurityWriteRepository
{
    public function __construct(
        private readonly Connection $connection,
        private readonly UserPasswordHasherInterface $hasher,
        private readonly SecurityAuditLogger $audit,
    ) {
    }

    /**
     * @param list<int> $roleIds
     */
    public function createUser(
        string $email,
        string $firstNames,
        string $lastNames,
        string $plainPassword,
        array $roleIds,
        ?string $photoPath = null,
    ): int {
        $email = mb_strtolower(trim($email));
        $firstNames = trim($firstNames);
        $lastNames = trim($lastNames);
        $this->validateIdentity($email, $firstNames, $lastNames, $plainPassword, $roleIds, true);

        $this->connection->beginTransaction();
        try {
            $roles = $this->roleCodes($roleIds);
            $prototype = new AcademicUser(0, $email, '', $firstNames, $lastNames, $photoPath, $roles, true);
            $hash = $this->hasher->hashPassword($prototype, $plainPassword);

            $id = (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_seg_usuario (
                    usu_correo, usu_password_hash, usu_nombres, usu_apellidos, usu_foto_ruta, usu_activo
                ) VALUES (
                    :email, :password, :firstNames, :lastNames, :photoPath, TRUE
                )
                RETURNING usu_id
                SQL,
                [
                    'email' => $email,
                    'password' => $hash,
                    'firstNames' => $firstNames,
                    'lastNames' => $lastNames,
                    'photoPath' => $photoPath,
                ],
            );

            $this->replaceRoles($id, $roleIds);
            $this->connection->commit();

            $this->audit->log('USUARIO_CREADO', 'USUARIO', $id, ['email' => $email, 'roles' => $roles]);

            return $id;
        } catch (DbalException $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    /**
     * @param list<int> $roleIds
     */
    public function updateUser(
        int $id,
        string $email,
        string $firstNames,
        string $lastNames,
        bool $active,
        array $roleIds,
        ?string $newPassword,
        ?string $photoPath,
        ?int $actorUserId,
    ): void {
        $email = mb_strtolower(trim($email));
        $firstNames = trim($firstNames);
        $lastNames = trim($lastNames);
        $this->validateIdentity($email, $firstNames, $lastNames, $newPassword ?? '', $roleIds, false);

        if ($actorUserId === $id && !$active) {
            throw new \RuntimeException('No puedes desactivar tu propia cuenta mientras administras usuarios.');
        }

        $this->connection->beginTransaction();
        try {
            $current = $this->connection->fetchAssociative(
                'SELECT usu_id, usu_password_hash FROM sis_seg_usuario WHERE usu_id = :id FOR UPDATE',
                ['id' => $id],
            );
            if ($current === false) {
                throw new \RuntimeException('El usuario no existe.');
            }

            $newRoleCodes = $this->roleCodes($roleIds);
            $removesUserManagers = !in_array('ROLE_GESTION_USUARIOS', $newRoleCodes, true) || !$active;
            if ($removesUserManagers && $this->hasRole($id, 'ROLE_GESTION_USUARIOS')) {
                $others = (int) $this->connection->fetchOne(
                    <<<'SQL'
                    SELECT COUNT(DISTINCT u.usu_id)
                    FROM sis_seg_usuario u
                    JOIN sis_seg_usuario_rol ur ON ur.usr_usu_id = u.usu_id
                    JOIN sis_seg_rol r ON r.rol_id = ur.usr_rol_id
                    WHERE u.usu_activo
                      AND r.rol_codigo = 'ROLE_GESTION_USUARIOS'
                      AND u.usu_id <> :id
                    SQL,
                    ['id' => $id],
                );
                if ($others === 0) {
                    throw new \RuntimeException('Debe permanecer al menos un usuario activo con el rol Gestión de usuarios.');
                }
            }

            $data = [
                'usu_correo' => $email,
                'usu_nombres' => $firstNames,
                'usu_apellidos' => $lastNames,
                'usu_activo' => $active,
                'usu_foto_ruta' => $photoPath,
                'usu_actualizado_en' => (new \DateTimeImmutable())->format('Y-m-d H:i:sP'),
            ];

            if ($newPassword !== null && trim($newPassword) !== '') {
                if (mb_strlen($newPassword) < 10) {
                    throw new \RuntimeException('La nueva contraseña debe tener al menos 10 caracteres.');
                }
                $prototype = new AcademicUser($id, $email, (string) $current['usu_password_hash'], $firstNames, $lastNames, $photoPath, $newRoleCodes, $active);
                $data['usu_password_hash'] = $this->hasher->hashPassword($prototype, $newPassword);
            }

            $this->connection->update('sis_seg_usuario', $data, ['usu_id' => $id]);
            $this->replaceRoles($id, $roleIds);
            $this->connection->commit();

            $this->audit->log('USUARIO_ACTUALIZADO', 'USUARIO', $id, [
                'email' => $email,
                'active' => $active,
                'roles' => $newRoleCodes,
                'passwordChanged' => $newPassword !== null && trim($newPassword) !== '',
                'photoPath' => $photoPath,
            ]);
        } catch (DbalException $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    /** @param list<int> $roleIds */
    private function validateIdentity(
        string $email,
        string $firstNames,
        string $lastNames,
        string $password,
        array $roleIds,
        bool $passwordRequired,
    ): void {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new \RuntimeException('Ingresa un correo institucional válido.');
        }
        if ($firstNames === '' || $lastNames === '') {
            throw new \RuntimeException('Nombres y apellidos son obligatorios.');
        }
        if ($passwordRequired && mb_strlen($password) < 10) {
            throw new \RuntimeException('La contraseña inicial debe tener al menos 10 caracteres.');
        }
        if ($roleIds === []) {
            throw new \RuntimeException('Selecciona al menos un rol funcional.');
        }
    }

    /** @param list<int> $roleIds @return list<string> */
    private function roleCodes(array $roleIds): array
    {
        $roleIds = array_values(array_unique(array_map('intval', $roleIds)));
        $rows = $this->connection->fetchAllAssociative(
            'SELECT rol_id AS id, rol_codigo AS code FROM sis_seg_rol WHERE rol_activo AND rol_id IN (?)',
            [$roleIds],
            [ArrayParameterType::INTEGER],
        );

        if (count($rows) !== count($roleIds)) {
            throw new \RuntimeException('Uno o más roles seleccionados no existen o están inactivos.');
        }

        return array_values(array_map(static fn (array $row): string => (string) $row['code'], $rows));
    }

    /** @param list<int> $roleIds */
    private function replaceRoles(int $userId, array $roleIds): void
    {
        $this->connection->executeStatement('DELETE FROM sis_seg_usuario_rol WHERE usr_usu_id = :id', ['id' => $userId]);
        foreach (array_values(array_unique(array_map('intval', $roleIds))) as $roleId) {
            $this->connection->insert('sis_seg_usuario_rol', [
                'usr_usu_id' => $userId,
                'usr_rol_id' => $roleId,
            ]);
        }
    }

    private function hasRole(int $userId, string $role): bool
    {
        return (bool) $this->connection->fetchOne(
            <<<'SQL'
            SELECT 1
            FROM sis_seg_usuario_rol ur
            JOIN sis_seg_rol r ON r.rol_id = ur.usr_rol_id
            WHERE ur.usr_usu_id = :id AND r.rol_codigo = :role
            LIMIT 1
            SQL,
            ['id' => $userId, 'role' => $role],
        );
    }

    private function domainMessage(\Throwable $e): string
    {
        $message = strtolower($e->getMessage());
        if (str_contains($message, 'ux_usu_correo_lower')) {
            return 'Ya existe un usuario con ese correo institucional.';
        }

        return 'No fue posible guardar el usuario. Verifica los datos e intenta nuevamente.';
    }
}
