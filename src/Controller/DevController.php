<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class DevController extends AbstractController
{
    #[Route('/ui-kit', name: 'app_dev_ui_kit', methods: ['GET'])]
    public function uiKit(): Response
    {
        return $this->render('dev/ui_kit.html.twig');
    }
}
