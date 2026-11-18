import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';
import 'package:pronosticosapp/core/utils/forecast_format.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/domain/site_variables.dart';
import 'package:pronosticosapp/features/weather/presentation/controllers/weather_controller.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/index.dart';

class ForecastDetailPage extends StatefulWidget {
  const ForecastDetailPage({super.key});

  @override
  State<ForecastDetailPage> createState() => _ForecastDetailPageState();
}

class _ForecastDetailPageState extends State<ForecastDetailPage> {
  ForecastDay? _initial;

  @override
  void initState() {
    super.initState();
    // Los argumentos se leen una sola vez: si otra pantalla se apila encima
    // (por ejemplo "Editar"), Get.arguments pasa a ser el de esa pantalla.
    final args = Get.arguments;
    if (args is ForecastDay) {
      _initial = args;
    } else if (args is int) {
      _initial = Get.find<WeatherController>().getForecastById(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _initial;
    if (initial == null) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PucaraBackground(),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudo cargar el pronóstico',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: Get.back, child: const Text('Volver')),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Si el pronóstico se actualizó (tras editar), se muestra la versión nueva.
    final forecast = Get.find<WeatherController>().getForecastById(initial.id) ?? initial;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PucaraBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(forecast),
                  const SizedBox(height: 20),
                  _buildHeader(forecast),
                  const SizedBox(height: 24),
                  const PucaraSectionTitle(
                    title: 'Información detallada',
                    subtitle: 'Variables y métricas del pronóstico seleccionado',
                  ),
                  const SizedBox(height: 14),
                  ..._detailItems(forecast),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Set<ForecastVar>? _siteVars(String siteId) {
    final controller = Get.find<WeatherController>();
    final id = siteId.toLowerCase();
    for (final site in controller.sites) {
      if (site.id.toLowerCase() == id) {
        return SiteVariables.forSiteName(site.name, company: site.companyName);
      }
    }
    return null;
  }

  /// Variables de la faena; `null` = sin dato (se muestra "—", nunca 0).
  List<Widget> _detailItems(ForecastDay f) {
    Widget item(String title, String value, String type, {bool chart = true}) {
      return DetailItemWidget(
        title: title,
        value: value,
        type: type,
        forecast: f,
        onViewChart: _showDetailChart,
        hasChart: chart,
      );
    }

    final vars = _siteVars(f.siteId);
    bool wind(ForecastVar v, bool hasData) =>
        vars == null ? hasData : vars.contains(v);
    final windParts = <String>[
      if (wind(ForecastVar.windDir, f.windDirectionAM != null || f.windDirectionPM != null)) ...[
        'AM: ${fmtText(f.windDirectionAM)}',
        'PM: ${fmtText(f.windDirectionPM)}',
      ],
      if (wind(ForecastVar.windIntensity, f.windIntensity != null))
        'Intensidad: ${fmtNum(f.windIntensity, 'km/h')}',
      if (wind(ForecastVar.gust, f.gust != null))
        'Rachas: ${fmtNum(f.gust, 'km/h')}',
    ];

    // Faena del listado del cliente: se muestran sus variables (con "—" si no
    // hay dato). Faena desconocida: solo las que traen dato.
    final siteVars = _siteVars(f.siteId);
    bool show(ForecastVar v, bool hasData) =>
        siteVars == null ? hasData : siteVars.contains(v);

    final items = <Widget>[
      if (show(ForecastVar.temp, f.min != null || f.max != null))
        item('Temperatura mín/máx', fmtRange(f.min, f.max, '°C'), 'temperature', chart: false),
      if (show(ForecastVar.isoMinMax, f.isoMin != null || f.isoMax != null))
        item('Isoterma 0°C mín/máx', fmtRange(f.isoMin, f.isoMax, 'msnm'), 'isotherm'),
      if (show(ForecastVar.isoHeight, f.isoHeight != null))
        item('Altura de isoterma', fmtNum(f.isoHeight, 'msnm'), 'isothermHeight', chart: false),
      if (show(ForecastVar.precip, f.precipProb != null))
        item('Prob. de precipitación', fmtNum(f.precipProb, '%'), 'rain'),
      if (show(ForecastVar.electric, f.electricProb != null))
        item('Actividad eléctrica', fmtNum(f.electricProb, '%'), 'storm', chart: false),
      if (show(ForecastVar.water, f.waterMm != null))
        item('Acumulación de agua', fmtNum(f.waterMm, 'mm'), 'water', chart: false),
      if (show(ForecastVar.snow, f.snowCm != null))
        item('Acumulación de nieve', fmtNum(f.snowCm, 'cm'), 'snow', chart: false),
      if (windParts.isNotEmpty) item('Viento', windParts.join('\n'), 'wind'),
      if (show(ForecastVar.humidity, f.humidity != null))
        item('Humedad relativa', fmtNum(f.humidity, '%'), 'humidity'),
    ];
    if (items.isNotEmpty) return items;
    return const [
      PucaraPanel(
        borderRadius: 20,
        child: Text(
          'Este pronóstico no tiene variables informadas.',
          style: TextStyle(color: PucaraColors.textSecondary),
        ),
      ),
    ];
  }

  void _showDetailChart(String type, ForecastDay forecast) {
    ChartModalHandler.showDetailChart(context, type, forecast);
  }

  Widget _buildTopBar(ForecastDay forecast) {
    return Row(
      children: [
        _circleAction(
          icon: Icons.arrow_back_ios_new,
          onTap: Get.back,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalle ${forecast.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text(
                  'VARIABLES DEL PRONÓSTICO',
                  style: TextStyle(
                    color: PucaraColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ForecastUtils.formatDate(forecast.date),
                style: const TextStyle(
                  color: PucaraColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ForecastDay forecast) {
    return PucaraPanel(
      padding: const EdgeInsets.all(18),
      color: PucaraColors.surfaceStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Text(
              'RESUMEN DEL DÍA',
              style: TextStyle(
                color: PucaraColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: WeatherIconView(
                  type: forecast.icon,
                  size: 40,
                  fallback: Icon(_iconForType(forecast.icon), color: _colorForType(forecast.icon), size: 30),
                ),
              ),
              const SizedBox(width: 12),
              // "Resumen" / "Día ${forecast.day}" se quitaron: ya están el chip
              // "RESUMEN DEL DÍA" y el título "Detalle ${forecast.day}" arriba.
              const Spacer(),
              Text(
                fmtRange(forecast.min, forecast.max, '°C'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (forecast.precipProb != null)
                _statChip('Precip. ${fmtNum(forecast.precipProb, '%')}', Icons.water_drop_outlined, PucaraColors.accentBright),
              if (forecast.electricProb != null)
                _statChip('Eléctrica ${fmtNum(forecast.electricProb, '%')}', Icons.thunderstorm_outlined, const Color(0xFFFFC95B)),
              if (forecast.waterMm != null)
                _statChip('Agua ${fmtNum(forecast.waterMm, 'mm')}', Icons.opacity_outlined, const Color(0xFF59D1B7)),
              if (forecast.snowCm != null)
                _statChip('Nieve ${fmtNum(forecast.snowCm, 'cm')}', Icons.ac_unit, const Color(0xFF7CC5FF)),
              if (forecast.humidity != null)
                _statChip('Humedad ${fmtNum(forecast.humidity, '%')}', Icons.opacity_outlined, const Color(0xFF59D1B7)),
              if (forecast.windDirectionAM != null)
                _statChip('Viento AM ${forecast.windDirectionAM}', Icons.air, const Color(0xFFEAEAEA)),
              if (forecast.windDirectionPM != null)
                _statChip('Viento PM ${forecast.windDirectionPM}', Icons.air, const Color(0xFFEAEAEA)),
              if (forecast.gust != null)
                _statChip('Rachas ${fmtNum(forecast.gust, 'km/h')}', Icons.air, const Color(0xFF67D7D0)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('sun')) return Icons.wb_sunny_outlined;
    if (t.contains('cloud')) return Icons.cloud_outlined;
    if (t.contains('rain')) return Icons.grain;
    if (t.contains('storm')) return Icons.thunderstorm_outlined;
    if (t.contains('snow')) return Icons.ac_unit;
    return Icons.wb_sunny_outlined;
  }

  Color _colorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('sun')) return const Color(0xFFFFD45D);
    if (t.contains('cloud')) return const Color(0xFFEAEAEA);
    if (t.contains('rain')) return PucaraColors.accentBright;
    if (t.contains('storm')) return const Color(0xFFFFC95B);
    if (t.contains('snow')) return const Color(0xFF7CC5FF);
    return PucaraColors.accentBright;
  }

  Widget _statChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
