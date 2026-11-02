<?php

namespace App\Controller;

use App\Repository\AcademicOperationsReadRepository;
use App\Repository\AcademicOperationsWriteRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class AcademicManagementController extends AbstractController
{
    #[Route('/ofertas', name: 'app_offering_index', methods: ['GET'])]
    public function offerings(Request $request, AcademicOperationsReadRepository $read): Response
    {
        $q = trim((string) $request->query->get('q', ''));
        $periodId = ctype_digit((string) $request->query->get('period', ''))
            ? (int) $request->query->get('period')
            : null;
        $sectionId = ctype_digit((string) $request->query->get('section', ''))
            ? (int) $request->query->get('section')
            : null;
        $status = strtolower(trim((string) $request->query->get('status', 'all')));
        if (!\in_array($status, ['all', 'active', 'inactive'], true)) {
            $status = 'all';
        }

        return $this->render('offering/index.html.twig', [
            'items' => $read->offeringCatalog($q, $periodId, $sectionId, $status),
            'metrics' => $read->offeringMetrics(),
            'periods' => $read->availablePeriods(true),
            'sections' => $read->sections(),
            'q' => $q,
            'periodId' => $periodId,
            'sectionId' => $sectionId,
            'status' => $status,
        ]);
    }

    #[Route('/ofertas/nueva', name: 'app_offering_new', methods: ['GET', 'POST'])]
    public function createOffering(
        Request $request,
        AcademicOperationsReadRepository $read,
        AcademicOperationsWriteRepository $write,
    ): Response {
        $errors = [];
        $form = [
            'periodId' => '',
            'curriculumCourseId' => '',
            'sectionId' => '',
        ];

        if ($request->isMethod('POST')) {
            $form = [
                'periodId' => trim((string) $request->request->get('periodId', '')),
                'curriculumCourseId' => trim((string) $request->request->get('curriculumCourseId', '')),
                'sectionId' => trim((string) $request->request->get('sectionId', '')),
            ];

            if (!ctype_digit($form['periodId'])) {
                $errors[] = 'Selecciona un período académico.';
            }
            if (!ctype_digit($form['curriculumCourseId'])) {
                $errors[] = 'Selecciona un curso de pensum.';
            }
            if (!ctype_digit($form['sectionId'])) {
                $errors[] = 'Selecciona una sección.';
            }

            if ($errors === []) {
                try {
                    $write->createOffering(
                        (int) $form['periodId'],
                        (int) $form['curriculumCourseId'],
                        (int) $form['sectionId'],
                    );
                    $this->addFlash('success', 'Oferta académica creada correctamente.');

                    return $this->redirectToRoute('app_offering_index');
                } catch (\RuntimeException $e) {
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('offering/new.html.twig', [
            'periods' => $read->availablePeriods(),
            'curriculumCourses' => $read->curriculumCourses(),
            'sections' => $read->sections(),
            'form' => $form,
            'errors' => $errors,
        ]);
    }
}
