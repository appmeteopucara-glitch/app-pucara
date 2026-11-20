import 'package:get/get.dart';
import 'package:pronosticosapp/features/auth/presentation/pages/account_page.dart';
import 'package:pronosticosapp/features/auth/presentation/pages/auth_page.dart';
import 'package:pronosticosapp/features/auth/presentation/pages/delete_account_page.dart';
import 'package:pronosticosapp/features/company/presentation/pages/select_company_page.dart';
import 'package:pronosticosapp/features/splash/presentation/pages/splash_page.dart';
import 'package:pronosticosapp/features/weather/presentation/pages/weather_detail_page.dart';
import 'package:pronosticosapp/features/weather/presentation/pages/add_forecast_page.dart';
import 'package:pronosticosapp/features/weather/presentation/pages/home_page.dart';
import 'package:pronosticosapp/features/weather/presentation/pages/forecast_detail_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String weatherDetail = '/weather-detail';
  static const String addForecast = '/add-forecast';
  static const String selectCompany = '/select-company';
  static const String home = '/home';
  static const String forecastDetail = '/forecast-detail';
  static const String account = '/account';
  static const String deleteAccount = '/delete-account';

  static final List<GetPage> pages = [
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: auth, page: () => const AuthPage()),
    GetPage(name: weatherDetail, page: () => const WeatherDetailPage()),
    GetPage(name: addForecast, page: () => const AddForecastPage()),
    GetPage(name: selectCompany, page: () => const SelectCompanyPage()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: forecastDetail, page: () => const ForecastDetailPage()),
    GetPage(name: account, page: () => const AccountPage()),
    GetPage(name: deleteAccount, page: () => const DeleteAccountPage()),
  ];
}
