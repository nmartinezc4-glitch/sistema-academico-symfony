<?php

namespace App\Security;

use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\UserInterface;

final class AcademicUser implements UserInterface, PasswordAuthenticatedUserInterface
{
    /**
     * @param list<string> $roles
     */
    public function __construct(
        private readonly int $id,
        private readonly string $email,
        private readonly string $passwordHash,
        private readonly string $firstNames,
        private readonly string $lastNames,
        private readonly ?string $photoPath,
        private readonly array $roles,
        private readonly bool $active,
    ) {
    }

    public function getId(): int
    {
        return $this->id;
    }

    public function getUserIdentifier(): string
    {
        return mb_strtolower($this->email);
    }

    public function getPassword(): string
    {
        return $this->passwordHash;
    }

    /** @return list<string> */
    public function getRoles(): array
    {
        return array_values(array_unique([...$this->roles, 'ROLE_USER']));
    }

    public function eraseCredentials(): void
    {
    }

    public function isActive(): bool
    {
        return $this->active;
    }

    public function getDisplayName(): string
    {
        return trim($this->firstNames.' '.$this->lastNames);
    }

    public function getPhotoPath(): ?string
    {
        return $this->photoPath;
    }

    public function getInitials(): string
    {
        $first = trim($this->firstNames);
        $last = trim($this->lastNames);
        $a = $first !== '' ? mb_substr($first, 0, 1) : '';
        $b = $last !== '' ? mb_substr($last, 0, 1) : '';

        return mb_strtoupper($a.$b);
    }

    public function getPrimaryRoleLabel(): string
    {
        $labels = [
            'ROLE_DIRECCION' => 'Dirección académica',
            'ROLE_COORDINACION' => 'Coordinación académica',
            'ROLE_DOCENTE' => 'Docente',
            'ROLE_GESTION_USUARIOS' => 'Gestión de usuarios',
        ];

        foreach (array_keys($labels) as $role) {
            if (in_array($role, $this->roles, true)) {
                return $labels[$role];
            }
        }

        return 'Usuario institucional';
    }
}
