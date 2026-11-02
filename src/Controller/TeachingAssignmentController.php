<?php

namespace App\Controller;

use App\Repository\TeachingAssignmentReadRepository;
use App\Repository\TeachingAssignmentWriteRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[IsGranted('ROLE_COORDINACION')]
final class TeachingAssignmentController extends AbstractController
{
    #[Route('/ofertas/docentes', name: 'app_teaching_assignment_index', methods: ['GET', 'POST'])]
    public function index(
        Request $request,
        TeachingAssignmentReadRepository $read,
        TeachingAssignmentWriteRepository $write,
    ): Response {
        $errors = [];

        if ($request->isMethod('POST')) {
            $userId = (int) $request->request->get('userId', 0);
            $offeringId = (int) $request->request->get('offeringId', 0);

            try {
                $write->assign($userId, $offeringId);
                $this->addFlash('success', 'Docente asignado a la oferta académica.');

                return $this->redirectToRoute('app_teaching_assignment_index');
            } catch (\RuntimeException $e) {
                $errors[] = $e->getMessage();
            }
        }

        return $this->render('security/teaching_assignments.html.twig', [
            'teachers' => $read->teachers(),
            'offerings' => $read->offerings(),
            'assignments' => $read->assignments(),
            'errors' => $errors,
        ]);
    }

    #[Route('/ofertas/docentes/{userId}/{offeringId}/retirar', name: 'app_teaching_assignment_remove', methods: ['POST'], requirements: ['userId' => '\\d+', 'offeringId' => '\\d+'])]
    public function remove(int $userId, int $offeringId, TeachingAssignmentWriteRepository $write): Response
    {
        $write->remove($userId, $offeringId);
        $this->addFlash('success', 'Asignación docente retirada.');

        return $this->redirectToRoute('app_teaching_assignment_index', status: Response::HTTP_SEE_OTHER);
    }
}
