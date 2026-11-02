<?php

namespace App\Service;

use App\Security\AcademicUser;
use Doctrine\DBAL\Connection;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpFoundation\RequestStack;

final class SecurityAuditLogger
{
    public function __construct(
        private readonly Connection $connection,
        private readonly Security $security,
        private readonly RequestStack $requestStack,
    ) {
    }

    /**
     * @param array<string,mixed> $detail
     */
    public function log(string $action, ?string $entity = null, string|int|null $entityId = null, array $detail = []): void
    {
        $user = $this->security->getUser();
        $request = $this->requestStack->getCurrentRequest();

        $this->connection->insert('sis_seg_auditoria', [
            'aud_usu_id' => $user instanceof AcademicUser ? $user->getId() : null,
            'aud_accion' => $action,
            'aud_entidad' => $entity,
            'aud_entidad_id' => $entityId !== null ? (string) $entityId : null,
            'aud_detalle' => json_encode($detail, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE),
            'aud_ip' => $request?->getClientIp(),
        ]);
    }
}
