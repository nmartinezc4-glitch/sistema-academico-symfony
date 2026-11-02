<?php

namespace App\Command;

use Doctrine\DBAL\Connection;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Routing\RouterInterface;

#[AsCommand(
    name: 'app:audit:preflight',
    description: 'Verifica dependencias estructurales mínimas antes de las pruebas funcionales.',
)]
final class ApplicationAuditCommand extends Command
{
    public function __construct(
        private readonly Connection $connection,
        private readonly RouterInterface $router,
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $errors = [];

        $relations = [
            'sis_aca_estudiante',
            'sis_aca_estudiante_programa',
            'sis_aca_estudiante_periodo',
            'sis_aca_carrera',
            'sis_aca_curso',
            'sis_aca_seccion',
            'sis_aca_pensum',
            'sis_aca_pensum_curso',
            'sis_aca_periodo_academico',
            'sis_aca_oferta_curso',
            'sis_aca_resultado_curso',
            'sis_aca_vw_ingreso_notas',
            'sis_aca_vw_reporte_notas',
            'sis_aca_vw_avance_pensum',
            'sis_aca_docente_oferta',
            'sis_seg_usuario',
            'sis_seg_rol',
            'sis_seg_usuario_rol',
            'sis_seg_auditoria',
        ];

        foreach ($relations as $relation) {
            if ($this->connection->fetchOne('SELECT to_regclass(:name)', ['name' => 'public.'.$relation]) === null) {
                $errors[] = 'Falta relación PostgreSQL: '.$relation;
            }
        }

        $routes = [
            'app_login', 'app_logout', 'app_dashboard', 'app_student_index', 'app_student_new',
            'app_grade_entry', 'app_career_index', 'app_course_index', 'app_curriculum_index',
            'app_period_index', 'app_offering_index', 'app_report_index', 'app_report_export_xlsx',
        ];
        $collection = $this->router->getRouteCollection();
        foreach ($routes as $route) {
            if ($collection->get($route) === null) {
                $errors[] = 'Falta ruta Symfony: '.$route;
            }
        }

        $userPhotoColumn = (int) $this->connection->fetchOne("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sis_seg_usuario' AND column_name = 'usu_foto_ruta'");
        if ($userPhotoColumn !== 1) {
            $errors[] = 'Falta columna de seguridad: SIS_SEG_USUARIO.USU_FOTO_RUTA. Ejecuta 18_security_user_photo.sql.';
        }

        $invalidCourseCodes = (int) $this->connection->fetchOne(
            "SELECT COUNT(*) FROM sis_aca_curso WHERE upper(cur_codigo) !~ '^[A-Z][A-Z0-9-]*-[0-9]{3}$'"
        );
        if ($invalidCourseCodes > 0) {
            $errors[] = sprintf('Hay %d código(s) de curso fuera del patrón SIGLA-###.', $invalidCourseCodes);
        }

        $invalidSections = (int) $this->connection->fetchOne(
            "SELECT COUNT(*) FROM sis_aca_seccion WHERE upper(sec_codigo) !~ '^[A-Z]+$'"
        );
        if ($invalidSections > 0) {
            $errors[] = sprintf('Hay %d sección(es) fuera del patrón alfabético A, B, C…', $invalidSections);
        }

        $students = (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_aca_estudiante');
        $results = (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_aca_resultado_curso');
        $pending = (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_aca_resultado_curso WHERE res_nota IS NULL');

        $io->table(['Indicador', 'Valor'], [
            ['Estudiantes', $students],
            ['Resultados', $results],
            ['Resultados pendientes', $pending],
            ['Relaciones verificadas', count($relations)],
            ['Roles de seguridad', (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_seg_rol WHERE rol_activo')],
            ['Rutas críticas verificadas', count($routes)],
        ]);

        if ($errors !== []) {
            $io->error($errors);

            return Command::FAILURE;
        }

        $io->success('Preflight estructural correcto. El sistema está listo para pruebas funcionales controladas.');

        return Command::SUCCESS;
    }
}
