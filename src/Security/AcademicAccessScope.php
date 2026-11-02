<?php

namespace App\Security;

use App\Repository\TeachingAssignmentReadRepository;
use Symfony\Bundle\SecurityBundle\Security;

final class AcademicAccessScope
{
    public function __construct(
        private readonly Security $security,
        private readonly TeachingAssignmentReadRepository $assignments,
    ) {
    }

    public function isScopedTeacher(): bool
    {
        return $this->security->isGranted('ROLE_DOCENTE')
            && !$this->security->isGranted('ROLE_COORDINACION')
            && !$this->security->isGranted('ROLE_DIRECCION');
    }

    /**
     * null = acceso institucional sin restricción nominal.
     * []   = docente autenticado sin estudiantes asignados.
     *
     * @return list<int>|null
     */
    public function studentIds(): ?array
    {
        if (!$this->isScopedTeacher()) {
            return null;
        }

        $user = $this->security->getUser();
        if (!$user instanceof AcademicUser) {
            return [];
        }

        return $this->assignments->studentIdsForUser($user->getId());
    }

    public function canViewStudent(int $studentId): bool
    {
        $ids = $this->studentIds();

        return $ids === null || in_array($studentId, $ids, true);
    }
}
