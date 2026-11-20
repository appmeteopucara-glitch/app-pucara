import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PucaraBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const PucaraSectionTitle(
                  title: 'Mi cuenta',
                  subtitle: 'Administra los datos asociados a tu usuario.',
                ),
                const SizedBox(height: 28),
                const Text(
                  'ZONA DE PELIGRO',
                  style: TextStyle(
                    color: PucaraColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                PucaraPanel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.delete_outline, color: PucaraColors.danger),
                    title: const Text(
                      'Eliminar cuenta',
                      style: TextStyle(
                        color: PucaraColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Borra tus datos personales de forma permanente.',
                      style: TextStyle(color: PucaraColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: PucaraColors.textSecondary),
                    onTap: () => Get.toNamed(AppRoutes.deleteAccount),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
