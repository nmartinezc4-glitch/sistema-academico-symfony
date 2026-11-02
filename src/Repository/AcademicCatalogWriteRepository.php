<?php

namespace App\Repository;

use App\Service\InstitutionalCodeGenerator;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception as DbalException;

final class AcademicCatalogWriteRepository
{
    public function __construct(
        private readonly Connection $connection,
        private readonly InstitutionalCodeGenerator $codes,
    ) {
    }

    /** @return array{id:int,code:string} */
    public function createCareer(string $name, ?string $description, ?string $codeHint = null): array
    {
        return $this->createGenerated(
            fn (): string => $this->codes->nextCareerCode($name, $codeHint),
            <<<'SQL'
            INSERT INTO sis_aca_carrera (car_codigo, car_nombre, car_descripcion, car_activo)
            VALUES (:code, :name, :description, TRUE)
            RETURNING car_id
            SQL,
            ['name' => trim($name), 'description' => $this->nullableText($description)],
            'carrera',
        );
    }

    /** @return array{id:int,code:string} */
    public function createCourse(string $name, ?string $description, ?string $prefix = null): array
    {
        return $this->createGenerated(
            fn (): string => $this->codes->nextCourseCode($name, $prefix),
            <<<'SQL'
            INSERT INTO sis_aca_curso (cur_codigo, cur_nombre, cur_descripcion, cur_activo)
            VALUES (:code, :name, :description, TRUE)
            RETURNING cur_id
            SQL,
            ['name' => trim($name), 'description' => $this->nullableText($description)],
            'curso',
        );
    }

    /** @return array{id:int,code:string} */
    public function createSection(): array
    {
        $this->connection->beginTransaction();

        try {
            $code = $this->codes->nextSectionCode();
            $id = (int) $this->connection->fetchOne(
                <<<'SQL'
                INSERT INTO sis_aca_seccion (sec_codigo, sec_nombre, sec_activo)
                VALUES (:code, :name, TRUE)
                RETURNING sec_id
                SQL,
                ['code' => $code, 'name' => 'Sección '.$code],
            );
            $this->connection->commit();

            return ['id' => $id, 'code' => $code];
        } catch (DbalException $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e, 'sección'), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    /** @param callable():string $codeFactory @param array<string,mixed> $params @return array{id:int,code:string} */
    private function createGenerated(callable $codeFactory, string $sql, array $params, string $entity): array
    {
        $this->connection->beginTransaction();

        try {
            $code = $codeFactory();
            $id = (int) $this->connection->fetchOne($sql, ['code' => $code] + $params);
            $this->connection->commit();

            return ['id' => $id, 'code' => $code];
        } catch (DbalException $e) {
            $this->connection->rollBack();
            throw new \RuntimeException($this->domainMessage($e, $entity), 0, $e);
        } catch (\Throwable $e) {
            $this->connection->rollBack();
            throw $e;
        }
    }

    private function nullableText(?string $value): ?string
    {
        $value = $value !== null ? trim($value) : null;

        return $value === '' ? null : $value;
    }

    private function domainMessage(\Throwable $e, string $entity): string
    {
        $message = strtolower($e->getMessage());

        if (str_contains($message, 'uq_car_nombre')) {
            return 'Ya existe una carrera con ese nombre.';
        }
        if (str_contains($message, 'uq_car_codigo')
            || str_contains($message, 'uq_cur_codigo')
            || str_contains($message, 'uq_sec_codigo')) {
            return 'No fue posible reservar el siguiente código institucional. Intenta nuevamente.';
        }

        return sprintf('No fue posible crear la %s. Verifica los datos e intenta nuevamente.', $entity);
    }
}
