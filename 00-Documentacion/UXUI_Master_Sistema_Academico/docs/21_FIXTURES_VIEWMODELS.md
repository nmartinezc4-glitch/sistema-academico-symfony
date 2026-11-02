# 21 — Contrato de Fixtures y ViewModels

## 1. Problema que resuelve

Si cada controller inventa nombres, carreras y notas, las pantallas se contradicen: un estudiante puede tener 61% en perfil y 76% en expediente. V1 debe comportarse como una aplicación coherente aunque no exista BD.

## 2. Fuente canónica

`DemoDataProvider` o equivalente debe tener una fuente única de:
- estudiantes;
- carreras;
- pensums;
- ciclos;
- períodos;
- cursos;
- resultados;
- report metrics.

No duplicar objetos.

## 3. Identidad de demo

Se recomienda preservar casos memorables del dataset real aprobado cuando estén disponibles:
- `STU-2025-0003` Carla para repitencia/borde;
- códigos MAT/PRO/WEB consistentes.

Pero no es necesario copiar 708 resultados en PHP. Crear un subconjunto visual coherente.

## 4. Determinismo

Fixtures no usan `random()` en cada request. Deben producir exactamente la misma pantalla para pruebas visuales.

## 5. Formato de ViewModel

Preferible DTO readonly o arrays documentados. Ejemplo:

```php
[
  'student' => [
    'id' => 3,
    'code' => 'STU-2025-0003',
    'fullName' => 'Carla Andrea Pérez Gómez',
    'photo' => null,
    'status' => 'ACTIVA',
  ],
  'program' => [...],
  'progress' => [...],
]
```

## 6. Valor vs label

Conservar valores canónicos y labels separados cuando aplique:
`status = APROBADO`, `statusLabel = Aprobado`.

## 7. Fechas

El fixture puede usar `DateTimeImmutable`; Twig formatea con locale futuro. No guardar fecha ya formateada si luego se reutiliza.

## 8. Porcentajes

Guardar `61.0`, no `"61 %"`. El ViewModel puede contener numeric y Twig aplicar formatting.

## 9. Gráficos

Datos de chart deben derivarse del mismo fixture tabular, no dos números contradictorios escritos a mano.

## 10. Estados de pruebas

Crear fixtures explícitos:
- normal;
- empty;
- blocked;
- withdrawn;
- noPhoto;
- noPeriod;
- complete;
- historical.

Poder activar por query de desarrollo (`?scenario=empty`) es opcional y útil.

## 11. Migración V2

Application Service generará el mismo ViewModel. Esto permite reemplazar provider sin tocar Twig.
