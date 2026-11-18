import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';
import 'package:pronosticosapp/core/utils/forecast_format.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_input.dart';
import 'package:pronosticosapp/features/weather/domain/site_variables.dart';
import 'package:pronosticosapp/features/weather/data/datasource/weather_remote_data_source.dart';
import 'package:pronosticosapp/features/weather/presentation/controllers/weather_controller.dart';

class AddForecastPage extends StatefulWidget {
  const AddForecastPage({super.key});

  @override
  State<AddForecastPage> createState() => _AddForecastPageState();
}

class _AddForecastPageState extends State<AddForecastPage> with WidgetsBindingObserver {
  final WeatherController controller = Get.find<WeatherController>();
  String? selectedSiteId;
  DateTime? selectedForecastDate;
  bool? _canCreate;
  // Todas las variables son opcionales: un campo vacío se envía como null.
  final TextEditingController minTempController = TextEditingController();
  final TextEditingController maxTempController = TextEditingController();
  final TextEditingController isoMinController = TextEditingController();
  final TextEditingController isoMaxController = TextEditingController();
  final TextEditingController isoHeightController = TextEditingController();
  final TextEditingController electricProbController = TextEditingController();
  final TextEditingController precipProbController = TextEditingController();
  final TextEditingController waterMmController = TextEditingController();
  final TextEditingController snowCmController = TextEditingController();
  final TextEditingController windIntensityController = TextEditingController();
  final TextEditingController gustController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();

  String selectedDay = '';
  String selectedIcon = WeatherIconCatalog.defaultKey; // Valor predeterminado
  // Hasta dos puntos cardinales por franja (ej. NO/SO). Vacío = sin dato.
  List<String> windDirectionAM = [];
  List<String> windDirectionPM = [];
  // Texto del resumen que acompaña a la clave del ícono (se conserva al editar).
  String _summaryExtra = '';

  final List<String> windDirections = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];

  bool isEditing = false;
  int? editingForecastId;
  String? editingBackendId;

  /// Variables de la faena elegida (null = faena fuera del listado: todas).
  Set<ForecastVar>? get _siteVars {
    final id = selectedSiteId?.toLowerCase();
    if (id == null) return null;
    for (final site in controller.sites) {
      if (site.id.toLowerCase() == id) {
        final vars = SiteVariables.forSiteName(site.name, company: site.companyName);
        debugPrint('[SiteVariables] "${site.name}" (${site.companyName}) -> ${vars == null ? "todas" : vars.map((v) => v.name).join(",")}');
        return vars;
      }
    }
    return null;
  }

  bool _has(ForecastVar v) => _siteVars?.contains(v) ?? true;

  List<TextEditingController> get _allControllers => [
    minTempController,
    maxTempController,
    isoMinController,
    isoMaxController,
    isoHeightController,
    electricProbController,
    precipProbController,
    waterMmController,
    snowCmController,
    windIntensityController,
    gustController,
    humidityController,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args['siteId'] is String) {
        selectedSiteId = args['siteId'] as String;
      }
      if (args['prefillDate'] is String) {
        selectedForecastDate = _normalizeDate(DateTime.tryParse(args['prefillDate'] as String));
      } else if (args['prefillDate'] is DateTime) {
        selectedForecastDate = _normalizeDate(args['prefillDate'] as DateTime);
      }
    }
    _checkRole();

    // Verificar si estamos en modo edición
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args.containsKey('forecastId') && args.containsKey('isEditing')) {
        isEditing = args['isEditing'] ?? false;
        editingForecastId = args['forecastId'];
        if (args['backendId'] is String) {
          editingBackendId = args['backendId'] as String;
        }

        if (isEditing && editingForecastId != null) {
          _loadForecastData(editingForecastId!);
        }
      }
    }

    // Si no estamos editando, solo se fija el día; las variables quedan vacías.
    if (!isEditing) {
      final nextDays = controller.getNextDays(4);
      if (selectedForecastDate != null) {
        selectedDay = _dayName(selectedForecastDate!);
      } else if (nextDays.isNotEmpty) {
        selectedForecastDate = _normalizeDate(DateTime.now());
        selectedDay = nextDays[0]; // Día actual
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkRole();
    }
  }

  void _checkRole() async {
    final can = await TokenStorage.isMeteorologist();
    if (mounted) setState(() => _canCreate = can);
  }

  String _numText(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  List<String> _splitDirection(String? value) {
    if (value == null || value.trim().isEmpty) return [];
    return value.split('/').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).take(2).toList();
  }

  void _loadForecastData(int forecastId) {
    final forecast = controller.getForecastById(forecastId);
    if (forecast != null) {
      selectedForecastDate = _normalizeDate(forecast.date);
      selectedDay = forecast.day;
      selectedIcon = WeatherIconCatalog.resolve(forecast.icon) ?? WeatherIconCatalog.defaultKey;
      minTempController.text = _numText(forecast.min);
      maxTempController.text = _numText(forecast.max);
      isoMinController.text = _numText(forecast.isoMin);
      isoMaxController.text = _numText(forecast.isoMax);
      isoHeightController.text = _numText(forecast.isoHeight);
      electricProbController.text = _numText(forecast.electricProb);
      precipProbController.text = _numText(forecast.precipProb);
      waterMmController.text = _numText(forecast.waterMm);
      snowCmController.text = _numText(forecast.snowCm);
      windIntensityController.text = _numText(forecast.windIntensity);
      gustController.text = _numText(forecast.gust);
      humidityController.text = _numText(forecast.humidity);
      windDirectionAM = _splitDirection(forecast.windDirectionAM);
      windDirectionPM = _splitDirection(forecast.windDirectionPM);
      final summary = forecast.summary ?? '';
      if (WeatherIconCatalog.fromSummary(summary) != null) {
        final comma = summary.indexOf(',');
        _summaryExtra = comma == -1 ? '' : summary.substring(comma + 1).trim();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextDays = controller.getNextDays(4); // Hoy + 3 días
    final availableDates = _availableForecastDates();
    if (_canCreate == null) {
      return const Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            PucaraBackground(),
            Center(
              child: CircularProgressIndicator(color: PucaraColors.accentBright),
            ),
          ],
        ),
      );
    }
    if (_canCreate == false) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PucaraBackground(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: PucaraPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 48, color: PucaraColors.accentBright),
                        const SizedBox(height: 12),
                        const Text(
                          'Acceso restringido',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tu rol actual no permite crear pronósticos.\nSi crees que esto es un error, contacta a un administrador.\nPuedes ver pronósticos existentes desde la lista.',
                          style: TextStyle(fontSize: 14, color: PucaraColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back_ios_new),
                          label: const Text('Volver'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
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
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  PucaraPanel(
                    color: PucaraColors.surfaceStrong,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Text(
                          'CONFIGURACIÓN DEL PRONÓSTICO',
                            style: TextStyle(
                              color: PucaraColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PucaraSectionTitle(
                          title: isEditing ? 'Editar pronóstico' : 'Nuevo pronóstico',
                          subtitle: 'Configura el estado meteorológico del sitio',
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Día y estado'),
                        const SizedBox(height: 8),
                        _buildDaySelector(nextDays, availableDates),
                        // El estado del clima se elige siempre, sin importar la faena.
                        const SizedBox(height: 12),
                        _buildWeatherIconChips(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PucaraSectionTitle(
                    title: 'Variables meteorológicas',
                    subtitle: 'Toca cada tarjeta para editar sus valores',
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.94,
                    children: [
                      if (_has(ForecastVar.temp))
                      _buildOptionCard(
                        title: 'Temp. mín./máx.',
                        subtitle: 'Rango diario en °C',
                        icon: Icons.thermostat,
                        value: fmtRange(_parse(minTempController), _parse(maxTempController), '°C'),
                        onTap: () => _showTemperatureModal(context),
                      ),
                      if (_has(ForecastVar.isoMinMax))
                      _buildOptionCard(
                        title: 'Isoterma 0°C',
                        subtitle: 'Mínima y máxima en msnm',
                        icon: Icons.ac_unit,
                        value: fmtRange(_parse(isoMinController), _parse(isoMaxController), 'msnm'),
                        onTap: () => _showIsothermModal(context),
                      ),
                      if (_has(ForecastVar.isoHeight))
                      _buildOptionCard(
                        title: 'Altura de isoterma',
                        subtitle: 'En msnm',
                        icon: Icons.height,
                        value: fmtNum(_parse(isoHeightController), 'msnm'),
                        onTap: () => _showSingleValueModal(
                          context,
                          title: 'Altura de isoterma',
                          subtitle: 'Metros sobre el nivel del mar (1000 a 6000)',
                          controller: isoHeightController,
                          hint: 'Altura (msnm)',
                          decimal: false,
                        ),
                      ),
                      if (_has(ForecastVar.precip))
                      _buildOptionCard(
                        title: 'Prob. precipitación',
                        subtitle: 'Porcentaje (0 a 100)',
                        icon: Icons.water_drop_outlined,
                        value: fmtNum(_parse(precipProbController), '%'),
                        onTap: () => _showSingleValueModal(
                          context,
                          title: 'Probabilidad de precipitación',
                          subtitle: 'Valor en porcentaje (0 a 100)',
                          controller: precipProbController,
                          hint: 'Probabilidad (%)',
                          decimal: false,
                        ),
                      ),
                      if (_has(ForecastVar.electric))
                      _buildOptionCard(
                        title: 'Actividad eléctrica',
                        subtitle: 'Probabilidad (%)',
                        icon: Icons.thunderstorm_outlined,
                        value: fmtNum(_parse(electricProbController), '%'),
                        onTap: () => _showSingleValueModal(
                          context,
                          title: 'Probabilidad de actividad eléctrica',
                          subtitle: 'Valor en porcentaje (0 a 100)',
                          controller: electricProbController,
                          hint: 'Probabilidad (%)',
                          decimal: false,
                        ),
                      ),
                      if (_has(ForecastVar.water))
                      _buildOptionCard(
                        title: 'Acum. agua',
                        subtitle: 'Precipitación en mm',
                        icon: Icons.opacity_outlined,
                        value: fmtNum(_parse(waterMmController), 'mm'),
                        onTap: () => _showSingleValueModal(
                          context,
                          title: 'Acumulación de precipitación de agua',
                          subtitle: 'Valor en milímetros (0 a 1000)',
                          controller: waterMmController,
                          hint: 'Agua (mm)',
                        ),
                      ),
                      if (_has(ForecastVar.snow))
                      _buildOptionCard(
                        title: 'Acum. nieve',
                        subtitle: 'Precipitación en cm',
                        icon: Icons.snowing,
                        value: fmtNum(_parse(snowCmController), 'cm'),
                        onTap: () => _showSingleValueModal(
                          context,
                          title: 'Acumulación de precipitación de nieve',
                          subtitle: 'Valor en centímetros (0 a 500)',
                          controller: snowCmController,
                          hint: 'Nieve (cm)',
                        ),
                      ),
                      if (_has(ForecastVar.windDir) || _has(ForecastVar.windIntensity) || _has(ForecastVar.gust))
                      _buildOptionCard(
                        title: 'Viento',
                        subtitle: 'Dirección, intensidad y rachas',
                        icon: Icons.air,
                        value: [
                          if (_has(ForecastVar.windDir)) 'AM ${fmtText(windDirectionAM.join('/'))}\nPM ${fmtText(windDirectionPM.join('/'))}',
                          if (_has(ForecastVar.windIntensity)) 'Int. ${fmtNum(_parse(windIntensityController), 'km/h')}',
                          if (_has(ForecastVar.gust)) 'Rachas ${fmtNum(_parse(gustController), 'km/h')}',
                        ].join('\n'),
                        onTap: () => _showWindDirectionModal(context),
                      ),
                      if (_has(ForecastVar.humidity))
                      _buildOptionCard(
                        title: 'Humedad relativa',
                        subtitle: 'Porcentaje (0 a 100)',
                        icon: Icons.opacity,
                        value: fmtNum(_parse(humidityController), '%'),
                        onTap: () => _showSingleValueModal(
                          context,
                          title: 'Humedad relativa',
                          subtitle: 'Valor en porcentaje (0 a 100)',
                          controller: humidityController,
                          hint: 'Humedad (%)',
                          decimal: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Obx(
                    () => PucaraPrimaryButton(
                      label: isEditing ? 'GUARDAR EDICIÓN' : 'GUARDAR PRONÓSTICO',
                      onPressed: controller.isSaving.value ? null : _saveForecast,
                      isLoading: controller.isSaving.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: Get.back,
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar pronóstico' : 'Agregar pronóstico',
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
                  'FORMULARIO OPERATIVO',
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
                selectedSiteId == null ? 'Sin sitio seleccionado' : 'Sitio seleccionado',
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

  Future<void> _showPucaraSheet({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: PucaraColors.surfaceStrong,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: child,
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 52,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _sheetTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetHandle(),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: PucaraColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _modalTextField({
    required TextEditingController controller,
    required String hint,
    bool signed = false,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(signed: signed, decimal: decimal),
      style: const TextStyle(color: Colors.white),
      decoration: pucaraInputDecoration(
        hint: hint,
        icon: Icons.edit_outlined,
      ),
    );
  }

  Widget _sheetConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PucaraPrimaryButton(
        label: 'CONFIRMAR',
        onPressed: () {
          setState(() {});
          Navigator.pop(context);
        },
      ),
    );
  }

  // Encabezado de sección
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
  
  // Selector de día 
  Widget _buildDaySelector(List<String> nextDays, List<DateTime> dateOptions) {
    final options = dateOptions.map(_dayName).toList();
    if (selectedDay.isNotEmpty && !options.contains(selectedDay)) {
      options.insert(0, selectedDay);
    }
    return InputDecorator(
      decoration: pucaraInputDecoration(
        hint: 'Selecciona un día',
        icon: Icons.calendar_today_outlined,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF122540),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          value: selectedDay.isEmpty ? null : selectedDay,
          isExpanded: true,
          hint: const Text('Selecciona un día', style: TextStyle(color: PucaraColors.textSecondary)),
          items: options.map((day) {
            return DropdownMenuItem<String>(
              value: day,
              child: Text(day, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedDay = value;
                final idx = options.indexOf(value);
                if (idx >= 0 && idx < dateOptions.length) {
                  selectedForecastDate = dateOptions[idx];
                }
              });
            }
          },
        ),
      ),
    );
  }
  
  // Lista desplegable de estado del clima (catálogo de íconos)
  Widget _buildWeatherIconChips() {
    return InputDecorator(
      decoration: pucaraInputDecoration(
        hint: 'Selecciona el estado del clima',
        icon: Icons.wb_cloudy_outlined,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF122540),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          value: selectedIcon,
          isExpanded: true,
          menuMaxHeight: 420,
          selectedItemBuilder: (context) => WeatherIconCatalog.options
              .map((o) => Align(
                    alignment: Alignment.centerLeft,
                    child: _iconOptionRow(o, 28),
                  ))
              .toList(),
          items: WeatherIconCatalog.options
              .map((o) => DropdownMenuItem<String>(
                    value: o.key,
                    child: _iconOptionRow(o, 36),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => selectedIcon = value);
          },
        ),
      ),
    );
  }

  Widget _iconOptionRow(WeatherIconOption option, double size) {
    return Row(
      children: [
        Image.asset(option.asset, width: size, height: size, fit: BoxFit.contain),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            option.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
  
  // Widget para construir las tarjetas de opciones
  Widget _buildOptionCard({required String title, String? subtitle, required IconData icon, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: PucaraPanel(
        borderRadius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: PucaraColors.accentBright),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: PucaraColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: PucaraColors.accentBright,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Text(
                  'Editar configuración',
                  style: TextStyle(
                    color: PucaraColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                Spacer(),
                Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Modal para temperatura
  void _showTemperatureModal(BuildContext context) {
    _showPucaraSheet(
      context: context,
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Temperatura mín./máx.', subtitle: 'Rango diario (-50 a 50 °C). Déjalo vacío si no hay dato'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _modalTextField(controller: minTempController, hint: 'Mínima (°C)', signed: true, decimal: true)),
              const SizedBox(width: 16),
              Expanded(child: _modalTextField(controller: maxTempController, hint: 'Máxima (°C)', signed: true, decimal: true)),
            ],
          ),
          const SizedBox(height: 20),
          _sheetConfirmButton(context),
        ],
      ),
    );
  }

  // Modal para isoterma (mínima y máxima en msnm)
  void _showIsothermModal(BuildContext context) {
    _showPucaraSheet(
      context: context,
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Isoterma 0°C', subtitle: 'Mínima y máxima en msnm (1000 a 6000, enteros). Déjalo vacío si no hay dato'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _modalTextField(controller: isoMinController, hint: 'Mínima (msnm)')),
              const SizedBox(width: 16),
              Expanded(child: _modalTextField(controller: isoMaxController, hint: 'Máxima (msnm)')),
            ],
          ),
          const SizedBox(height: 20),
          _sheetConfirmButton(context),
        ],
      ),
    );
  }

  // Modal genérico para una sola variable opcional
  void _showSingleValueModal(
    BuildContext context, {
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hint,
    bool decimal = true,
  }) {
    _showPucaraSheet(
      context: context,
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle(title, subtitle: '$subtitle. Déjalo vacío si no hay dato'),
          const SizedBox(height: 20),
          _modalTextField(controller: controller, hint: hint, decimal: decimal),
          const SizedBox(height: 20),
          _sheetConfirmButton(context),
        ],
      ),
    );
  }

  // Modal para viento: dirección AM/PM (hasta dos puntos), intensidad y rachas
  void _showWindDirectionModal(BuildContext context) {
    _showPucaraSheet(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          Widget chips(String label, List<String> selected) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Wrap(
                  spacing: 8,
                  children: windDirections.map((direction) {
                    final isSelected = selected.contains(direction);
                    return FilterChip(
                      label: Text(direction, style: TextStyle(color: isSelected ? Colors.white : PucaraColors.textSecondary)),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (value) {
                        void apply() {
                          if (value) {
                            selected.add(direction);
                            if (selected.length > 2) selected.removeAt(0);
                          } else {
                            selected.remove(direction);
                          }
                        }
                        setModalState(apply);
                        setState(() {});
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      selectedColor: PucaraColors.accent,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    );
                  }).toList(),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetTitle('Viento', subtitle: 'Hasta dos puntos cardinales por franja. Todo es opcional'),
                const SizedBox(height: 20),
                if (_has(ForecastVar.windDir)) ...[
                  chips('AM:', windDirectionAM),
                  const SizedBox(height: 16),
                  chips('PM:', windDirectionPM),
                  const SizedBox(height: 16),
                ],
                if (_has(ForecastVar.windIntensity)) ...[
                  _modalTextField(controller: windIntensityController, hint: 'Intensidad (km/h)', decimal: true),
                  const SizedBox(height: 12),
                ],
                if (_has(ForecastVar.gust)) ...[
                  _modalTextField(controller: gustController, hint: 'Rachas máximas (km/h)', decimal: true),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                _sheetConfirmButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Texto vacío = null (sin dato). Acepta coma decimal.
  double? _parse(TextEditingController c) {
    final raw = c.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  /// Isoterma 0 °C: enteros de 1000 a 6000 msnm (la API rechaza decimales y valores fuera de rango).
  String? _isothermError() {
    final fields = <String, TextEditingController>{
      'La isoterma mínima': isoMinController,
      'La isoterma máxima': isoMaxController,
      'La altura de la isoterma': isoHeightController,
    };
    for (final entry in fields.entries) {
      final v = _parse(entry.value);
      if (v == null) continue;
      if (v != v.roundToDouble()) return '${entry.key} debe ser un número entero';
      if (v < 1000 || v > 6000) return '${entry.key} debe estar entre 1000 y 6000 msnm';
    }
    return null;
  }

  /// Devuelve el nombre de la primera variable con un texto que no es número.
  String? _invalidNumberField() {
    final fields = <String, TextEditingController>{
      'La temperatura mínima': minTempController,
      'La temperatura máxima': maxTempController,
      'La isoterma mínima': isoMinController,
      'La isoterma máxima': isoMaxController,
      'La altura de la isoterma': isoHeightController,
      'La probabilidad de actividad eléctrica': electricProbController,
      'La probabilidad de precipitación': precipProbController,
      'La acumulación de agua': waterMmController,
      'La acumulación de nieve': snowCmController,
      'La intensidad del viento': windIntensityController,
      'Las rachas máximas': gustController,
      'La humedad relativa': humidityController,
    };
    for (final entry in fields.entries) {
      final raw = entry.value.text.trim();
      if (raw.isNotEmpty && _parse(entry.value) == null) return entry.key;
    }
    return null;
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveForecast() async {
    // Solo faena y fecha son obligatorias.
    if (selectedSiteId == null || selectedSiteId!.isEmpty) {
      final ctx = context;
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Selecciona un sitio'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (selectedDay.isEmpty) {
      _showMessage('Selecciona un día');
      return;
    }

    try {
      final invalid = _invalidNumberField();
      if (invalid != null) {
        _showMessage('$invalid no es un número válido');
        return;
      }
      final isothermError = _isothermError();
      if (isothermError != null) {
        _showMessage(isothermError);
        return;
      }
      final min = _parse(minTempController);
      final max = _parse(maxTempController);
      final isoMin = _parse(isoMinController)?.round();
      final isoMax = _parse(isoMaxController)?.round();
      if (min != null && max != null && min > max) {
        _showMessage('La temperatura mínima debe ser menor o igual a la máxima');
        return;
      }
      if (isoMin != null && isoMax != null && isoMin > isoMax) {
        _showMessage('La isoterma mínima debe ser menor o igual a la máxima');
        return;
      }

      final date = _normalizeDate(selectedForecastDate);
      final allowedKeys = _availableForecastDates().map(_dateKey).toSet();
      if (!allowedKeys.contains(_dateKey(date))) {
        final ctx = context;
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('La fecha del pronóstico debe estar entre hoy y 6 días hacia adelante'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // El backend no tiene campo de ícono editable: la clave del catálogo va al inicio del resumen.
      final summary = _summaryExtra.isEmpty ? selectedIcon : '$selectedIcon, $_summaryExtra';
      int? asInt(TextEditingController c) => _parse(c)?.round();
      String? direction(List<String> d) => d.isEmpty ? null : d.join('/');

      final input = ForecastInput(
        siteId: selectedSiteId!,
        forecastDate: date,
        temperatureMinC: min,
        temperatureMaxC: max,
        windDirectionAm: direction(windDirectionAM),
        windDirectionPm: direction(windDirectionPM),
        isothermMinMsnm: isoMin,
        isothermMaxMsnm: isoMax,
        isothermHeightMeters: asInt(isoHeightController),
        electricActivityProbabilityPercent: asInt(electricProbController),
        precipitationProbabilityPercent: asInt(precipProbController),
        waterAccumulationMm: _parse(waterMmController),
        snowAccumulationCm: _parse(snowCmController),
        windIntensityKmH: _parse(windIntensityController),
        maxWindGustKmH: _parse(gustController),
        relativeHumidityPercent: asInt(humidityController),
        summary: summary,
      );

      final doCreate = !isEditing || editingForecastId == null;
      final backendId = isEditing ? (editingBackendId ?? (editingForecastId != null ? controller.getBackendIdForLocal(editingForecastId!) : null)) : null;
      if (!doCreate && (backendId == null || backendId.isEmpty)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo identificar el pronóstico a actualizar'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      debugPrint('[AddForecast] ${doCreate ? "CREATE" : "UPDATE id=$backendId"} payload=${input.toJson()}');
      final ok = doCreate
          ? await controller.createForecastRemote(input) != null
          : await controller.updateForecastRemote(backendId!, input);

      if (ok) {
        debugPrint('[AddForecast] ${doCreate ? "CREATE" : "UPDATE"} OK');
        if (!doCreate) {
          await controller.loadForecastsForSite(selectedSiteId!);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Get.back(result: {'snackbar': doCreate ? 'Pronóstico creado correctamente' : 'Pronóstico actualizado correctamente'});
        return;
      }

      debugPrint('[AddForecast] ${doCreate ? "CREATE" : "UPDATE"} FAILED');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(doCreate ? 'No se pudo crear el pronóstico' : 'No se pudo actualizar el pronóstico'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationError catch (e) {
      debugPrint('[AddForecast] VALIDATION ERROR: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      debugPrint('[AddForecast] ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al guardar el pronóstico'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  DateTime _normalizeDate(DateTime? date) {
    final value = (date ?? DateTime.now()).toLocal();
    return DateTime(value.year, value.month, value.day);
  }

  List<DateTime> _availableForecastDates() {
    final start = _normalizeDate(DateTime.now());
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  String _dayName(DateTime date) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[date.weekday - 1];
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
