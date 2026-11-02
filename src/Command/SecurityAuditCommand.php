<?php

namespace App\Command;

use Doctrine\DBAL\Connection;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:security:audit',
    description: 'Verifica que la fase de identidad, roles y permisos esté lista para pruebas funcionales.',
)]
final class SecurityAuditCommand extends Command
{
    private const REQUIRED_ROLES = [
        'ROLE_DOCENTE',
        'ROLE_COORDINACION',
        'ROLE_DIRECCION',
        'ROLE_GESTION_USUARIOS',
    ];

    public function __construct(private readonly Connection $connection)
    {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $errors = [];
        $warnings = [];

        foreach (['sis_seg_usuario', 'sis_seg_rol', 'sis_seg_usuario_rol', 'sis_seg_auditoria', 'sis_aca_docente_oferta'] as $relation) {
            if ($this->connection->fetchOne('SELECT to_regclass(:name)', ['name' => 'public.'.$relation]) === null) {
                $errors[] = 'Falta relación de seguridad: '.$relation;
            }
        }

        if ($errors !== []) {
            $io->error($errors);

            return Command::FAILURE;
        }

        $photoColumn = (int) $this->connection->fetchOne(
            "SELECT COUNT(*) FROM information_schema.columns
             WHERE table_schema = 'public'
               AND table_name = 'sis_seg_usuario'
               AND column_name = 'usu_foto_ruta'"
        );
        if ($photoColumn !== 1) {
            $errors[] = 'Falta SIS_SEG_USUARIO.USU_FOTO_RUTA. Ejecuta 18_security_user_photo.sql.';
        }

        $roleCodes = array_map('strval', $this->connection->fetchFirstColumn(
            'SELECT rol_codigo FROM sis_seg_rol WHERE rol_activo ORDER BY rol_codigo'
        ));
        foreach (self::REQUIRED_ROLES as $requiredRole) {
            if (!in_array($requiredRole, $roleCodes, true)) {
                $errors[] = 'Falta rol activo requerido: '.$requiredRole;
            }
        }

        $users = $this->connection->fetchAllAssociative(
            'SELECT usu_id, usu_correo, usu_password_hash, usu_activo FROM sis_seg_usuario ORDER BY usu_id'
        );
        $activeUsers = 0;
        foreach ($users as $user) {
            if ((bool) $user['usu_activo']) {
                ++$activeUsers;
            }

            $info = password_get_info((string) $user['usu_password_hash']);
            if (($info['algoName'] ?? 'unknown') === 'unknown') {
                $errors[] = sprintf(
                    'El usuario %s no tiene un hash de contraseña reconocido por PHP/Symfony.',
                    (string) $user['usu_correo']
                );
            }
        }

        $activeManagers = (int) $this->connection->fetchOne(
            <<<'SQL'
            SELECT COUNT(DISTINCT u.usu_id)
            FROM sis_seg_usuario u
            JOIN sis_seg_usuario_rol ur ON ur.usr_usu_id = u.usu_id
            JOIN sis_seg_rol r ON r.rol_id = ur.usr_rol_id
            WHERE u.usu_activo
              AND r.rol_activo
              AND r.rol_codigo = 'ROLE_GESTION_USUARIOS'
            SQL
        );

        if ($users === []) {
            $warnings[] = 'Todavía no existe ningún usuario institucional. Crea el primero con app:security:create-user.';
        } elseif ($activeManagers === 0) {
            $errors[] = 'Debe existir al menos un usuario activo con ROLE_GESTION_USUARIOS.';
        }

        $teacherAssignments = (int) $this->connection->fetchOne(
            'SELECT COUNT(*) FROM sis_aca_docente_oferta WHERE dof_activo'
        );
        $auditEvents = (int) $this->connection->fetchOne('SELECT COUNT(*) FROM sis_seg_auditoria');

        $io->table(['Indicador', 'Valor'], [
            ['Roles activos', count($roleCodes)],
            ['Usuarios registrados', count($users)],
            ['Usuarios activos', $activeUsers],
            ['Gestores de usuarios activos', $activeManagers],
            ['Asignaciones docente-oferta activas', $teacherAssignments],
            ['Eventos de auditoría', $auditEvents],
            ['Columna de fotografía', $photoColumn === 1 ? 'OK' : 'FALTA'],
        ]);

        if ($warnings !== []) {
            $io->warning($warnings);
        }

        if ($errors !== []) {
            $io->error($errors);

            return Command::FAILURE;
        }

        if ($users === []) {
            $io->note('Infraestructura de seguridad correcta; falta crear el primer usuario institucional.');

            return Command::SUCCESS;
        }

        $io->success('Seguridad certificada para iniciar pruebas funcionales por rol.');

        return Command::SUCCESS;
    }
}
