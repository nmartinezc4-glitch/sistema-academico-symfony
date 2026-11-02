<?php

namespace App\Twig;

use App\Ui\UiState\StatusCatalog;
use Twig\Extension\AbstractExtension;
use Twig\TwigFunction;

final class UiExtension extends AbstractExtension
{
    public function getFunctions(): array
    {
        return [
            new TwigFunction('status_label', [StatusCatalog::class, 'label']),
            new TwigFunction('status_tone', [StatusCatalog::class, 'tone']),
            new TwigFunction('block_message', [StatusCatalog::class, 'blockMessage']),
        ];
    }
}
