<?php

namespace App\EventSubscriber;

use App\Security\AcademicUser;
use App\Service\SecurityAuditLogger;
use Doctrine\DBAL\Connection;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\Security\Http\Event\LoginSuccessEvent;

final class LoginAuditSubscriber implements EventSubscriberInterface
{
    public function __construct(
        private readonly Connection $connection,
        private readonly SecurityAuditLogger $audit,
    ) {
    }

    public static function getSubscribedEvents(): array
    {
        return [LoginSuccessEvent::class => 'onLoginSuccess'];
    }

    public function onLoginSuccess(LoginSuccessEvent $event): void
    {
        $user = $event->getUser();
        if (!$user instanceof AcademicUser) {
            return;
        }

        $this->connection->update(
            'sis_seg_usuario',
            [
                'usu_ultimo_acceso_en' => (new \DateTimeImmutable())->format('Y-m-d H:i:sP'),
                'usu_actualizado_en' => (new \DateTimeImmutable())->format('Y-m-d H:i:sP'),
            ],
            ['usu_id' => $user->getId()],
        );

        $this->audit->log('LOGIN_OK', 'USUARIO', $user->getId());
    }
}
