import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/storage/company_session.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final token = await TokenStorage.getToken();
    final expiry = await TokenStorage.getExpiry();
    final nowUtc = DateTime.now().toUtc();
    final isValid = token != null &&
        token.isNotEmpty &&
        (expiry == null || expiry.isAfter(nowUtc));

    await Future.delayed(const Duration(seconds: 4));

    if (isValid) await CompanySession.refreshFromServer();
    final next = isValid ? await CompanySession.nextRoute() : AppRoutes.auth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isValid) {
        Get.offAllNamed(next);
      } else {
        Get.offAllNamed(AppRoutes.auth);
      }
    });
  }
}
