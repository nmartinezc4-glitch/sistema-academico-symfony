<?php

namespace App\Ui\UiState;

final class StatusCatalog
{
    public const MAP = [
        // Resultado
        'APROBADO' => ['label' => 'Aprobado', 'tone' => 'success'],
        'REPROBADO' => ['label' => 'Reprobado', 'tone' => 'danger'],
        'PENDIENTE' => ['label' => 'Pendiente', 'tone' => 'warning'],
        'SIN_OFERTA' => ['label' => 'Sin oferta', 'tone' => 'neutral'],
        'YA_APROBADO' => ['label' => 'Ya aprobado', 'tone' => 'info'],
        'SIN_REGISTRO' => ['label' => 'Sin registro', 'tone' => 'neutral'],
        // Período
        'PLANIFICADO' => ['label' => 'Planificado', 'tone' => 'neutral'],
        'ABIERTO' => ['label' => 'Abierto', 'tone' => 'success'],
        'CERRADO' => ['label' => 'Cerrado', 'tone' => 'info'],
        // Programa / inscripción
        'ACTIVO' => ['label' => 'Activo', 'tone' => 'success'],
        'FINALIZADO' => ['label' => 'Finalizado', 'tone' => 'info'],
        'RETIRADO' => ['label' => 'Retirado', 'tone' => 'danger'],
        'INSCRITO' => ['label' => 'Inscrito', 'tone' => 'success'],
        // Curso
        'OBLIGATORIO' => ['label' => 'Obligatorio', 'tone' => 'info'],
        'OPTATIVO' => ['label' => 'Optativo', 'tone' => 'neutral'],
    ];

    public const BLOCK_MESSAGES = [
        'PERIODO_NO_ABIERTO' => 'El período no está abierto. No es posible registrar o modificar calificaciones.',
        'ESTUDIANTE_NO_INSCRITO' => 'El estudiante no se encuentra inscrito en este período.',
        'SIN_OFERTA' => 'No existe una oferta del curso disponible para este período y sección.',
        'OFERTA_INACTIVA' => 'La oferta académica está inactiva.',
        'YA_APROBADO' => 'El curso ya fue aprobado y no requiere un nuevo intento.',
    ];

    public static function label(string $status): string
    {
        return self::MAP[$status]['label'] ?? $status;
    }

    public static function tone(string $status): string
    {
        return self::MAP[$status]['tone'] ?? 'neutral';
    }

    public static function blockMessage(string $code): string
    {
        return self::BLOCK_MESSAGES[$code] ?? 'La acción no está disponible en este contexto.';
    }
}
