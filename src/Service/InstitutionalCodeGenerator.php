<?php

namespace App\Service;

use Doctrine\DBAL\Connection;

final class InstitutionalCodeGenerator
{
    public function __construct(private readonly Connection $connection)
    {
    }

    public function nextStudentCode(string $programStartDate): string
    {
        $year = $this->yearFromDate($programStartDate, 'fecha de ingreso');

        return $this->nextScopedCode(
            sprintf('sis_aca_estudiante_codigo_%04d', $year),
            'sis_aca_estudiante',
            'est_codigo',
            sprintf('STU-%04d', $year),
            4,
        );
    }

    public function nextCareerCode(string $name, ?string $preferredCode = null): string
    {
        $base = $preferredCode !== null && trim($preferredCode) !== ''
            ? $this->normalizeSemanticCode($preferredCode, 20)
            : $this->acronym($name, 10);

        $this->assertTransaction();
        $this->lock('sis_aca_carrera_codigo_'.$base);

        if (!$this->codeExists('sis_aca_carrera', 'car_codigo', $base)) {
            return $base;
        }

        for ($i = 2; $i <= 99; ++$i) {
            $candidate = $base.'-'.$i;
            if (!$this->codeExists('sis_aca_carrera', 'car_codigo', $candidate)) {
                return $candidate;
            }
        }

        throw new \RuntimeException('No hay códigos disponibles para la sigla de carrera '.$base.'.');
    }

    public function nextCourseCode(string $name, ?string $preferredPrefix = null): string
    {
        $prefix = $preferredPrefix !== null && trim($preferredPrefix) !== ''
            ? $this->normalizeSemanticCode($preferredPrefix, 8)
            : $this->acronym($name, 5);

        return $this->nextScopedCode(
            'sis_aca_curso_codigo_'.$prefix,
            'sis_aca_curso',
            'cur_codigo',
            $prefix,
            3,
            101,
        );
    }

    public function nextSectionCode(): string
    {
        $this->assertTransaction();
        $this->lock('sis_aca_seccion_codigo');

        $codes = $this->connection->fetchFirstColumn(
            "SELECT upper(sec_codigo)
             FROM sis_aca_seccion
             WHERE upper(sec_codigo) ~ '^[A-Z]+$'"
        );

        $max = 0;
        foreach ($codes as $code) {
            $max = max($max, $this->alphaToNumber((string) $code));
        }

        return $this->numberToAlpha($max + 1);
    }

    public function nextCurriculumCode(string $careerCode, string $validFrom, int $version): string
    {
        $year = $this->yearFromDate($validFrom, 'fecha de vigencia del pensum');
        $careerCode = $this->normalizeSemanticCode($careerCode, 20);
        $base = sprintf('%s-%04d', $careerCode, $year);

        $this->assertTransaction();
        $this->lock(sprintf('sis_aca_pensum_codigo_%s_%04d', $careerCode, $year));

        if (!$this->codeExists('sis_aca_pensum', 'pen_codigo', $base)) {
            return $base;
        }

        $candidate = sprintf('%s-V%d', $base, max(2, $version));
        if (strlen($candidate) > 30) {
            throw new \RuntimeException('La sigla de carrera es demasiado larga para generar el código del pensum.');
        }
        if (!$this->codeExists('sis_aca_pensum', 'pen_codigo', $candidate)) {
            return $candidate;
        }

        for ($i = max(2, $version + 1); $i <= 99; ++$i) {
            $candidate = sprintf('%s-V%d', $base, $i);
            if (!$this->codeExists('sis_aca_pensum', 'pen_codigo', $candidate)) {
                return $candidate;
            }
        }

        throw new \RuntimeException('No hay códigos disponibles para el pensum '.$base.'.');
    }

    public function nextPolicyCode(string $validFrom): string
    {
        $year = $this->yearFromDate($validFrom, 'fecha de vigencia de la política');

        return $this->nextScopedCode(
            sprintf('sis_aca_politica_codigo_%04d', $year),
            'sis_aca_politica_academica',
            'pol_codigo',
            sprintf('POL-%04d', $year),
            2,
        );
    }

    private function nextScopedCode(string $lockKey, string $table, string $column, string $prefix, int $digits, int $startAt = 1): string
    {
        $this->assertTransaction();
        $this->lock($lockKey);

        $pattern = sprintf('^%s-[0-9]{%d}$', preg_quote($prefix, '/'), $digits);
        $sql = sprintf(
            'SELECT COALESCE(MAX(RIGHT(%s, %d)::int), 0) + 1 FROM %s WHERE %s ~ :pattern',
            $column,
            $digits,
            $table,
            $column,
        );

        $next = max($startAt, (int) $this->connection->fetchOne($sql, ['pattern' => $pattern]));
        $max = (10 ** $digits) - 1;

        if ($next < 1 || $next > $max) {
            throw new \RuntimeException(sprintf('No hay correlativos disponibles para el prefijo %s.', $prefix));
        }

        return sprintf('%s-%0'.$digits.'d', $prefix, $next);
    }

    private function acronym(string $name, int $maxLength): string
    {
        $ascii = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $name);
        $ascii = strtoupper($ascii !== false ? $ascii : $name);
        $words = preg_split('/[^A-Z0-9]+/', $ascii, -1, PREG_SPLIT_NO_EMPTY) ?: [];
        $stop = ['DE', 'DEL', 'LA', 'LAS', 'LOS', 'EN', 'CON', 'Y', 'E', 'PARA'];
        $significant = array_values(array_filter($words, static fn (string $word): bool => !in_array($word, $stop, true)));

        if ($significant === []) {
            throw new \RuntimeException('No fue posible sugerir una sigla institucional a partir del nombre.');
        }
        if (count($significant) === 1) {
            return substr($significant[0], 0, min(4, $maxLength));
        }

        $code = '';
        foreach ($significant as $word) {
            $code .= $word[0];
        }

        return substr($code, 0, $maxLength);
    }

    private function normalizeSemanticCode(string $value, int $maxLength): string
    {
        $ascii = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $value);
        $value = strtoupper($ascii !== false ? $ascii : $value);
        $value = preg_replace('/[^A-Z0-9-]+/', '-', $value) ?? '';
        $value = trim(preg_replace('/-+/', '-', $value) ?? '', '-');

        if ($value === '' || !preg_match('/^[A-Z][A-Z0-9-]*$/', $value)) {
            throw new \RuntimeException('La sigla debe iniciar con una letra y usar únicamente letras, números o guiones.');
        }
        if (strlen($value) > $maxLength) {
            throw new \RuntimeException(sprintf('La sigla admite como máximo %d caracteres.', $maxLength));
        }

        return $value;
    }

    private function codeExists(string $table, string $column, string $code): bool
    {
        $sql = sprintf('SELECT 1 FROM %s WHERE upper(%s) = upper(:code) LIMIT 1', $table, $column);

        return (bool) $this->connection->fetchOne($sql, ['code' => $code]);
    }

    private function assertTransaction(): void
    {
        if (!$this->connection->isTransactionActive()) {
            throw new \LogicException('La generación de código institucional requiere una transacción activa.');
        }
    }

    private function lock(string $key): void
    {
        $this->connection->fetchOne('SELECT pg_advisory_xact_lock(hashtext(:lock_key))', ['lock_key' => $key]);
    }

    private function alphaToNumber(string $value): int
    {
        $result = 0;
        foreach (str_split($value) as $char) {
            $result = ($result * 26) + (ord($char) - 64);
        }

        return $result;
    }

    private function numberToAlpha(int $value): string
    {
        $result = '';
        while ($value > 0) {
            --$value;
            $result = chr(65 + ($value % 26)).$result;
            $value = intdiv($value, 26);
        }

        return $result;
    }

    private function yearFromDate(string $value, string $label): int
    {
        $date = \DateTimeImmutable::createFromFormat('!Y-m-d', $value);
        if ($date === false || $date->format('Y-m-d') !== $value) {
            throw new \RuntimeException(sprintf('No fue posible generar el código: la %s no es válida.', $label));
        }

        return (int) $date->format('Y');
    }
}
