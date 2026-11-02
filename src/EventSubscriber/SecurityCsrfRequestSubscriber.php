<?php

namespace App\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\Security\Csrf\CsrfToken;
use Symfony\Component\Security\Csrf\CsrfTokenManagerInterface;

final class SecurityCsrfRequestSubscriber implements EventSubscriberInterface
{
    public function __construct(private readonly CsrfTokenManagerInterface $csrf)
    {
    }

    public static function getSubscribedEvents(): array
    {
        return [KernelEvents::REQUEST => ['onKernelRequest', 8]];
    }

    public function onKernelRequest(RequestEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();
        if (!$request->isMethod('POST')) {
            return;
        }

        $route = (string) $request->attributes->get('_route', '');
        if ($route === '' || !str_starts_with($route, 'app_') || in_array($route, ['app_login', 'app_logout'], true)) {
            return;
        }

        $provided = (string) $request->request->get('_token', '');
        if (!$this->csrf->isTokenValid(new CsrfToken($route, $provided))) {
            throw new AccessDeniedHttpException('La sesión del formulario expiró o la solicitud no es válida. Recarga la página e intenta nuevamente.');
        }
    }
}
