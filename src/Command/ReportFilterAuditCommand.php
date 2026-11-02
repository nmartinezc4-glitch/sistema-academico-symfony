<?php

namespace App\Command;

use App\Service\Export\ReportExportBuilder;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:audit:report-filters',
    description: 'Comprueba que vista web, vista previa y Excel comparten el mismo conjunto de datos filtrado.',
)]
final class ReportFilterAuditCommand extends Command
{
    private const EMPTY_FILTERS = [
        'periodo' => '',
        'carrera' => '',
        'curso' => '',
        'seccion' => '',
        'estado' => '',
        'alerta' => '',
        'pensum' => '',
        'ciclo' => '',
        'q' => '',
    ];

    public function __construct(private readonly ReportExportBuilder $builder)
    {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $io->title('Auditoría de sincronía de filtros de reportes');

        $cases = [
            'alumnos-carrera' => [
                'carrera' => 'career',
                'estado' => 'status',
                'q' => 'code',
            ],
            'notas-carrera' => [
                'periodo' => 'period',
                'carrera' => 'career',
                'seccion' => 'section',
                'estado' => 'status',
            ],
            'notas-curso' => [
                'curso' => 'course',
                'periodo' => 'period',
                'carrera' => 'career',
                'seccion' => 'section',
            ],
            'notas-seccion' => [
                'periodo' => 'period',
                'carrera' => 'career',
                'curso' => 'course',
                'seccion' => 'section',
            ],
            'avance-estudiante' => [
                'carrera' => 'career',
                'pensum' => 'curriculum',
                'q' => 'code',
            ],
            'avance-ciclo' => [
                'carrera' => 'career',
                'pensum' => 'curriculum',
                'ciclo' => 'cycle',
            ],
            'pendientes-repitencias' => [
                'periodo' => 'period',
                'estado' => 'status',
                'alerta' => 'alertType',
                'q' => 'student',
            ],
        ];

        $failures = 0;
        foreach ($cases as $report => $filterMap) {
            $baseline = $this->builder->build($report, self::EMPTY_FILTERS, null)['rows'];
            if ($baseline === []) {
                $io->note(sprintf('%s: sin datos; no se puede probar selección específica.', $report));
                continue;
            }

            $sample = $baseline[0];
            foreach ($filterMap as $filterKey => $rowKey) {
                $value = trim((string) ($sample[$rowKey] ?? ''));
                if ($value === '') {
                    continue;
                }

                $filters = self::EMPTY_FILTERS;
                $filters[$filterKey] = $value;
                $filtered = $this->builder->build($report, $filters, null)['rows'];

                $valid = $filtered !== [] && $this->rowsMatch($filtered, $filterKey, $rowKey, $value);
                $io->writeln(sprintf(
                    '%s %-24s %-18s %s (%d/%d)',
                    $valid ? '<info>PASS</info>' : '<error>FAIL</error>',
                    $report,
                    $filterKey,
                    $value,
                    count($filtered),
                    count($baseline),
                ));

                if (!$valid) {
                    ++$failures;
                }
            }
        }

        if ($failures > 0) {
            $io->error(sprintf('Se detectaron %d fallos de sincronía de filtros.', $failures));

            return Command::FAILURE;
        }

        $io->success('Los filtros probados producen subconjuntos consistentes para web, vista previa y Excel.');

        return Command::SUCCESS;
    }

    /** @param list<array<string,mixed>> $rows */
    private function rowsMatch(array $rows, string $filterKey, string $rowKey, string $value): bool
    {
        $needle = mb_strtolower($value);

        foreach ($rows as $row) {
            $candidate = (string) ($row[$rowKey] ?? '');

            if ($filterKey === 'q') {
                $haystack = mb_strtolower(($row['student'] ?? $row['fullName'] ?? '').' '.($row['code'] ?? ''));
                if (!str_contains($haystack, $needle)) {
                    return false;
                }
                continue;
            }

            if ($candidate !== $value) {
                return false;
            }
        }

        return true;
    }
}
