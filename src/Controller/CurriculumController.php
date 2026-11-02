<?php

namespace App\Controller;

use App\Repository\AcademicCatalogWriteRepository;
use App\Repository\CurriculumReadRepository;
use App\Repository\CurriculumWriteRepository;
use App\Ui\Paginator;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class CurriculumController extends AbstractController
{
    #[Route('/pensums', name: 'app_curriculum_index', methods: ['GET'])]
    public function index(Request $request, CurriculumReadRepository $repo): Response
    {
        $q = trim((string) $request->query->get('q', ''));
        $career = trim((string) $request->query->get('career', ''));
        $status = strtolower(trim((string) $request->query->get('status', 'all')));
        if (!\in_array($status, ['all', 'active', 'inactive'], true)) {
            $status = 'all';
        }

        $order = strtolower(trim((string) $request->query->get('orden', 'career-asc')));
        if (!\in_array($order, ['career-asc', 'name-asc', 'newest', 'courses-desc'], true)) {
            $order = 'career-asc';
        }

        $filteredTotal = $repo->countCurriculaSearch(
            q: $q,
            careerId: $career !== '' ? $career : null,
            status: $status,
        );
        $pager = Paginator::fromRequest($request, $filteredTotal);
        $metrics = $repo->curriculumMetrics();

        return $this->render('curriculum/index.html.twig', [
            'items' => $repo->searchCurriculaPage(
                q: $q,
                careerId: $career !== '' ? $career : null,
                status: $status,
                order: $order,
                limit: $pager->perPage,
                offset: $pager->offset(),
            ),
            'q' => $q,
            'career' => $career,
            'status' => $status,
            'order' => $order,
            'careers' => $repo->careers(),
            'metrics' => $metrics,
            'filteredTotal' => $filteredTotal,
            'total' => $metrics['total'],
            'pager' => $pager,
        ]);
    }

    #[Route('/pensums/nuevo', name: 'app_curriculum_new', methods: ['GET', 'POST'])]
    public function create(
        Request $request,
        CurriculumReadRepository $read,
        CurriculumWriteRepository $write,
    ): Response {
        $errors = [];
        $form = [
            'careerId' => '',
            'name' => '',
            'validFrom' => '',
            'validUntil' => '',
        ];

        if ($request->isMethod('POST')) {
            $form = [
                'careerId' => trim((string) $request->request->get('careerId', '')),
                'name' => trim((string) $request->request->get('name', '')),
                'validFrom' => trim((string) $request->request->get('validFrom', '')),
                'validUntil' => trim((string) $request->request->get('validUntil', '')),
            ];

            if (!ctype_digit($form['careerId'])) {
                $errors[] = 'Selecciona una carrera válida.';
            }
            if ($form['name'] === '' || mb_strlen($form['name']) > 150) {
                $errors[] = 'El nombre es obligatorio y admite hasta 150 caracteres.';
            }

            $validFrom = self::dateInput($form['validFrom']);
            $validUntil = $form['validUntil'] === '' ? null : self::dateInput($form['validUntil']);
            if ($validFrom === null) {
                $errors[] = 'La fecha de inicio de vigencia no es válida.';
            }
            if ($form['validUntil'] !== '' && $validUntil === null) {
                $errors[] = 'La fecha de fin de vigencia no es válida.';
            }
            if ($validFrom !== null && $validUntil !== null && $validUntil < $validFrom) {
                $errors[] = 'La fecha de fin no puede ser anterior al inicio de vigencia.';
            }

            if ($errors === []) {
                try {
                    $id = $write->createPensum(
                        (int) $form['careerId'],
                        $form['name'],
                        $form['validFrom'],
                        $form['validUntil'] !== '' ? $form['validUntil'] : null,
                    );

                    $this->addFlash('success', 'Pensum creado como borrador. Agrega sus cursos y actívalo cuando esté listo.');

                    return $this->redirectToRoute('app_curriculum_show', ['id' => $id]);
                } catch (\RuntimeException $e) {
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('curriculum/new.html.twig', [
            'careers' => $read->careers(),
            'errors' => $errors,
            'form' => $form,
        ]);
    }

    #[Route('/pensums/{id}', name: 'app_curriculum_show', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function show(int $id, CurriculumReadRepository $repo): Response
    {
        $vm = $repo->curriculum($id);
        if (!$vm) {
            throw $this->createNotFoundException();
        }

        return $this->render('curriculum/show.html.twig', [
            'vm' => $vm,
            'courseCatalog' => $repo->courses(),
            'availableCycles' => $repo->availableCycles(),
        ]);
    }

    #[Route('/pensums/{id}/cursos', name: 'app_curriculum_course_add', methods: ['POST'], requirements: ['id' => '\\d+'])]
    public function addCourse(
        int $id,
        Request $request,
        CurriculumWriteRepository $write,
    ): Response {
        try {
            $courseId = (int) $request->request->get('courseId', 0);
            $cycleId = (int) $request->request->get('cycleId', 0);
            $required = $request->request->getBoolean('required', true);

            if ($courseId <= 0 || $cycleId <= 0) {
                throw new \RuntimeException('Selecciona un curso y un ciclo curricular.');
            }

            $write->addCourse($id, $courseId, $cycleId, $required);
            $this->addFlash('success', 'Curso agregado al pensum correctamente.');
        } catch (\RuntimeException $e) {
            $this->addFlash('danger', $e->getMessage());
        }

        return $this->redirectToRoute('app_curriculum_show', ['id' => $id], Response::HTTP_SEE_OTHER);
    }

    #[Route('/pensums/{id}/activar', name: 'app_curriculum_activate', methods: ['POST'], requirements: ['id' => '\\d+'])]
    public function activate(int $id, CurriculumWriteRepository $write): Response
    {
        try {
            $write->activate($id);
            $this->addFlash('success', 'Pensum activado. Ya puede asignarse a nuevos estudiantes.');
        } catch (\RuntimeException $e) {
            $this->addFlash('danger', $e->getMessage());
        }

        return $this->redirectToRoute('app_curriculum_show', ['id' => $id], Response::HTTP_SEE_OTHER);
    }

    #[Route('/carreras', name: 'app_career_index', methods: ['GET'])]
    public function careers(CurriculumReadRepository $repo): Response
    {
        return $this->render('shell/catalog.html.twig', [
            'title' => 'Carreras',
            'subtitle' => 'Administra las carreras disponibles para crear y versionar pensums.',
            'items' => $repo->careerCatalog(),
            'columns' => [
                ['key' => 'code', 'label' => 'Código'],
                ['key' => 'name', 'label' => 'Nombre'],
                ['key' => 'description', 'label' => 'Descripción'],
                ['key' => 'status', 'label' => 'Estado', 'type' => 'badge'],
            ],
            'createRoute' => 'app_career_new',
            'createLabel' => 'Nueva carrera',
        ]);
    }

    #[Route('/carreras/nueva', name: 'app_career_new', methods: ['GET', 'POST'])]
    public function createCareer(Request $request, AcademicCatalogWriteRepository $write): Response
    {
        return $this->catalogCreate($request, $write, 'career');
    }

    #[Route('/cursos', name: 'app_course_index', methods: ['GET'])]
    public function courses(CurriculumReadRepository $repo): Response
    {
        return $this->render('shell/catalog.html.twig', [
            'title' => 'Cursos',
            'subtitle' => 'Catálogo maestro de materias reutilizable entre pensums y versiones.',
            'items' => $repo->courseCatalog(),
            'columns' => [
                ['key' => 'code', 'label' => 'Código'],
                ['key' => 'name', 'label' => 'Nombre'],
                ['key' => 'description', 'label' => 'Descripción'],
                ['key' => 'status', 'label' => 'Estado', 'type' => 'badge'],
            ],
            'createRoute' => 'app_course_new',
            'createLabel' => 'Nuevo curso',
        ]);
    }

    #[Route('/cursos/nuevo', name: 'app_course_new', methods: ['GET', 'POST'])]
    public function createCourse(Request $request, AcademicCatalogWriteRepository $write): Response
    {
        return $this->catalogCreate($request, $write, 'course');
    }

    #[Route('/secciones', name: 'app_section_index', methods: ['GET'])]
    public function sections(CurriculumReadRepository $repo): Response
    {
        return $this->render('shell/catalog.html.twig', [
            'title' => 'Secciones',
            'catalogEyebrow' => 'Gestión académica',
            'subtitle' => 'Administra las secciones utilizadas en inscripciones y ofertas académicas.',
            'items' => $repo->sectionCatalog(),
            'columns' => [
                ['key' => 'code', 'label' => 'Código'],
                ['key' => 'name', 'label' => 'Nombre'],
                ['key' => 'status', 'label' => 'Estado', 'type' => 'badge'],
            ],
            'createRoute' => 'app_section_new',
            'createLabel' => 'Nueva sección',
        ]);
    }

    #[Route('/secciones/nueva', name: 'app_section_new', methods: ['GET', 'POST'])]
    public function createSection(Request $request, AcademicCatalogWriteRepository $write): Response
    {
        return $this->catalogCreate($request, $write, 'section');
    }

    private function catalogCreate(
        Request $request,
        AcademicCatalogWriteRepository $write,
        string $kind,
    ): Response {
        $config = match ($kind) {
            'career' => [
                'title' => 'Nueva carrera',
                'eyebrow' => 'Estructura académica',
                'entityLabel' => 'carrera',
                'article' => 'la',
                'indexRoute' => 'app_career_index',
                'codePattern' => 'SIGLA institucional',
                'codeHelp' => 'El sistema puede sugerirla desde el nombre; coordinación puede indicar una sigla preferida.',
                'codeInput' => 'career',
                'nameMax' => 150,
                'description' => true,
            ],
            'course' => [
                'title' => 'Nuevo curso',
                'eyebrow' => 'Catálogo académico',
                'entityLabel' => 'curso',
                'article' => 'el',
                'indexRoute' => 'app_course_index',
                'codePattern' => 'SIGLA-###',
                'codeHelp' => 'Ej.: MAT-101, COM-102. El correlativo se calcula automáticamente.',
                'codeInput' => 'course',
                'nameMax' => 150,
                'description' => true,
            ],
            'section' => [
                'title' => 'Nueva sección',
                'eyebrow' => 'Gestión académica',
                'entityLabel' => 'sección',
                'article' => 'la',
                'indexRoute' => 'app_section_index',
                'codePattern' => 'A, B, C…',
                'codeHelp' => 'La siguiente letra disponible se asigna automáticamente.',
                'codeInput' => 'section',
                'nameMax' => 50,
                'description' => false,
            ],
            default => throw new \LogicException('Catálogo no soportado.'),
        };

        $form = [
            'name' => '',
            'description' => '',
            'codeHint' => '',
        ];
        $errors = [];

        if ($request->isMethod('POST')) {
            $form = [
                'name' => trim((string) $request->request->get('name', '')),
                'description' => trim((string) $request->request->get('description', '')),
                'codeHint' => trim((string) $request->request->get('codeHint', '')),
            ];

            if ($kind !== 'section' && ($form['name'] === '' || mb_strlen($form['name']) > $config['nameMax'])) {
                $errors[] = sprintf('El nombre es obligatorio y admite hasta %d caracteres.', $config['nameMax']);
            }

            if ($errors === []) {
                try {
                    $created = match ($kind) {
                        'career' => $write->createCareer($form['name'], $form['description'], $form['codeHint']),
                        'course' => $write->createCourse($form['name'], $form['description'], $form['codeHint']),
                        'section' => $write->createSection(),
                    };

                    $this->addFlash('success', sprintf(
                        '%s creada correctamente con código %s.',
                        ucfirst($config['entityLabel']),
                        $created['code'],
                    ));

                    return $this->redirectToRoute($config['indexRoute']);
                } catch (\RuntimeException $e) {
                    $errors[] = $e->getMessage();
                }
            }
        }

        return $this->render('catalog/new.html.twig', [
            'config' => $config,
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
        if ($date === false || $date->format('Y-m-d') !== $value) {
            return null;
        }

        return $date;
    }

}
