<?php

namespace App\Service\Report;

use Symfony\Component\HttpFoundation\Request;

final class ReportFilterSet
{
    /**
     * Única traducción HTTP -> filtros de dominio para reportes, vista previa
     * y Excel. Esto evita que cada endpoint interprete parámetros de forma
     * diferente.
     *
     * @return array{
     *   periodo:string,
     *   carrera:string,
     *   curso:string,
     *   seccion:string,
     *   estado:string,
     *   alerta:string,
     *   pensum:string,
     *   ciclo:string,
     *   q:string
     * }
     */
    public function fromRequest(Request $request): array
    {
        return [
            'periodo' => $this->value($request, 'periodo'),
            'carrera' => $this->value($request, 'carrera', 'career'),
            'curso' => $this->value($request, 'curso'),
            'seccion' => $this->value($request, 'seccion'),
            'estado' => mb_strtoupper($this->value($request, 'estado', 'status')),
            'alerta' => mb_strtoupper($this->value($request, 'alerta')),
            'pensum' => $this->value($request, 'pensum', 'curriculum'),
            'ciclo' => $this->value($request, 'ciclo'),
            'q' => $this->value($request, 'q'),
        ];
    }

    private function value(Request $request, string $key, ?string $alias = null): string
    {
        $value = trim((string) $request->query->get($key, ''));

        if ($value === '' && $alias !== null) {
            $value = trim((string) $request->query->get($alias, ''));
        }

        return $value;
    }
}
