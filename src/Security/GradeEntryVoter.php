<?php

namespace App\Security;

use App\Repository\TeachingAssignmentReadRepository;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Authorization\Voter\Vote;
use Symfony\Component\Security\Core\Authorization\Voter\Voter;
use Symfony\Component\Security\Core\User\UserInterface;

final class GradeEntryVoter extends Voter
{
    public const EDIT = 'GRADE_EDIT';

    public function __construct(private readonly TeachingAssignmentReadRepository $assignments)
    {
    }

    protected function supports(string $attribute, mixed $subject): bool
    {
        return $attribute === self::EDIT && is_int($subject);
    }

    protected function voteOnAttribute(string $attribute, mixed $subject, TokenInterface $token, ?Vote $vote = null): bool
    {
        $user = $token->getUser();
        if (!$user instanceof AcademicUser) {
            return false;
        }

        if (in_array('ROLE_COORDINACION', $user->getRoles(), true)) {
            return true;
        }

        if (!in_array('ROLE_DOCENTE', $user->getRoles(), true)) {
            return false;
        }

        return $this->assignments->canEditOffering($user->getId(), $subject);
    }
}
