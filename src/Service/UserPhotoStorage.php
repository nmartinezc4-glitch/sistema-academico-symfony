<?php

namespace App\Service;

use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpKernel\KernelInterface;

final class UserPhotoStorage
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

        $directory = $this->kernel->getProjectDir().'/public/uploads/users';
        if (!is_dir($directory) && !mkdir($directory, 0775, true) && !is_dir($directory)) {
            throw new \RuntimeException('No fue posible preparar el directorio de fotografías de usuarios.');
        }

        $filename = 'user-'.bin2hex(random_bytes(8)).'.'.$extension;

        try {
            $file->move($directory, $filename);
        } catch (\Throwable $e) {
            throw new \RuntimeException('No fue posible guardar la fotografía del usuario.', 0, $e);
        }

        return '/uploads/users/'.$filename;
    }

    public function delete(?string $publicPath): void
    {
        if ($publicPath === null || !str_starts_with($publicPath, '/uploads/users/')) {
            return;
        }

        $fullPath = $this->kernel->getProjectDir().'/public/uploads/users/'.basename($publicPath);
        if (is_file($fullPath)) {
            @unlink($fullPath);
        }
    }

    private function detectMimeType(UploadedFile $file): string
    {
        if (!class_exists(\finfo::class)) {
            throw new \RuntimeException('El servidor no tiene Fileinfo disponible para validar fotografías.');
        }

        $detector = new \finfo(FILEINFO_MIME_TYPE);
        $mime = $detector->file($file->getPathname());

        return is_string($mime) ? strtolower(trim($mime)) : '';
    }
}
