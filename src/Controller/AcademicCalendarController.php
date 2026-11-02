<?php

namespace App\Controller;

use App\Repository\AcademicCalendarReadRepository;
use App\Repository\AcademicCalendarWriteRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class AcademicCalendarController extends AbstractController
{
    #[Route('/periodos', name: 'app_period_index', methods: ['GET'])]
    public function index(AcademicCalendarReadRepository $read): Response
    {
        return $this->render('calendar/index.html.twig', [
            'years' => $read->calendar(),
            'metrics' => $read->metrics(),
        ]);
    }

    #[Route('/anios/nuevo', name: 'app_year_new', methods: ['GET', 'POST'])]
    public function createYear(Request $request, AcademicCalendarWriteRepository $write): Response
    {
        $form = [
            'year' => '',
            'name' => '',
            'startDate' => '',
            'endDate' => '',
        ];
        $errors = [];

        if ($request->isMethod('POST')) {
            $form = [
                'year' => trim((string) $request->request->get('year', '')),
                'name' => trim((string) $request->request->get('name', '')),
                'startDate' => trim((string) $request->request->get('startDate', '')),
                'endDate' => trim((string) $request->request->get('endDate', '')),
            ];

            if (!ctype_digit($form['year']) || (int) $form['year'] <= 0) {
                $errors[] = 'El año lectivo debe ser un número positivo.';
            }
            if ($form['name'] === '' || mb_strlen($form['name']) > 100) {
                $errors[] = 'El nombre es obligatorio y admite hasta 100 caracteres.';
            }

            $start = self::dateInput($form['startDate']);
            $end = self::dateInput($form['endDate']);
            if ($start === null || $end === null) {
                $errors[] = 'Las fechas del año lectivo no son válidas.';
            } elseif ($end < $start) {
                $errors[] = 'La fecha final no puede ser anterior a la fecha inicial.';
            }

            if ($errors === []) {
                try {
                    $write->createYear(
                        (int) $form['year'],
                        $form['name'],
                        $form['startDate'],
                        $form['endDate'],
                    );
                    $this->addFlash('success', 'Año lectivo creado como PLANIFICADO.');

                    return $this->redirectToRoute('app_period_index');
                } catch (\RuntimeException $e) {
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('calendar/year_new.html.twig', [
            'form' => $form,
            'errors' => $errors,
        ]);
    }

    #[Route('/periodos/nuevo', name: 'app_period_new', methods: ['GET', 'POST'])]
    public function createPeriod(
        Request $request,
        AcademicCalendarReadRepository $read,
        AcademicCalendarWriteRepository $write,
    ): Response {
        $form = [
            'yearId' => '',
            'number' => '',
            'startDate' => '',
            'endDate' => '',
        ];
        $errors = [];

        if ($request->isMethod('POST')) {
            $form = [
                'yearId' => trim((string) $request->request->get('yearId', '')),
                'number' => trim((string) $request->request->get('number', '')),
                'startDate' => trim((string) $request->request->get('startDate', '')),
                'endDate' => trim((string) $request->request->get('endDate', '')),
            ];

            if (!ctype_digit($form['yearId'])) {
                $errors[] = 'Selecciona un año lectivo.';
            }
            if (!\in_array($form['number'], ['1', '2'], true)) {
                $errors[] = 'Selecciona Semestre I o Semestre II.';
            }

            $start = self::dateInput($form['startDate']);
            $end = self::dateInput($form['endDate']);
            if ($start === null || $end === null) {
                $errors[] = 'Las fechas del período no son válidas.';
            } elseif ($end < $start) {
                $errors[] = 'La fecha final no puede ser anterior a la fecha inicial.';
            }

            if ($errors === []) {
                try {
                    $write->createPeriod(
                        (int) $form['yearId'],
                        (int) $form['number'],
                        $form['startDate'],
                        $form['endDate'],
                    );
                    $this->addFlash('success', 'Período académico creado como PLANIFICADO. La política vigente fue asignada automáticamente.');

                    return $this->redirectToRoute('app_period_index');
                } catch (\RuntimeException $e) {
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('calendar/period_new.html.twig', [
            'years' => $read->years(),
            'form' => $form,
            'errors' => $errors,
        ]);
    }

    #[Route('/periodos/{id}/abrir', name: 'app_period_open', methods: ['POST'], requirements: ['id' => '\\d+'])]
    public function open(int $id, AcademicCalendarWriteRepository $write): Response
    {
        try {
            $write->transitionPeriod($id, 'ABIERTO');
            $this->addFlash('success', 'Período abierto. Ahora admite captura y corrección de resultados.');
        } catch (\RuntimeException $e) {
            $this->addFlash('danger', $e->getMessage());
        }

        return $this->redirectToRoute('app_period_index', status: Response::HTTP_SEE_OTHER);
    }

    #[Route('/periodos/{id}/cerrar', name: 'app_period_close', methods: ['POST'], requirements: ['id' => '\\d+'])]
    public function close(int $id, AcademicCalendarWriteRepository $write): Response
    {
        try {
            $write->transitionPeriod($id, 'CERRADO');
            $this->addFlash('success', 'Período cerrado. Las notas quedan protegidas contra modificaciones ordinarias.');
        } catch (\RuntimeException $e) {
            $this->addFlash('danger', $e->getMessage());
        }

        return $this->redirectToRoute('app_period_index', status: Response::HTTP_SEE_OTHER);
    }

    #[Route('/politicas-academicas', name: 'app_policy_index', methods: ['GET'])]
    public function policies(AcademicCalendarReadRepository $read): Response
    {
        return $this->render('shell/catalog.html.twig', [
            'title' => 'Políticas académicas',
            'catalogEyebrow' => 'Configuración',
            'subtitle' => 'Historial versionado de reglas de aprobación. Las políticas utilizadas quedan protegidas por reglas de integridad del sistema.',
            'items' => $read->policies(),
            'columns' => [
                ['key' => 'code', 'label' => 'Código'],
                ['key' => 'name', 'label' => 'Nombre'],
                ['key' => 'passingGrade', 'label' => 'Nota aprobación'],
                ['key' => 'validFrom', 'label' => 'Vigente desde'],
                ['key' => 'validUntil', 'label' => 'Vigente hasta'],
            ],
            'createRoute' => 'app_policy_new',
            'createLabel' => 'Nueva política',
            'catalogNote' => 'Las políticas conservan su vigencia histórica. Una reforma se registra como una nueva versión y no modifica períodos anteriores.',
        ]);
    }

    #[Route('/politicas-academicas/nueva', name: 'app_policy_new', methods: ['GET', 'POST'])]
    public function createPolicy(Request $request, AcademicCalendarWriteRepository $write): Response
    {
        $form = [
            'name' => '',
            'passingGrade' => '',
            'validFrom' => '',
        ];
        $errors = [];

        if ($request->isMethod('POST')) {
            $form = [
                'name' => trim((string) $request->request->get('name', '')),
                'passingGrade' => trim((string) $request->request->get('passingGrade', '')),
                'validFrom' => trim((string) $request->request->get('validFrom', '')),
            ];

            if ($form['name'] === '' || mb_strlen($form['name']) > 150) {
                $errors[] = 'El nombre es obligatorio y admite hasta 150 caracteres.';
            }
            if (!is_numeric($form['passingGrade'])) {
                $errors[] = 'La nota mínima debe ser numérica.';
            } elseif ((float) $form['passingGrade'] < 0 || (float) $form['passingGrade'] > 100) {
                $errors[] = 'La nota mínima debe estar entre 0 y 100.';
            }
            if (self::dateInput($form['validFrom']) === null) {
                $errors[] = 'La fecha de vigencia no es válida.';
            }

            if ($errors === []) {
                try {
                    $write->createPolicy(
                        $form['name'],
                        (float) $form['passingGrade'],
                        $form['validFrom'],
                    );
                    $this->addFlash('success', 'Nueva política académica creada. Los períodos futuros usarán la regla vigente según su fecha de inicio.');

                    return $this->redirectToRoute('app_policy_index');
                } catch (\RuntimeException $e) {
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('policy/new.html.twig', [
            'form' => $form,
            'errors' => $errors,
        ]);
    }

    private static function dateInput(string $value): ?\DateTimeImmutable
    {
        if ($value === '') {
            return null;
        }

        $date = \DateTimeImmutable::createFromFormat('!Y-m-d', $value);

        return $date !== false && $date->format('Y-m-d') === $value ? $date : null;
    }
}
