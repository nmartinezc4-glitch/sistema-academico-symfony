<?php

namespace App\Command;

use App\Repository\SecurityReadRepository;
use App\Repository\SecurityWriteRepository;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Question\Question;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:security:create-user',
    description: 'Crea el primer usuario institucional o un usuario adicional mediante Symfony Security.',
)]
final class SecurityCreateUserCommand extends Command
{
    public function __construct(
        private readonly SecurityReadRepository $read,
        private readonly SecurityWriteRepository $write,
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $roles = $this->read->roles();

        if ($roles === []) {
            $io->error('No hay roles cargados. Ejecuta primero 17_security_seed_roles.sql.');

            return Command::FAILURE;
        }

        $email = (string) $io->ask('Correo institucional');
        $firstNames = (string) $io->ask('Nombres');
        $lastNames = (string) $io->ask('Apellidos');

        $io->table(['ID', 'Código', 'Rol'], array_map(
            static fn (array $r): array => [$r['id'], $r['code'], $r['name']],
            $roles,
        ));
        $roleInput = (string) $io->ask('IDs de roles separados por coma', implode(',', array_column(array_filter(
            $roles,
            static fn (array $r): bool => in_array($r['code'], ['ROLE_COORDINACION', 'ROLE_GESTION_USUARIOS'], true),
        ), 'id')));
        $roleIds = array_values(array_filter(array_map('intval', preg_split('/\s*,\s*/', $roleInput) ?: [])));

        $question = new Question('Contraseña inicial (mínimo 10 caracteres): ');
        $question->setHidden(true);
        $question->setHiddenFallback(false);
        $password = (string) $this->getHelper('question')->ask($input, $output, $question);

        try {
            $id = $this->write->createUser($email, $firstNames, $lastNames, $password, $roleIds, null);
        } catch (\RuntimeException $e) {
            $io->error($e->getMessage());

            return Command::FAILURE;
        }

        $io->success(sprintf('Usuario creado con ID %d. La contraseña no fue almacenada en texto plano.', $id));

        return Command::SUCCESS;
    }
}
