<?php

namespace App\Service\Export;

use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;

/**
 * Exportación sencilla para usuarios académicos.
 *
 * Una sola hoja, sin nombres de tablas, vistas, frameworks ni metadatos técnicos.
 * El archivo contiene únicamente contexto útil, encabezados comprensibles y datos.
 */
final class SimpleReportXlsxWriter
{
    private const PAPER = 'F6F1E8';
    private const PAPER_SOFT = 'FBF8F2';
    private const INK = '342D29';
    private const INK_SOFT = '6F655F';
    private const LINE = 'DED5C9';
    private const BURGUNDY = '793B46';
    private const TERRACOTTA = 'C86F50';

    /**
     * @param list<array{key:string,label:string}> $columns
     * @param list<array<string,mixed>> $rows
     * @param array<string,string> $context
     */
    public function write(
        string $title,
        string $fileName,
        array $columns,
        array $rows,
        array $context = [],
    ): string {
        $book = new Spreadsheet();
        $sheet = $book->getActiveSheet();
        $sheet->setTitle('Reporte');
        $lastColumn = $this->columnLetter(max(1, \count($columns)));

        $sheet->mergeCells("A1:{$lastColumn}1");
        $sheet->setCellValue('A1', $title);
        $sheet->getStyle('A1')->applyFromArray([
            'font' => ['name' => 'Georgia', 'bold' => true, 'size' => 18, 'color' => ['rgb' => self::BURGUNDY]],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => self::PAPER]],
        ]);
        $sheet->getRowDimension(1)->setRowHeight(30);

        $contextRow = 3;
        if ($context === []) {
            $context = ['Alcance' => 'Todos los registros disponibles'];
        }
        foreach ($context as $label => $value) {
            if ($value === '') {
                continue;
            }
            $sheet->setCellValue("A{$contextRow}", $label);
            $sheet->setCellValue("B{$contextRow}", $value);
            $sheet->getStyle("A{$contextRow}")->getFont()->setBold(true)->setColor(new \PhpOffice\PhpSpreadsheet\Style\Color(self::INK_SOFT));
            ++$contextRow;
        }

        $headerRow = $contextRow + 1;
        foreach ($columns as $index => $column) {
            $cell = $this->columnLetter($index + 1).$headerRow;
            $sheet->setCellValue($cell, $column['label']);
        }
        $sheet->getStyle("A{$headerRow}:{$lastColumn}{$headerRow}")->applyFromArray([
            'font' => ['name' => 'Calibri', 'bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => self::INK]],
            'borders' => ['bottom' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => self::TERRACOTTA]]],
        ]);

        $rowNumber = $headerRow + 1;
        foreach ($rows as $row) {
            foreach ($columns as $index => $column) {
                $value = $row[$column['key']] ?? '—';
                if ($value === null || $value === '') {
                    $value = '—';
                }
                $sheet->setCellValue($this->columnLetter($index + 1).$rowNumber, $value);
            }
            if (($rowNumber - $headerRow) % 2 === 0) {
                $sheet->getStyle("A{$rowNumber}:{$lastColumn}{$rowNumber}")
                    ->getFill()
                    ->setFillType(Fill::FILL_SOLID)
                    ->getStartColor()
                    ->setRGB(self::PAPER_SOFT);
            }
            ++$rowNumber;
        }

        $lastRow = max($headerRow, $rowNumber - 1);
        $sheet->getStyle("A{$headerRow}:{$lastColumn}{$lastRow}")->getBorders()->getAllBorders()
            ->setBorderStyle(Border::BORDER_THIN)
            ->getColor()->setRGB(self::LINE);

        foreach (range(1, \count($columns)) as $index) {
            $sheet->getColumnDimension($this->columnLetter($index))->setAutoSize(true);
        }
        $sheet->freezePane('A'.($headerRow + 1));
        if ($rows !== []) {
            $sheet->setAutoFilter("A{$headerRow}:{$lastColumn}{$lastRow}");
        }
        $sheet->setShowGridLines(false);
        $sheet->getPageSetup()->setOrientation('landscape')->setFitToWidth(1)->setFitToHeight(0);

        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '_', $fileName) ?: 'reporte';
        $path = sys_get_temp_dir().'/'.$safeName.'.xlsx';
        IOFactory::createWriter($book, 'Xlsx')->save($path);
        $book->disconnectWorksheets();

        return $path;
    }

    private function columnLetter(int $number): string
    {
        $letter = '';
        while ($number > 0) {
            $number--;
            $letter = chr(65 + ($number % 26)).$letter;
            $number = intdiv($number, 26);
        }

        return $letter;
    }
}
