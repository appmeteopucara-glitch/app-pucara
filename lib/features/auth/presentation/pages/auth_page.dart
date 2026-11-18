import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/features/auth/presentation/controllers/auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AuthController controller;
  late Worker _tabWorker;
  bool _loginPwdObscure = true;
  bool _registerPwdObscure = true;
  bool _registerConfirmObscure = true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AuthController());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      controller.changeTab(_tabController.index);
    });
    _tabWorker = ever<int>(controller.tabIndex, (i) {
      if (_tabController.index != i) {
        _tabController.animateTo(i);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PucaraBackground(),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom * 0.15),
            child: SafeArea(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: keyboardOpen ? 6 : 10),
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PucaraBrand(
                        size: 116,
                        compact: true,
                        showTagline: false,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: keyboardOpen ? 10 : 20),
                FadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            'PLATAFORMA METEOROLOGICA',
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
                          'Accede a tu panel operativo',
                          style: TextStyle(
                            fontSize: keyboardOpen ? 24 : 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: keyboardOpen ? 4 : 8),
                        Text(
                          'Consulta pronósticos, variables ambientales y alertas con el mismo estilo visual del panel PUCARÁ.',
                          style: TextStyle(
                            fontSize: keyboardOpen ? 13 : 14,
                            color: PucaraColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: keyboardOpen ? 12 : 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PucaraPanel(
                    padding: const EdgeInsets.all(5),
                    borderRadius: 22,
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: PucaraColors.textSecondary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [PucaraColors.accentBright, PucaraColors.accent],
                        ),
                      ),
                      tabs: const [
                        Tab(text: 'Ingresar'),
                        Tab(text: 'Crear cuenta'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: keyboardOpen ? 10 : 16),
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: PucaraPanel(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                        borderRadius: 28,
                        color: PucaraColors.surfaceStrong,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLoginForm(controller),
                            _buildRegisterForm(controller),
                          ],
                        ),
                      ),
                    ),
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

  // Formulario de login
  Widget _buildLoginForm(AuthController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inicia sesión para continuar',
              style: TextStyle(
                fontSize: 17,
                color: PucaraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 26),
            TextField(
              onChanged: controller.setEmail,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Correo electrónico',
                icon: Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 6),
            Obx(() {
              final showError = controller.email.value.isNotEmpty && !controller.isEmailValid;
              return showError
                  ? const Text('Correo inválido', style: TextStyle(color: PucaraColors.danger))
                  : const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.setPassword,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Contraseña',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _loginPwdObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _loginPwdObscure = !_loginPwdObscure),
                ),
              ),
              obscureText: _loginPwdObscure,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 6),
            Obx(() {
              final showError = controller.password.value.isNotEmpty && !controller.isPasswordValid;
              return showError
                  ? const Text('Mínimo 6 caracteres', style: TextStyle(color: PucaraColors.danger))
                  : const SizedBox.shrink();
            }),
            const SizedBox(height: 20),
            Obx(
              () => PucaraPrimaryButton(
                label: 'INGRESAR',
                onPressed: controller.isLoading.value || !controller.canLogin ? null : controller.login,
                isLoading: controller.isLoading.value,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => controller.errorMessage.value.isNotEmpty
                  ? Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: PucaraColors.danger),
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¿Aún no tienes cuenta?',
                  style: TextStyle(color: PucaraColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Crear una ahora'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Formulario de registro
  Widget _buildRegisterForm(AuthController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Solicita acceso para usar la plataforma',
              style: TextStyle(
                fontSize: 16,
                color: PucaraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: controller.setFirstName,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Nombres',
                icon: Icons.person_outline,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.setLastName,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Apellidos',
                icon: Icons.badge_outlined,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.setEmail,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Correo electrónico',
                icon: Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 6),
            Obx(() {
              final showError = controller.email.value.isNotEmpty && !controller.isEmailValid;
              return showError
                  ? const Text('Correo inválido', style: TextStyle(color: PucaraColors.danger))
                  : const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.setPassword,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Contraseña',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _registerPwdObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _registerPwdObscure = !_registerPwdObscure),
                ),
              ),
              obscureText: _registerPwdObscure,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 6),
            Obx(() {
              final showError = controller.password.value.isNotEmpty && !controller.isPasswordValid;
              return showError
                  ? const Text('Mínimo 6 caracteres', style: TextStyle(color: PucaraColors.danger))
                  : const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.setConfirmPassword,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Confirmar contraseña',
                icon: Icons.lock_reset_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _registerConfirmObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _registerConfirmObscure = !_registerConfirmObscure),
                ),
              ),
              obscureText: _registerConfirmObscure,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 6),
            Obx(() {
              final confirm = controller.confirmPassword.value;
              final showMin = confirm.isNotEmpty && confirm.length < 6;
              final showMatch = confirm.isNotEmpty && !controller.arePasswordsEqual && !showMin;
              if (showMin) {
                return const Text('Mínimo 6 caracteres', style: TextStyle(color: PucaraColors.danger));
              }
              if (showMatch) {
                return const Text('Las contraseñas no coinciden', style: TextStyle(color: PucaraColors.danger));
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.setPhoneNumber,
              style: const TextStyle(color: Colors.white),
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: pucaraInputDecoration(
                hint: 'Número de teléfono',
                icon: Icons.phone_outlined,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            Obx(
              () => PucaraPrimaryButton(
                label: 'SOLICITAR ACCESO',
                onPressed: controller.isLoading.value || !controller.canRegister ? null : controller.register,
                isLoading: controller.isLoading.value,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => controller.errorMessage.value.isNotEmpty
                  ? Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: PucaraColors.danger),
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
