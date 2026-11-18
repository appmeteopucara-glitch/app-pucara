# Debug Session: flutter-import-det
- **Status**: [CLOSED]
- **Issue**: El mismo archivo Excel sube correctamente en Swagger a `/api/forecasts/import/det`, pero desde la app Flutter el backend rechaza la carga o la app muestra un resultado distinto.
- **Debug Server**: http://192.168.40.40:7777/event
- **Log File**: .dbg/trae-debug-log-flutter-import-det.ndjson

## Reproduction Steps
1. Abrir la pantalla de carga masiva en la app Flutter.
2. Seleccionar el mismo archivo Excel que se probó en Swagger.
3. Subirlo con el switch `overwrite` equivalente al de Swagger.
4. Comparar request y respuesta de Flutter vs Swagger.

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | Flutter envía el archivo sin `Content-Type` Excel válido y el backend lo procesa distinto. | High | Low | Rejected |
| B | El `multipart/form-data` de Flutter envía `file`, `filename` u `overwrite` distinto a Swagger. | High | Low | Rejected |
| C | La respuesta real del backend llega bien, pero la app muestra un mensaje incorrecto por parseo. | Medium | Low | Rejected |
| D | `FilePicker` entrega bytes válidos, pero el request final armado por `MultipartRequest` no replica el de Swagger. | Medium | Medium | Rejected |
| E | La pantalla de detalle del sitio filtra o resuelve mal `siteId`, por eso no refleja los pronósticos importados. | High | Low | Confirmed |

## Log Evidence
Instrumentation added in:
- `lib/core/network/api_client.dart`
- `lib/features/weather/presentation/pages/import_forecasts_page.dart`

Observed evidence:
- Flutter importó correctamente el mismo archivo con `200 OK`.
- Respuesta backend capturada: `0 creados, 9 actualizados, 0 rechazados`.
- Respuesta backend capturada: `9 creados, 0 actualizados, 0 rechazados`.
- La diferencia restante estaba en la pantalla `weather_detail_page.dart`, donde:
  - se calculaba el pronóstico más cercano sin filtrar por sitio,
  - se comparaba `siteId` con igualdad estricta y sensible a casing.

## Verification Conclusion
Root cause confirmed in UI data resolution for site detail, not in import request.

## Resolution
`weather_detail_page.dart` filtra el pronóstico más cercano, los slots y el sitio por `siteId` comparando en minúsculas (`_todayForecast`, `_forecastSlots`, `_siteForId`, `_varsFor`). `flutter analyze` sin incidencias.
