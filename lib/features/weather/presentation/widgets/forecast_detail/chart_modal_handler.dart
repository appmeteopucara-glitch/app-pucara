import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/presentation/controllers/weather_controller.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/humidity_chart.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/isotherm_chart.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/rain_probability_chart.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/storm_probability_chart.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/temperature_chart.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/wind_direction_chart.dart';

class ChartModalHandler {
  static void showDetailChart(BuildContext context, String type, ForecastDay forecast) {
    Widget chartWidget;
    String title;
    
    switch (type) {
      case 'temperature':
        chartWidget = TemperatureChart(forecast: forecast);
        title = 'Temperatura min/max';
        break;
      case 'isotherm':
        chartWidget = IsothermChart(forecast: forecast);
        title = 'Isoterma 0°C mín/máx';
        break;
      case 'rain':
        chartWidget = RainProbabilityChart(forecast: forecast);
        title = 'Probabilidad de precipitación';
        break;
      case 'humidity':
        chartWidget = HumidityChart(forecast: forecast);
        title = 'Humedad relativa';
        break;
      case 'wind':
        chartWidget = WindDirectionChart(forecast: forecast);
        title = 'Viento';
        break;
      case 'storm':
        chartWidget = StormProbabilityChart(forecast: forecast);
        title = 'Actividad eléctrica';
        break;
      default:
        chartWidget = TemperatureChart(forecast: forecast);
        title = 'Detalle';
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: PucaraColors.surfaceStrong,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showFullScreenChart(context, type, forecast, title);
                              },
                              icon: Icon(Icons.screen_rotation_outlined),
                              tooltip: 'Ver en modo horizontal',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                foregroundColor: PucaraColors.accentBright,
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: PucaraPanel(
                              borderRadius: 22,
                              color: PucaraColors.surface,
                              padding: const EdgeInsets.all(12.0),
                              child: chartWidget,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _chartDescription(type),
                            style: const TextStyle(color: PucaraColors.textSecondary, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<bool>(
                            future: TokenStorage.isMeteorologist(),
                            builder: (context, snapshot) {
                              if (snapshot.data != true) {
                                return const SizedBox.shrink();
                              }
                              return SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final controller = Get.find<WeatherController>();
                                    final backendId = controller.getBackendIdForLocal(forecast.id);
                                    Navigator.pop(context);
                                    Get.toNamed(
                                      AppRoutes.addForecast,
                                      arguments: {
                                        'forecastId': forecast.id,
                                        'backendId': backendId,
                                        'isEditing': true,
                                        'siteId': forecast.siteId,
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar este pronóstico'),
                                ),
                              );
                            },
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
      },
    );
  }

  static void _showFullScreenChart(BuildContext context, String type, ForecastDay forecast, String title) {
    Widget chartWidget;
    
    switch (type) {
      case 'temperature':
        chartWidget = TemperatureChart(forecast: forecast, isHorizontalView: true);
        break;
      case 'isotherm':
        chartWidget = IsothermChart(forecast: forecast, isHorizontalView: true);
        break;
      case 'rain':
        chartWidget = RainProbabilityChart(forecast: forecast, isHorizontalView: true);
        break;
      case 'humidity':
        chartWidget = HumidityChart(forecast: forecast, isHorizontalView: true);
        break;
      case 'wind':
        chartWidget = WindDirectionChart(forecast: forecast, isHorizontalView: true);
        break;
      case 'storm':
        chartWidget = StormProbabilityChart(forecast: forecast, isHorizontalView: true);
        break;
      default:
        chartWidget = TemperatureChart(forecast: forecast, isHorizontalView: true);
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const PucaraBackground(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: PucaraPanel(
                            borderRadius: 24,
                            color: PucaraColors.surfaceStrong,
                            padding: const EdgeInsets.all(16.0),
                            child: chartWidget,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _chartDescription(String type) {
    switch (type) {
      case 'isotherm':
      case 'rain':
      case 'storm':
      case 'humidity':
        return 'El gráfico muestra el valor configurado para este pronóstico.';
      default:
        return 'El gráfico muestra los valores configurados para este pronóstico.';
    }
  }
}
