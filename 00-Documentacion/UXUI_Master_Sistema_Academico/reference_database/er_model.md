# Modelo ER — Sistema Académico (SIS_ACA)

Fuente: estructura E1 (`database/01_schema.sql` + `02_constraints.sql`). Todas las relaciones son 1:N obligatorias del lado hijo (FK `NOT NULL`, `ON DELETE RESTRICT`).

## 1. ER conceptual

Dos ejes que no se mezclan. El **currículo** responde *dónde va el curso en el pensum*; el **calendario** responde *cuándo se cursó*. Se cruzan en la oferta y en el resultado.

```mermaid
flowchart LR
    subgraph CURRICULO["Currículo (dónde)"]
        CAR[Carrera] --> PEN[Pensum]
        PEN --> PCU[Pensum-Curso]
        CUR[Curso] --> PCU
        CIC[Ciclo curricular] --> PCU
    end
    subgraph CALENDARIO["Calendario (cuándo)"]
        POL[Política académica] --> PER[Período]
        ANL[Año lectivo] --> PER
    end
    subgraph ESTUDIANTE_["Trayectoria del estudiante"]
        EST[Estudiante] --> EPR[Estudiante-Programa]
        EPR --> EPE[Estudiante-Período]
        EPE --> RES[Resultado]
    end
    PEN --> EPR
    PER --> EPE
    CIC --> EPE
    SEC[Sección] --> EPE
    PCU --> OFE[Oferta de curso]
    PER --> OFE
    SEC --> OFE
    OFE --> RES
```

## 2. ER lógico (PK / FK / UK)

```mermaid
erDiagram
    SIS_ACA_POLITICA_ACADEMICA  ||--o{ SIS_ACA_PERIODO_ACADEMICO   : "evalua (PER_POL_ID)"
    SIS_ACA_ANIO_LECTIVO        ||--o{ SIS_ACA_PERIODO_ACADEMICO   : "contiene (PER_ANL_ID)"
    SIS_ACA_CARRERA             ||--o{ SIS_ACA_PENSUM              : "versiona (PEN_CAR_ID)"
    SIS_ACA_PENSUM              ||--o{ SIS_ACA_PENSUM_CURSO        : "incluye (PCU_PEN_ID)"
    SIS_ACA_CURSO               ||--o{ SIS_ACA_PENSUM_CURSO        : "se ubica (PCU_CUR_ID)"
    SIS_ACA_CICLO_CURRICULAR    ||--o{ SIS_ACA_PENSUM_CURSO        : "posiciona (PCU_CIC_ID)"
    SIS_ACA_ESTUDIANTE          ||--o{ SIS_ACA_ESTUDIANTE_PROGRAMA : "se inscribe (EPR_EST_ID)"
    SIS_ACA_PENSUM              ||--o{ SIS_ACA_ESTUDIANTE_PROGRAMA : "rige (EPR_PEN_ID)"
    SIS_ACA_ESTUDIANTE_PROGRAMA ||--o{ SIS_ACA_ESTUDIANTE_PERIODO  : "cursa (EPE_EPR_ID)"
    SIS_ACA_PERIODO_ACADEMICO   ||--o{ SIS_ACA_ESTUDIANTE_PERIODO  : "en (EPE_PER_ID)"
    SIS_ACA_CICLO_CURRICULAR    ||--o{ SIS_ACA_ESTUDIANTE_PERIODO  : "ubica (EPE_CIC_ID)"
    SIS_ACA_SECCION             ||--o{ SIS_ACA_ESTUDIANTE_PERIODO  : "asigna (EPE_SEC_ID)"
    SIS_ACA_PERIODO_ACADEMICO   ||--o{ SIS_ACA_OFERTA_CURSO        : "oferta (OFE_PER_ID)"
    SIS_ACA_PENSUM_CURSO        ||--o{ SIS_ACA_OFERTA_CURSO        : "imparte (OFE_PCU_ID)"
    SIS_ACA_SECCION             ||--o{ SIS_ACA_OFERTA_CURSO        : "en (OFE_SEC_ID)"
    SIS_ACA_ESTUDIANTE_PERIODO  ||--o{ SIS_ACA_RESULTADO_CURSO     : "obtiene (RES_EPE_ID)"
    SIS_ACA_OFERTA_CURSO        ||--o{ SIS_ACA_RESULTADO_CURSO     : "califica (RES_OFE_ID)"

    SIS_ACA_POLITICA_ACADEMICA {
        int POL_ID PK
        varchar POL_CODIGO UK
        numeric POL_NOTA_APROBACION
        date POL_VIGENTE_DESDE UK
    }
    SIS_ACA_ANIO_LECTIVO {
        int ANL_ID PK
        smallint ANL_ANIO UK
        varchar ANL_ESTADO
    }
    SIS_ACA_PERIODO_ACADEMICO {
        int PER_ID PK
        int PER_ANL_ID FK "UK con PER_NUMERO"
        smallint PER_NUMERO
        int PER_POL_ID FK "vigente en PER_FECHA_INICIO (T3)"
        varchar PER_ESTADO "CERRADO bloquea RES (T2)"
    }
    SIS_ACA_CARRERA {
        int CAR_ID PK
        varchar CAR_CODIGO UK
        varchar CAR_NOMBRE UK
    }
    SIS_ACA_PENSUM {
        int PEN_ID PK
        int PEN_CAR_ID FK "UK con PEN_VERSION"
        varchar PEN_CODIGO UK
        smallint PEN_VERSION
    }
    SIS_ACA_CICLO_CURRICULAR {
        int CIC_ID PK
        smallint CIC_ANIO "UK con CIC_SEMESTRE"
        smallint CIC_SEMESTRE
    }
    SIS_ACA_CURSO {
        int CUR_ID PK
        varchar CUR_CODIGO UK
    }
    SIS_ACA_PENSUM_CURSO {
        int PCU_ID PK
        int PCU_PEN_ID FK "UK con PCU_CUR_ID"
        int PCU_CUR_ID FK
        int PCU_CIC_ID FK
        boolean PCU_OBLIGATORIO
    }
    SIS_ACA_SECCION {
        int SEC_ID PK
        varchar SEC_CODIGO UK
    }
    SIS_ACA_ESTUDIANTE {
        int EST_ID PK
        varchar EST_CODIGO UK
        varchar EST_FOTO_RUTA UK
    }
    SIS_ACA_ESTUDIANTE_PROGRAMA {
        int EPR_ID PK
        int EPR_EST_ID FK "1 ACTIVO por estudiante"
        int EPR_PEN_ID FK "congelado con RES (T4)"
        varchar EPR_ESTADO
    }
    SIS_ACA_ESTUDIANTE_PERIODO {
        int EPE_ID PK
        int EPE_EPR_ID FK "UK con EPE_PER_ID"
        int EPE_PER_ID FK
        int EPE_CIC_ID FK
        int EPE_SEC_ID FK
    }
    SIS_ACA_OFERTA_CURSO {
        int OFE_ID PK
        int OFE_PER_ID FK "UK PER+PCU+SEC"
        int OFE_PCU_ID FK
        int OFE_SEC_ID FK
    }
    SIS_ACA_RESULTADO_CURSO {
        int RES_ID PK
        int RES_EPE_ID FK "UK con RES_OFE_ID"
        int RES_OFE_ID FK
        numeric RES_NOTA "NULL = PENDIENTE; EPE/OFE inmutables"
    }
```

## 3. Reglas que el diagrama no muestra

| Regla | Dónde se garantiza |
|---|---|
| Carrera del estudiante = carrera del pensum | Por construcción: no existe columna de carrera en EPR (H1) |
| Resultado: mismo período, mismo pensum, misma sección | T2 (SA201–SA203) |
| Resultados mutables solo con período ABIERTO, estudiante INSCRITO y oferta activa (INSERT/UPDATE/DELETE) | T2 (SA204, SA205, SA206) |
| Sin nuevo intento de un curso ya aprobado en un período anterior | T2 (SA207) |
| Período usa la política vigente en su inicio; política usada inmutable | T3 (SA301–SA305) |
| Contexto académico congelado si hay dependencias (8 tablas: EPR, EPE, OFE, PCU, PEN, PER, ANL, CIC) e identidad de RES inmutable | T4 (SA401) |
| Estado APROBADO/REPROBADO/PENDIENTE | Derivado en vistas, nunca almacenado |
