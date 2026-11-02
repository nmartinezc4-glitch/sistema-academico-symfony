<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Authentication\AuthenticationUtils;

final class AuthController extends AbstractController
{
    #[Route('/login', name: 'app_login', methods: ['GET', 'POST'])]
    public function login(AuthenticationUtils $authenticationUtils): Response
    {
        if ($this->getUser() !== null) {
            return $this->redirectToRoute('app_dashboard');
        }

        return $this->render('auth/login.html.twig', [
            'lastUsername' => $authenticationUtils->getLastUsername(),
            'error' => $authenticationUtils->getLastAuthenticationError() !== null
                ? 'Credenciales inválidas o cuenta inactiva.'
                : null,
        ]);
    }

    #[Route('/logout', name: 'app_logout', methods: ['POST'])]
    public function logout(): never
    {
        throw new \LogicException('Symfony Security intercepta esta ruta.');
    }
}
