# Debug Session: import-success-mismatch
- **Status**: [CLOSED]
- **Issue**: Swagger muestra que `/api/forecasts/import/det` procesa el Excel correctamente, pero en la app el resultado visible indica que no se subieron o los pronósticos no aparecen reflejados.
- **Debug Server**: Pending
- **Log File**: .dbg/trae-debug-log-import-success-mismatch.ndjson

## Reproduction Steps
1. Abrir la pantalla de carga masiva en la app.
2. Seleccionar un Excel válido.
3. Subirlo usando `/api/forecasts/import/det`.
4. Comparar el resultado mostrado en Swagger vs lo que muestra la app y el listado de pronósticos.

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | El import responde éxito, pero `fetchForecasts()` no trae los datos recién actualizados. | High | Low | Pending |
| B | La app refresca datos, pero descarta registros por mapeo de `siteId` o por fecha. | High | Medium | Pending |
| C | El backend nuevo responde con una forma distinta y la app cae en mensaje genérico o interpreta mal el resultado. | Medium | Low | Pending |
| D | La lista consultada por la app usa otra fuente o filtro y por eso no refleja lo importado desde `/import/det`. | Medium | Medium | Pending |

## Log Evidence
Pending

## Verification Conclusion
Mismo origen que `debug-flutter-import-det.md`: el import funcionaba y la pantalla de detalle no resolvía bien `siteId` (sin filtro por sitio y con igualdad sensible a mayúsculas). Corregido en `weather_detail_page.dart` con comparación case-insensitive.
