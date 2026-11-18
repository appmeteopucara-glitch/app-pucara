import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/features/splash/presentation/controllers/splash_controller.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PucaraBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 4),
                  FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Column(
                      children: [
                        const PucaraBrand(
                          size: 188,
                          showTagline: false,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 116,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'INFORMACIÓN METEORÓLOGICA\nPARA DECISIONES SEGURAS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PucaraColors.textSecondary,
                            fontSize: 12,
                            height: 1.45,
                            letterSpacing: 0.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 700),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 74,
                          height: 74,
                          child: CircularProgressIndicator(
                            strokeWidth: 4.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PucaraColors.accentBright,
                            ),
                            backgroundColor: Color(0x29FFFFFF),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'CARGANDO...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 148,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeIn(
                    delay: const Duration(milliseconds: 600),
                    child: const Text(
                      'Preparando información meteorológica',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PucaraColors.textSecondary,
                        fontSize: 13,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
