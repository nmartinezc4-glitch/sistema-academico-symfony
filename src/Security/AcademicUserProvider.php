<?php

namespace App\Security;

use Doctrine\DBAL\Connection;
use Symfony\Component\Security\Core\Exception\UnsupportedUserException;
use Symfony\Component\Security\Core\Exception\UserNotFoundException;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\PasswordUpgraderInterface;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Security\Core\User\UserProviderInterface;

final class AcademicUserProvider implements UserProviderInterface, PasswordUpgraderInterface
{
    public function __construct(private readonly Connection $connection)
    {
    }

    public function loadUserByIdentifier(string $identifier): UserInterface
    {
        $row = $this->connection->fetchAssociative(
            <<<'SQL'
            SELECT
                usu_id AS id,
                usu_correo AS email,
                usu_password_hash AS password,
                usu_nombres AS "firstNames",
                usu_apellidos AS "lastNames",
                usu_foto_ruta AS "photoPath",
                usu_activo AS active
            FROM sis_seg_usuario
            WHERE lower(usu_correo) = lower(:identifier)
            LIMIT 1
            SQL,
            ['identifier' => trim($identifier)],
        );

        if ($row === false || !(bool) $row['active']) {
            $exception = new UserNotFoundException();
            $exception->setUserIdentifier($identifier);

            throw $exception;
        }

        $roles = $this->connection->fetchFirstColumn(
            <<<'SQL'
            SELECT r.rol_codigo
            FROM sis_seg_usuario_rol ur
            JOIN sis_seg_rol r ON r.rol_id = ur.usr_rol_id
            WHERE ur.usr_usu_id = :id
              AND r.rol_activo
            ORDER BY r.rol_codigo
            SQL,
            ['id' => (int) $row['id']],
        );

        return new AcademicUser(
            id: (int) $row['id'],
            email: (string) $row['email'],
            passwordHash: (string) $row['password'],
            firstNames: (string) $row['firstNames'],
            lastNames: (string) $row['lastNames'],
            photoPath: $row['photoPath'] !== null ? (string) $row['photoPath'] : null,
            roles: array_map('strval', $roles),
            active: true,
        );
    }

    public function refreshUser(UserInterface $user): UserInterface
    {
        if (!$user instanceof AcademicUser) {
            throw new UnsupportedUserException(sprintf('Clase de usuario no soportada: %s.', $user::class));
        }

        return $this->loadUserByIdentifier($user->getUserIdentifier());
    }

    public function supportsClass(string $class): bool
    {
        return AcademicUser::class === $class || is_subclass_of($class, AcademicUser::class);
    }

    public function upgradePassword(PasswordAuthenticatedUserInterface $user, string $newHashedPassword): void
    {
        if (!$user instanceof AcademicUser) {
            throw new UnsupportedUserException(sprintf('Clase de usuario no soportada: %s.', $user::class));
        }

        $this->connection->update(
            'sis_seg_usuario',
            [
                'usu_password_hash' => $newHashedPassword,
                'usu_actualizado_en' => (new \DateTimeImmutable())->format('Y-m-d H:i:sP'),
            ],
            ['usu_id' => $user->getId()],
        );
    }
}
