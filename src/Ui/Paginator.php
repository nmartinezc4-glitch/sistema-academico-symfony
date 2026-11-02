<?php

namespace App\Ui;

use Symfony\Component\HttpFoundation\Request;

/**
 * Paginación real de servidor: clamp de página, slice de filas y
 * metadatos para el componente _pagination.html.twig.
 */
final class Paginator
{
    public const ALLOWED_PER_PAGE = [10, 25, 50];

    public function __construct(
        public readonly int $page,
        public readonly int $perPage,
        public readonly int $total,
    ) {
    }

    public static function fromRequest(Request $request, int $total, int $defaultPerPage = 10): self
    {
        $perPage = (int) $request->query->get('per_page', $defaultPerPage);
        if (!\in_array($perPage, self::ALLOWED_PER_PAGE, true)) {
            $perPage = $defaultPerPage;
        }
        $pages = max(1, (int) ceil($total / $perPage));
        $page = (int) $request->query->get('page', 1);
        $page = max(1, min($page, $pages));

        return new self($page, $perPage, max(0, $total));
    }

    public function pages(): int
    {
        return max(1, (int) ceil($this->total / $this->perPage));
    }

    public function offset(): int
    {
        return ($this->page - 1) * $this->perPage;
    }

    /** @param list<mixed> $rows @return list<mixed> */
    public function slice(array $rows): array
    {
        return array_slice($rows, $this->offset(), $this->perPage);
    }

    /** @return array{from:int, to:int} */
    public function range(): array
    {
        if ($this->total === 0) {
            return ['from' => 0, 'to' => 0];
        }

        return ['from' => $this->offset() + 1, 'to' => min($this->offset() + $this->perPage, $this->total)];
    }

    /** @return list<int> ventana de páginas: primera, última y hasta 5 alrededor de la actual */
    public function window(int $span = 5): array
    {
        $pages = $this->pages();
        $start = max(1, $this->page - intdiv($span, 2));
        $end = min($pages, $start + $span - 1);
        $start = max(1, $end - $span + 1);

        return range($start, $end);
    }
}
