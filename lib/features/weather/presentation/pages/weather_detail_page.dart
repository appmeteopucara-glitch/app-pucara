import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';
import 'package:pronosticosapp/core/utils/forecast_format.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/domain/site_variables.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/domain/entities/weather.dart';
import 'package:pronosticosapp/features/weather/presentation/controllers/weather_controller.dart';

class WeatherDetailPage extends StatelessWidget {
  const WeatherDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WeatherController>();
    final dynamic args = Get.arguments;
    final int? cityId = args is int
        ? args
        : (args is Map && args['cityId'] is int)
        ? args['cityId'] as int
        : null;
    final String? siteId = args is Map && args['siteId'] is String
        ? args['siteId'] as String
        : null;

    if (cityId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }

    late final Weather weather;
    try {
      weather = controller.weatherList.firstWhere((w) => w.id == cityId);
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }

    if (siteId != null &&
        !controller.forecastDays.any(
          (forecast) => forecast.siteId.toLowerCase() == siteId.toLowerCase(),
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadForecastsForSite(siteId);
      });
    }
    final site = _siteForId(controller, siteId);

    return Scaffold(
      floatingActionButton: FutureBuilder<bool>(
        future: TokenStorage.isMeteorologist(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done ||
              snap.data != true) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            backgroundColor: PucaraColors.accentBright,
            foregroundColor: Colors.white,
            onPressed: () async {
              final result = await Get.toNamed(
                AppRoutes.addForecast,
                arguments: {if (siteId != null) 'siteId': siteId},
              );
              if (context.mounted &&
                  result is Map &&
                  result['snackbar'] is String) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['snackbar'] as String)),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Nuevo',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
            ),
          );
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PucaraBackground(),
          SafeArea(
            child: Obx(() {
              final nearest = _todayForecast(controller, siteId);
              final slots = _forecastSlots(controller, siteId);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context, weather, site),
                    const SizedBox(height: 20),
                    FadeInDown(
                      duration: const Duration(milliseconds: 450),
                      child: _buildHeroCard(weather, nearest, siteId),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      duration: const Duration(milliseconds: 450),
                      child: _buildHighlights(weather, nearest, siteId),
                    ),
                    const SizedBox(height: 24),
                    const PucaraSectionTitle(
                      title: 'Pronóstico por día',
                      subtitle:
                          'Revisa cada día o agrega el pronóstico faltante',
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(
                      slots.length,
                      (index) => FadeInUp(
                        delay: Duration(milliseconds: 80 * index),
                        duration: const Duration(milliseconds: 350),
                        child: slots[index].forecast != null
                            ? _buildForecastCard(slots[index].forecast!, siteId)
                            : _buildMissingForecastCard(
                                slots[index].date,
                                siteId,
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Weather weather, Site? site) {
    return Row(
      children: [
        _circleAction(icon: Icons.arrow_back_ios_new, onTap: Get.back),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.cityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Text(
                  'DETALLE DEL SITIO',
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
                site?.companyName ?? 'Sitio sin pronóstico cargado',
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

  /// Variables de la faena (null = faena fuera del listado: se muestran todas).
  Set<ForecastVar>? _varsFor(String? siteId) {
    if (siteId == null || siteId.isEmpty) return null;
    final c = Get.find<WeatherController>();
    final id = siteId.toLowerCase();
    for (final site in c.sites) {
      if (site.id.toLowerCase() == id) {
        return SiteVariables.forSiteName(site.name, company: site.companyName);
      }
    }
    return null;
  }

  Widget _buildHeroCard(Weather weather, ForecastDay? nearest, String? siteId) {
    final vars = _varsFor(siteId);
    bool has(ForecastVar v) => vars?.contains(v) ?? true;
    final hasForecast = nearest != null;
    final min = hasForecast ? nearest.min : weather.minTemperature;
    final max = hasForecast ? nearest.max : weather.maxTemperature;
    // El número grande es la temperatura actual, no la máxima: si no, se repite
    // con la pastilla "MAX" de abajo. Con pronóstico, se promedia mín/máx.
    final displayTemp = hasForecast ? _average(min, max) : weather.temperature;
    final wind = hasForecast
        ? (nearest.windIntensity ?? nearest.gust)
        : weather.windSpeed;

    return PucaraPanel(
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
              'RESUMEN ACTUAL',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: WeatherIconView(
                  type: nearest?.icon ?? weather.iconCode,
                  size: 48,
                  fallback: Icon(
                    _iconForType(nearest?.icon ?? weather.iconCode),
                    color: _accentForType(nearest?.icon ?? weather.iconCode),
                    size: 42,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (has(ForecastVar.temp)) ...[
                    Text(
                      hasForecast ? fmtNum(displayTemp, '°C') : '--',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // Con pronóstico, el nombre del estado (ej. "Parcial día") ya lo dice
          // el ícono de arriba: mostrarlo aquí era redundante. Sin pronóstico,
          // sigue siendo útil indicarlo.
          if (!hasForecast) ...[
            const SizedBox(height: 16),
            Text(
              _heroStatus(weather, nearest),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Todavía no hay un pronóstico cargado para hoy.',
              style: TextStyle(
                color: PucaraColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (has(ForecastVar.temp)) ...[
                PucaraMetricPill(
                  label: 'Min',
                  value: hasForecast ? fmtNum(min, '°C') : '--',
                  icon: Icons.arrow_downward,
                  color: PucaraColors.accentBright,
                ),
                PucaraMetricPill(
                  label: 'Max',
                  value: hasForecast ? fmtNum(max, '°C') : '--',
                  icon: Icons.arrow_upward,
                  color: const Color(0xFFFF745E),
                ),
              ],
              if (has(ForecastVar.windIntensity) || has(ForecastVar.gust))
                PucaraMetricPill(
                  label: 'Viento',
                  value: hasForecast ? fmtNum(wind, 'km/h') : '--',
                  icon: Icons.air,
                  color: const Color(0xFF67D7D0),
                ),
            ],
          ),
          if (nearest == null)
            FutureBuilder<bool>(
              future: TokenStorage.isMeteorologist(),
              builder: (context, snap) {
                if (snap.data != true) return const SizedBox.shrink();
                final now = DateTime.now();
                return Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: OutlinedButton.icon(
                    onPressed: () => Get.toNamed(
                      AppRoutes.addForecast,
                      arguments: {
                        if (siteId != null) 'siteId': siteId,
                        'prefillDate': DateTime(now.year, now.month, now.day).toIso8601String(),
                      },
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar pronóstico de hoy'),
                  ),
                );
              },
            ),
          if (nearest != null) ...[
            const SizedBox(height: 18),
            FutureBuilder<bool>(
              future: TokenStorage.isMeteorologist(),
              builder: (context, snap) {
                final isMet = snap.data == true;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Get.toNamed(
                        AppRoutes.forecastDetail,
                        arguments: nearest,
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver detalle'),
                    ),
                    if (isMet)
                      OutlinedButton.icon(
                        onPressed: () {
                          final ctrl = Get.find<WeatherController>();
                          final backendId = ctrl.getBackendIdForLocal(
                            nearest.id,
                          );
                          Get.toNamed(
                            AppRoutes.addForecast,
                            arguments: {
                              'forecastId': nearest.id,
                              'backendId': backendId,
                              'isEditing': true,
                              'siteId': nearest.siteId.isNotEmpty
                                  ? nearest.siteId
                                  : siteId,
                            },
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlights(Weather weather, ForecastDay? nearest, String? siteId) {
    final vars = _varsFor(siteId);
    bool has(ForecastVar v) => vars?.contains(v) ?? true;
    String pct(int? v) => nearest == null ? '--' : fmtNum(v, '%');

    final cards = <Widget>[
      if (has(ForecastVar.precip))
        _highlightCard(
          title: 'Prob. precipitación',
          value: pct(nearest?.precipProb),
          icon: Icons.water_drop_outlined,
          color: PucaraColors.accentBright,
        ),
      if (has(ForecastVar.electric))
        _highlightCard(
          title: 'Prob. actividad eléctrica',
          value: pct(nearest?.electricProb),
          icon: Icons.thunderstorm_outlined,
          color: const Color(0xFFFFC95B),
        ),
      if (has(ForecastVar.water))
        _highlightCard(
          title: 'Acum. agua',
          value: nearest == null ? '--' : fmtNum(nearest.waterMm, 'mm'),
          icon: Icons.opacity_outlined,
          color: const Color(0xFF59D1B7),
        ),
      if (has(ForecastVar.snow))
        _highlightCard(
          title: 'Acum. nieve',
          value: nearest == null ? '--' : fmtNum(nearest.snowCm, 'cm'),
          icon: Icons.ac_unit,
          color: const Color(0xFF7CC5FF),
        ),
      if (has(ForecastVar.humidity))
        _highlightCard(
          title: 'Humedad relativa',
          value: pct(nearest?.humidity),
          icon: Icons.opacity,
          color: const Color(0xFF59D1B7),
        ),
    ];

    // De a dos por fila.
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        Row(
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 12),
            Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox.shrink()),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _highlightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return PucaraPanel(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: PucaraColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(ForecastDay day, String? siteId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PucaraPanel(
        padding: EdgeInsets.zero,
        borderRadius: 22,
        child: InkWell(
          onTap: () => _showForecastOptions(day, siteId),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: WeatherIconView(
                    type: day.icon,
                    size: 36,
                    fallback: Icon(
                      _iconForType(day.icon),
                      color: _accentForType(day.icon),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          day.day.toUpperCase(),
                          style: const TextStyle(
                            color: PucaraColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // El chip de arriba ya dice el día (ej. "MIÉRCOLES"):
                        // aquí solo la fecha, para no repetirlo.
                        '${day.date.day}/${day.date.month}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para ver detalle o acciones',
                        style: const TextStyle(
                          color: PucaraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(builder: (context) {
                  final showTemp = _varsFor(siteId)?.contains(ForecastVar.temp) ?? true;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        showTemp ? fmtDeg(day.max) : fmtNum(day.precipProb, '%'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        showTemp ? 'Min ${fmtDeg(day.min)}' : 'Prob. precip.',
                        style: const TextStyle(
                          color: PucaraColors.accentBright,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingForecastCard(DateTime date, String? siteId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PucaraPanel(
        borderRadius: 22,
        child: FutureBuilder<bool>(
          future: TokenStorage.isMeteorologist(),
          builder: (context, snap) {
            final canCreate = snap.data == true;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _dayName(date).toUpperCase(),
                    style: const TextStyle(
                      color: PucaraColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_dayName(date)} ${date.day}/${date.month}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Todavía no hay pronóstico cargado para este día.',
                  style: TextStyle(
                    color: PucaraColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (canCreate) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Get.toNamed(
                        AppRoutes.addForecast,
                        arguments: {
                          if (siteId != null) 'siteId': siteId,
                          'prefillDate': date.toIso8601String(),
                        },
                      );
                      if (context.mounted &&
                          result is Map &&
                          result['snackbar'] is String) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['snackbar'] as String)),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar pronóstico'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _showForecastOptions(ForecastDay day, String? siteId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: PucaraColors.surfaceStrong,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              day.day,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecciona una acción para este pronóstico',
              style: TextStyle(color: PucaraColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: TokenStorage.isMeteorologist(),
              builder: (context, snap) {
                final canEdit = snap.data == true;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit)
                      _sheetTile(
                        icon: Icons.edit_outlined,
                        color: PucaraColors.accentBright,
                        label: 'Editar pronóstico',
                        onTap: () {
                          Get.back();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Get.toNamed(
                              AppRoutes.addForecast,
                              arguments: {
                                'forecastId': day.id,
                                'backendId': Get.find<WeatherController>()
                                    .getBackendIdForLocal(day.id),
                                'isEditing': true,
                                'siteId': day.siteId.isNotEmpty
                                    ? day.siteId
                                    : siteId,
                              },
                            );
                          });
                        },
                      ),
                    _sheetTile(
                      icon: Icons.visibility_outlined,
                      color: const Color(0xFF7BE495),
                      label: 'Ver detalle',
                      onTap: () {
                        Get.back();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Get.toNamed(AppRoutes.forecastDetail, arguments: day);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: Colors.white.withValues(alpha: 0.04),
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }

  Widget _circleAction({required IconData icon, required VoidCallback onTap}) {
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

  /// Pronóstico de HOY de la faena (null si aún no está cargado).
  ForecastDay? _todayForecast(WeatherController controller, String? siteId) {
    final normalizedSiteId = siteId?.toLowerCase();
    final now = DateTime.now();
    for (final f in controller.forecastDays) {
      final sameSite = normalizedSiteId == null ||
          normalizedSiteId.isEmpty ||
          f.siteId.toLowerCase() == normalizedSiteId;
      if (sameSite &&
          f.date.year == now.year &&
          f.date.month == now.month &&
          f.date.day == now.day) {
        return f;
      }
    }
    return null;
  }

  String _heroStatus(Weather weather, ForecastDay? nearest) {
    if (nearest == null) return 'Sin pronóstico';
    return WeatherIconCatalog.labelFor(nearest.icon);
  }

  String _dayName(DateTime date) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[date.weekday - 1];
  }

  Site? _siteForId(WeatherController controller, String? siteId) {
    if (siteId == null || siteId.isEmpty) return null;
    try {
      final normalizedSiteId = siteId.toLowerCase();
      return controller.sites.firstWhere(
        (site) => site.id.toLowerCase() == normalizedSiteId,
      );
    } catch (_) {
      return null;
    }
  }

  List<_ForecastSlot> _forecastSlots(
    WeatherController controller,
    String? siteId,
  ) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final normalizedSiteId = siteId?.toLowerCase();
    final records = controller.forecastDays
        .where(
          (forecast) =>
              normalizedSiteId == null ||
              normalizedSiteId.isEmpty ||
              forecast.siteId.toLowerCase() == normalizedSiteId,
        )
        .toList();
    final byKey = <String, ForecastDay>{};
    for (final forecast in records) {
      final normalized = DateTime(
        forecast.date.year,
        forecast.date.month,
        forecast.date.day,
      );
      byKey[_dateKey(normalized)] = forecast;
    }

    // Hoy va en el resumen superior; aquí solo los 6 días siguientes (7 en total).
    return List.generate(6, (index) {
      final date = start.add(Duration(days: index + 1));
      return _ForecastSlot(date: date, forecast: byKey[_dateKey(date)]);
    });
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  /// Promedio de dos valores opcionales; si falta uno, usa el otro.
  double? _average(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return (a + b) / 2;
  }

  IconData _iconForType(String type) {
    final value = type.toLowerCase();
    if (value.contains('cloud')) return Icons.cloud_outlined;
    if (value.contains('rain')) return Icons.grain;
    if (value.contains('storm')) return Icons.thunderstorm_outlined;
    if (value.contains('snow')) return Icons.ac_unit;
    return Icons.wb_sunny_outlined;
  }

  Color _accentForType(String type) {
    final value = type.toLowerCase();
    if (value.contains('cloud')) return const Color(0xFFEAEAEA);
    if (value.contains('rain')) return PucaraColors.accentBright;
    if (value.contains('storm')) return const Color(0xFFFFC95B);
    if (value.contains('snow')) return const Color(0xFF7CC5FF);
    return const Color(0xFFFFD45D);
  }
}

class _ForecastSlot {
  final DateTime date;
  final ForecastDay? forecast;

  const _ForecastSlot({required this.date, required this.forecast});
}
