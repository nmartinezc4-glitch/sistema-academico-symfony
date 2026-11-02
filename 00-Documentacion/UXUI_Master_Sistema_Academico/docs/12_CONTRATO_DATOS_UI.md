# 12 — Contrato de Datos de UI y Binding Futuro

Twig consume ViewModels, no tablas.

## StudentSummaryViewModel
id EST_ID; code EST_CODIGO; names EST_NOMBRES/APELLIDOS; birthDate; photoPath; active; currentProgram EPR; curriculum PEN; career CAR; progress VW_AVANCE_PENSUM.

## StudentPeriodViewModel
epeId, year, term, cycle, section, enrollmentStatus.

## GradeEntryRowViewModel
Futura `VW_INGRESO_NOTAS`: epeId, curriculumCourseId, course, required, origin, offeringId, offeringActive, grade, status, editable, blockReason, lastAttempt.

## ResultRowViewModel
Futura `VW_RESULTADO_ESTUDIANTE`: resultId, period, course, section, grade, status, attempt, passingGrade.

## CurriculumViewModel
curriculum, career, cycles[], cycle.courses[] con PCU_ID/order/required/course.

## ProgressViewModel
`VW_AVANCE_PENSUM` y `VW_AVANCE_CICLO`: required, approved, pending, percentage, perCycle.

## ReportGradeRow
`VW_REPORTE_NOTAS`: student, career, course, section, period, grade/status, attempt.

No exponer IDs técnicos como información visible salvo códigos legibles.

Campos demo sin soporte deben marcarse `uiOnly`.
