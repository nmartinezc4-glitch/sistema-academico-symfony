<?php

namespace App\Service;

use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpKernel\KernelInterface;

final class StudentPhotoStorage
{
    private const MAX_BYTES = 2 * 1024 * 1024;

    private const EXTENSIONS = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];

    public function __construct(private readonly KernelInterface $kernel)
    {
    }

    public function store(UploadedFile $file): string
    {
        if (!$file->isValid()) {
            throw new \RuntimeException('La fotografía no pudo cargarse correctamente.');
        }

        $size = $file->getSize();
        if ($size === null || $size <= 0 || $size > self::MAX_BYTES) {
            throw new \RuntimeException('La fotografía debe pesar como máximo 2 MB.');
        }

        $mime = $this->detectMimeType($file);
        $extension = self::EXTENSIONS[$mime] ?? null;
        if ($extension === null) {
            throw new \RuntimeException('La fotografía debe ser JPG, PNG o WEBP.');
        }

        $directory = $this->kernel->getProjectDir().'/public/uploads/students';
        if (!is_dir($directory) && !mkdir($directory, 0775, true) && !is_dir($directory)) {
            throw new \RuntimeException('No fue posible preparar el directorio de fotografías.');
        }

        $filename = 'student-'.bin2hex(random_bytes(8)).'.'.$extension;

        try {
            $file->move($directory, $filename);
        } catch (\Throwable $e) {
            throw new \RuntimeException('No fue posible guardar la fotografía.', 0, $e);
        }

        return '/uploads/students/'.$filename;
    }

    private function detectMimeType(UploadedFile $file): string
    {
        if (!class_exists(\finfo::class)) {
            throw new \RuntimeException('El servidor no tiene disponible la extensión Fileinfo para validar fotografías.');
        }

        try {
            $detector = new \finfo(FILEINFO_MIME_TYPE);
            $mime = $detector->file($file->getPathname());
        } catch (\Throwable $e) {
            throw new \RuntimeException('No fue posible validar el tipo de la fotografía.', 0, $e);
        }

        return is_string($mime) ? strtolower(trim($mime)) : '';
    }

    public function delete(?string $publicPath): void
    {
        if ($publicPath === null || !str_starts_with($publicPath, '/uploads/students/')) {
            return;
        }

        $filename = basename($publicPath);
        $fullPath = $this->kernel->getProjectDir().'/public/uploads/students/'.$filename;
        if (is_file($fullPath)) {
            @unlink($fullPath);
        }
    }
}
