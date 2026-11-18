import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/domain/site_variables.dart';
import 'package:pronosticosapp/features/weather/presentation/services/company_logos.dart';

/// Genera el PDF "Pronóstico extendido 7 días": una tabla por faena con el día
/// actual y los seis siguientes, con las variables que aplican a cada faena.
class ForecastPdfService {
  static const _teal = PdfColor.fromInt(0xFF1A8A99);
  static const _blue = PdfColor.fromInt(0xFF2B6CB0);
  static const _red = PdfColor.fromInt(0xFFD62828);
  static const _grey = PdfColor.fromInt(0xFF666666);
  static const _band = PdfColor.fromInt(0xFFF1F1F1);
  static const _unitColor = PdfColor.fromInt(0xFF8FA8C8);

  static const _weekdays = ['Lun.', 'Mar.', 'Mie.', 'Jue.', 'Vie.', 'Sáb.', 'Dom.'];

  final Map<String, pw.MemoryImage?> _iconCache = {};

  Future<pw.MemoryImage?> _icon(String? key) async {
    final option = WeatherIconCatalog.optionFor(key);
    if (option == null) return null;
    if (_iconCache.containsKey(option.key)) return _iconCache[option.key];
    try {
      final data = await rootBundle.load(option.asset);
      return _iconCache[option.key] = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return _iconCache[option.key] = null;
    }
  }

  static const _pucaraLogoAsset = 'assets/images/company_logos/pucara.png';

  final Map<String, pw.MemoryImage?> _logoCache = {};

  Future<pw.MemoryImage?> _logo(String? asset) async {
    if (asset == null) return null;
    if (_logoCache.containsKey(asset)) return _logoCache[asset];
    try {
      final data = await rootBundle.load(asset);
      return _logoCache[asset] = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return _logoCache[asset] = null;
    }
  }

  Future<Uint8List> build({
    required List<Site> sites,
    required List<ForecastDay> forecasts,
    DateTime? now,
  }) async {
    final today = _day(now ?? DateTime.now());
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    final byCompany = <String, List<Site>>{};
    for (final site in sites) {
      byCompany.putIfAbsent(site.companyName.isEmpty ? 'Sin compañía' : site.companyName, () => []).add(site);
    }

    // Fuente con soporte Unicode (la Helvetica integrada del PDF no lo tiene).
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    final doc = pw.Document(title: 'Pronóstico extendido 7 días', author: 'Pucará');

    final pucaraLogo = await _logo(_pucaraLogoAsset);

    for (final entry in byCompany.entries) {
      final logo = await _logo(CompanyLogos.assetFor(entry.key));
      final blocks = <pw.Widget>[];
      for (final site in entry.value) {
        blocks.add(await _siteBlock(site, entry.key, days, forecasts));
        blocks.add(pw.SizedBox(height: 14));
      }
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
          header: (_) => pw.Column(children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo grande a la izquierda; el espacio de la derecha mantiene el título centrado.
                pw.SizedBox(
                  width: 190,
                  height: 64,
                  child: logo == null
                      ? pw.SizedBox()
                      : pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        ),
                ),
                pw.Text(
                  entry.key.toUpperCase(),
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                // Logo de Pucará a la derecha, igual tamaño de columna que el de la empresa.
                pw.SizedBox(
                  width: 190,
                  height: 64,
                  child: pucaraLogo == null
                      ? pw.SizedBox()
                      : pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Image(pucaraLogo, fit: pw.BoxFit.contain),
                        ),
                ),
              ],
            ),
            pw.Text(
              'PRONÓSTICO EXTENDIDO 7 DÍAS',
              style: const pw.TextStyle(fontSize: 9, color: _grey),
            ),
            pw.SizedBox(height: 10),
          ]),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generado el ${_two(today.day)}/${_two(today.month)}/${today.year}',
                style: const pw.TextStyle(fontSize: 8, color: _grey),
              ),
              pw.Text('${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _grey)),
            ],
          ),
          build: (_) => blocks,
        ),
      );
    }

    if (byCompany.isEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (_) => pw.Center(child: pw.Text('No hay sitios para mostrar.')),
        ),
      );
    }
    return doc.save();
  }

  Future<pw.Widget> _siteBlock(
    Site site,
    String company,
    List<DateTime> days,
    List<ForecastDay> forecasts,
  ) async {
    final vars = SiteVariables.forSiteName(site.name, company: company);
    bool has(ForecastVar v) => vars?.contains(v) ?? true;

    final byDay = <String, ForecastDay>{};
    final siteId = site.id.toLowerCase();
    for (final f in forecasts) {
      if (f.siteId.toLowerCase() != siteId) continue;
      byDay[_key(f.date)] = f;
    }
    final perDay = days.map((d) => byDay[_key(d)]).toList();

    String fmt(num? v) => v == null ? '-' : (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1));

    final main = <_Row>[];
    if (has(ForecastVar.cloud)) {
      main.add(_Row.icons('Cobertura nubosa', '', [for (final f in perDay) await _icon(f?.icon)]));
    }
    if (has(ForecastVar.isoMinMax)) {
      main.add(_Row.text('Máximo nivel isoterma 0°C', 'Msnm', [for (final f in perDay) fmt(f?.isoMax)]));
      main.add(_Row.text('Mínimo nivel isoterma 0°C', 'Msnm', [for (final f in perDay) fmt(f?.isoMin)]));
    }
    if (has(ForecastVar.isoHeight)) {
      main.add(_Row.text('Altura isoterma 0°C', 'Msnm', [for (final f in perDay) fmt(f?.isoHeight)]));
    }
    if (has(ForecastVar.electric)) {
      main.add(_Row.text('Prob. de actividad eléctrica', '%', [for (final f in perDay) fmt(f?.electricProb)]));
    }
    if (has(ForecastVar.windIntensity)) {
      main.add(_Row.text('Intensidad del viento', 'km/h', [for (final f in perDay) fmt(f?.windIntensity)]));
    }
    if (has(ForecastVar.gust)) {
      main.add(_Row.text('Rachas máximas', 'km/h', [for (final f in perDay) fmt(f?.gust)]));
    }
    if (has(ForecastVar.windDir)) {
      main.add(_Row.text('Dirección del viento', '', [for (final f in perDay) _direction(f)]));
    }
    if (has(ForecastVar.temp)) {
      main.add(_Row.temp('Temperatura Mín / Máx', '°C', [for (final f in perDay) (f?.min, f?.max)]));
    }
    if (has(ForecastVar.humidity)) {
      main.add(_Row.text('Humedad relativa', '%', [for (final f in perDay) fmt(f?.humidity)]));
    }

    final rain = <_Row>[];
    if (has(ForecastVar.precip)) {
      rain.add(_Row.text('Probabilidad precipitación', '%', [for (final f in perDay) fmt(f?.precipProb)]));
    }
    if (has(ForecastVar.snow)) {
      rain.add(_Row.text('Precipitación Nieve', 'cm', [for (final f in perDay) fmt(f?.snowCm)]));
    }
    if (has(ForecastVar.water)) {
      rain.add(_Row.text('Precipitación Agua', 'mm', [for (final f in perDay) fmt(f?.waterMm)]));
    }

    // Una sola tabla por faena: el nombre como título, sus variables y a continuación las de precipitación.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [_table(site.name.toUpperCase(), days, [...main, ...rain])],
    );
  }

  String _direction(ForecastDay? f) {
    if (f == null) return '-';
    final am = f.windDirectionAM;
    final pm = f.windDirectionPM;
    if ((am == null || am.isEmpty) && (pm == null || pm.isEmpty)) return '-';
    if (pm == null || pm.isEmpty || pm == am) return am!;
    if (am == null || am.isEmpty) return pm;
    return '$am / $pm';
  }

  static const _labelWidth = 150.0;
  static const _unitWidth = 44.0;

  pw.Widget _table(String title, List<DateTime> days, List<_Row> rows) {
    return pw.Column(children: [
      _line(
        pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _teal)),
        pw.SizedBox(),
        [
          for (final d in days)
            pw.Text(
              '${_weekdays[d.weekday - 1]} ${_two(d.day)}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _teal),
            ),
        ],
        height: 20,
      ),
      for (var i = 0; i < rows.length; i++) _dataRow(rows[i], shaded: i.isOdd),
    ]);
  }

  pw.Widget _dataRow(_Row row, {required bool shaded}) {
    final cells = <pw.Widget>[];
    for (var i = 0; i < 7; i++) {
      if (row.icons != null) {
        final img = row.icons![i];
        cells.add(img == null ? pw.Text('-', style: const pw.TextStyle(fontSize: 9)) : pw.Image(img, width: 26, height: 26));
      } else if (row.temps != null) {
        final (mn, mx) = row.temps![i];
        String n(num? v) => v == null ? '-' : (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1));
        // Rojo para temperaturas sobre 0, azul para temperaturas iguales o bajo 0.
        PdfColor colorFor(num? v) => (v != null && v > 0) ? _red : _blue;
        cells.add(
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 9),
              children: [
                pw.TextSpan(text: n(mn), style: pw.TextStyle(color: colorFor(mn))),
                const pw.TextSpan(text: ' / '),
                pw.TextSpan(text: n(mx), style: pw.TextStyle(color: colorFor(mx))),
              ],
            ),
          ),
        );
      } else {
        cells.add(pw.Text(row.values![i], style: const pw.TextStyle(fontSize: 9)));
      }
    }
    return _line(
      pw.Text(row.label, style: const pw.TextStyle(fontSize: 9)),
      pw.Text(row.unit, style: const pw.TextStyle(fontSize: 8, color: _unitColor)),
      cells,
      height: row.icons != null ? 34 : 18,
      shaded: shaded,
    );
  }

  pw.Widget _line(pw.Widget label, pw.Widget unit, List<pw.Widget> cells, {double height = 18, bool shaded = false}) {
    return pw.Container(
      height: height,
      color: shaded ? _band : null,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: _labelWidth, child: label),
          pw.SizedBox(width: _unitWidth, child: pw.Align(alignment: pw.Alignment.centerRight, child: unit)),
          pw.SizedBox(width: 8),
          for (final c in cells) pw.Expanded(child: pw.Center(child: c)),
        ],
      ),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
  static String _two(int v) => v.toString().padLeft(2, '0');
}

class _Row {
  final String label;
  final String unit;
  final List<String>? values;
  final List<pw.MemoryImage?>? icons;
  final List<(double?, double?)>? temps;

  _Row.text(this.label, this.unit, this.values) : icons = null, temps = null;
  _Row.icons(this.label, this.unit, this.icons) : values = null, temps = null;
  _Row.temp(this.label, this.unit, this.temps) : values = null, icons = null;
}
