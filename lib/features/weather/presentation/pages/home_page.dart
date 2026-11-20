import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';
import 'package:pronosticosapp/core/utils/forecast_format.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/domain/site_variables.dart';
import 'package:pronosticosapp/features/weather/domain/entities/weather.dart';
import 'package:pronosticosapp/features/weather/presentation/controllers/weather_controller.dart';
import 'package:pronosticosapp/features/weather/presentation/services/forecast_pdf_service.dart';
import 'package:printing/printing.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WeatherController controller;
  bool _snackbarShown = false;
  bool _downloadingPdf = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(WeatherController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_snackbarShown &&
          Get.arguments is Map &&
          (Get.arguments as Map).containsKey('snackbar')) {
        final message = (Get.arguments as Map)['snackbar'] as String;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        _snackbarShown = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PucaraBackground(),
          SafeArea(
            child: Obx(() {
              final companyName = controller.selectedCompanyName.value.isNotEmpty
                  ? controller.selectedCompanyName.value
                  : (controller.sites.isNotEmpty
                      ? controller.sites.first.companyName
                      : 'Pucará');
              final noCompanies = controller.companyCount.value == 0;
              final hasWeather = controller.weatherList.isNotEmpty;
              final hasSites = controller.sites.isNotEmpty;
              final errorMessage = controller.errorMessage.value;

              return RefreshIndicator(
                onRefresh: () async => controller.refreshWeatherData(),
                color: PucaraColors.accentBright,
                backgroundColor: PucaraColors.surfaceStrong,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildHeader(
                        context,
                        companyName,
                        subtitle: hasSites
                            ? 'Selecciona un sitio para continuar'
                            : (noCompanies
                                ? 'Tu usuario no tiene empresas asignadas'
                                : 'No tienes meteorología asignada o creada todavía'),
                      ),
                    ),
                    if (controller.isLoading.value && !hasWeather)
                      _buildStateView(
                        icon: Icons.cloud_sync_outlined,
                        title: 'Cargando sitios',
                        message:
                            'Estamos actualizando la información meteorológica.',
                      )
                    else if (!hasWeather)
                      _buildStateView(
                        icon: hasSites
                            ? Icons.cloud_off_outlined
                            : Icons.location_off_outlined,
                        title: hasSites
                            ? 'Aún no hay meteorología cargada'
                            : (noCompanies
                                ? 'Sin empresas asignadas'
                                : 'No tienes meteorología asignada'),
                        message: hasSites
                            ? 'Tus sitios están visibles, pero todavía no tienen información meteorológica cargada.'
                            : (noCompanies
                                ? 'Un administrador debe asignarte al menos una empresa para que veas tus faenas.'
                                : 'Cuando te asignen un sitio o se cree meteorología, aparecerá aquí sin bloquear el menú.'),
                        action: PucaraPrimaryButton(
                          label: 'REINTENTAR',
                          onPressed: controller.refreshWeatherData,
                        ),
                      )
                    else ...[
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildInlineNotice(errorMessage),
                        ),
                      ...List.generate(controller.weatherList.length, (index) {
                        final weather = controller.weatherList[index];
                        return FadeInLeftBig(
                          duration: const Duration(milliseconds: 450),
                          delay: Duration(milliseconds: 70 * (index + 1)),
                          child: _buildWeatherCard(weather, index),
                        );
                      }),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String companyName, {
    required String subtitle,
  }) {
    final sitesCount = controller.sites.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: PucaraBrand(
                size: 92,
                compact: true,
                showTagline: false,
                textAlign: TextAlign.left,
              ),
            ),
            _headerIconButton(
              icon: Icons.refresh,
              onTap: controller.refreshWeatherData,
            ),
            const SizedBox(width: 10),
            _headerIconButton(
              icon: Icons.person_outline,
              onTap: () => Get.toNamed(AppRoutes.account),
            ),
            const SizedBox(width: 10),
            _headerIconButton(
              icon: Icons.logout,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Text(
            'PANEL OPERATIVO',
            style: TextStyle(
              color: PucaraColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'MIS SITIOS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          companyName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: PucaraColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _headerInfoChip(
                label: 'Sitios',
                value: '$sitesCount',
                color: PucaraColors.accentBright,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _downloadButton()),
          ],
        ),
        if (controller.companyCount.value > 1) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _changeCompany,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Cambiar empresa'),
          ),
        ],
      ],
    );
  }

  Future<void> _changeCompany() async {
    final changed = await Get.toNamed(AppRoutes.selectCompany, arguments: {'fromHome': true});
    if (changed == true) controller.refreshWeatherData();
  }

  Widget _buildWeatherCard(Weather weather, int index) {
    final site = _siteForIndex(index);
    final siteId = controller.siteIdForIndex(index);
    final nearestForecast = controller.nearestForecastForSite(siteId);
    final hasForecast = nearestForecast != null;
    final displayMin = hasForecast ? nearestForecast.min : weather.minTemperature;
    final displayMax = hasForecast ? nearestForecast.max : weather.maxTemperature;
    // El número grande es la temperatura actual, no la máxima: si no, se repite
    // con la tarjeta "Máxima" de abajo. Con pronóstico, se promedia mín/máx.
    final displayTemperature = hasForecast
        ? _average(displayMin, displayMax)
        : weather.temperature;
    final displayWind = hasForecast
        ? (nearestForecast.windIntensity ?? nearestForecast.gust)
        : weather.windSpeed;
    final statusText = hasForecast
        ? WeatherIconCatalog.labelFor(nearestForecast.icon)
        : 'Sin pronóstico';
    // Variables que aplican a la faena (null = todas).
    final vars = SiteVariables.forSiteName(site?.name, company: site?.companyName);
    bool has(ForecastVar v) => vars?.contains(v) ?? true;
    final showTemp = has(ForecastVar.temp);
    final showWind = has(ForecastVar.windIntensity) || has(ForecastVar.gust);

    return PucaraPanel(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: InkWell(
        onTap: () async {
          await Get.toNamed(
            AppRoutes.weatherDetail,
            arguments: {'cityId': weather.id, 'siteId': siteId},
          );
          if (!mounted) return;
          controller.fetchForecasts();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: WeatherIconView(
                      type: nearestForecast?.icon ?? weather.iconCode,
                      size: 40,
                      fallback: Icon(
                        _iconForDescription(weather.description),
                        color: PucaraColors.accentBright,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'SITIO',
                            style: TextStyle(
                              color: PucaraColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          site?.name ?? weather.cityName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // La compañía ya se muestra en el encabezado de "Mis sitios":
                          // repetirla en cada tarjeta es redundante, se usa la dirección.
                          (site != null && site.address.isNotEmpty)
                              ? site.address
                              : weather.description,
                          style: const TextStyle(
                            color: PucaraColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showTemp) ...[
                        Text(
                          _deg(displayTemperature, hasForecast, unit: 'C'),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: PucaraColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (showTemp) ...[
                _buildTempBar(
                  min: displayMin ?? displayTemperature ?? 0,
                  max: displayMax ?? displayTemperature ?? 0,
                  current: displayTemperature ?? displayMin ?? 0,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: _metricTiles(
                  forecast: nearestForecast,
                  showTemp: showTemp,
                  showWind: showWind,
                  has: has,
                  min: displayMin,
                  max: displayMax,
                  wind: displayWind,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    hasSite(site)
                        ? 'Abrir dashboard del sitio'
                        : 'Abrir detalle del pronóstico',
                    style: const TextStyle(
                      color: PucaraColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PucaraPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: PucaraColors.accentBright),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: PucaraColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 20), action],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineNotice(String message) {
    return PucaraPanel(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      color: PucaraColors.surfaceStrong,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: PucaraColors.accentBright),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PucaraColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mínima/Máxima/Viento si la faena los lleva; si no, sus variables de precipitación.
  List<Widget> _metricTiles({
    required ForecastDay? forecast,
    required bool showTemp,
    required bool showWind,
    required bool Function(ForecastVar) has,
    required double? min,
    required double? max,
    required double? wind,
  }) {
    final hasForecast = forecast != null;
    final tiles = <Widget>[];
    void add(String label, String value, Color color) {
      if (tiles.isNotEmpty) tiles.add(const SizedBox(width: 10));
      tiles.add(Expanded(child: _metricTile(label: label, value: value, color: color)));
    }

    if (showTemp) {
      add('Mínima', _deg(min, hasForecast, unit: 'C'), PucaraColors.accentBright);
      add('Máxima', _deg(max, hasForecast, unit: 'C'), const Color(0xFFFF6A5A));
    }
    if (showWind) {
      add('Viento', hasForecast && wind != null ? '${wind.toStringAsFixed(0)} km/h' : '--', const Color(0xFF67D7D0));
    }
    if (!showTemp && !showWind) {
      if (has(ForecastVar.precip)) {
        add('Precip.', hasForecast ? fmtNum(forecast.precipProb, '%') : '--', PucaraColors.accentBright);
      }
      if (has(ForecastVar.water)) {
        add('Agua', hasForecast ? fmtNum(forecast.waterMm, 'mm') : '--', const Color(0xFF59D1B7));
      }
      if (has(ForecastVar.snow)) {
        add('Nieve', hasForecast ? fmtNum(forecast.snowCm, 'cm') : '--', const Color(0xFF7CC5FF));
      }
    }
    return tiles;
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: PucaraColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: PucaraColors.surfaceStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TokenStorage.clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada'),
          duration: Duration(milliseconds: 800),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 850));
      if (!context.mounted) return;
      Get.offAllNamed(AppRoutes.auth);
    }
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _headerInfoChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: PucaraColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadButton() {
    final enabled = !_downloadingPdf && controller.sites.isNotEmpty;
    return GestureDetector(
      onTap: enabled ? _downloadPdf : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: PucaraColors.accent.withValues(alpha: enabled ? 0.9 : 0.4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _downloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'DESCARGAR PRONÓSTICOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Genera el PDF de pronósticos a 7 días y abre el menú de compartir/guardar.
  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final bytes = await ForecastPdfService().build(
        sites: controller.sites.toList(),
        forecasts: controller.forecastDays.toList(),
      );
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'pronosticos_${now.year}-${two(now.month)}-${two(now.day)}.pdf',
      );
    } catch (e) {
      debugPrint('[HomePage] error generando PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el PDF de pronósticos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Site? _siteForIndex(int index) {
    final siteId = controller.siteIdForIndex(index);
    if (siteId == null) return null;
    try {
      return controller.sites.firstWhere((site) => site.id == siteId);
    } catch (_) {
      return null;
    }
  }

  bool hasSite(Site? site) => site != null;

  String _deg(double? value, bool hasForecast, {required String unit}) {
    if (!hasForecast || value == null) return '--';
    return '${value.toStringAsFixed(0)}°$unit';
  }

  /// Promedio de dos valores opcionales; si falta uno, usa el otro.
  double? _average(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return (a + b) / 2;
  }

  Widget _buildTempBar({
    required double min,
    required double max,
    required double current,
  }) {
    final safeRange = (max - min).abs() < 0.0001 ? 1.0 : (max - min);
    final ratio = ((current - min) / safeRange).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const thumbSize = 14.0;
        final thumbLeft = (trackWidth - thumbSize) * ratio;
        return SizedBox(
          height: 16,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      PucaraColors.accentBright,
                      Color(0xFF34D6D9),
                      Color(0xFFFF7A59),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Positioned(
                left: thumbLeft,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: PucaraColors.accent, width: 2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForDescription(String description) {
    final d = description.toLowerCase();
    if (d.contains('nube') || d.contains('cloud')) return Icons.cloud_outlined;
    if (d.contains('lluv') || d.contains('rain')) return Icons.grain;
    if (d.contains('torment') || d.contains('storm')) {
      return Icons.thunderstorm_outlined;
    }
    if (d.contains('nieve') || d.contains('snow')) return Icons.ac_unit;
    return Icons.wb_sunny_outlined;
  }
}
