import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pronosticosapp/features/auth/data/auth_providers.dart';
import 'package:pronosticosapp/features/auth/domain/usecases/register_user.dart';
import 'package:pronosticosapp/features/auth/domain/usecases/login_user.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/storage/company_session.dart';

class AuthController extends GetxController {
  // Variables para login y registro
  final email = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final name = ''.obs;
  final firstName = ''.obs;
  final lastName = ''.obs;
  final phoneNumber = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final tabIndex = 0.obs;

  void setEmail(String value) => email.value = value;
  void setPassword(String value) => password.value = value;
  void setConfirmPassword(String value) => confirmPassword.value = value;
  void setName(String value) => name.value = value;
  void setFirstName(String value) => firstName.value = value;
  void setLastName(String value) => lastName.value = value;
  void setPhoneNumber(String value) => phoneNumber.value = value;
  void changeTab(int index) => tabIndex.value = index;

  bool get isEmailValid => email.value.isEmail;
  bool get isPasswordValid => password.value.length >= 6;
  bool get arePasswordsEqual => password.value == confirmPassword.value;
  bool get canRegister =>
      isEmailValid && isPasswordValid && arePasswordsEqual && firstName.value.isNotEmpty && lastName.value.isNotEmpty;
  bool get canLogin => isEmailValid && isPasswordValid;

  void _safeShowSnack(String title, String message) {
    final ctx = Get.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Aceptar')),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        barrierDismissible: true,
      );
    }
  }

  // Método para login
  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      errorMessage.value = 'Por favor, completa todos los campos';
      return;
    }
    if (!email.value.isEmail) {
      errorMessage.value = 'Correo inválido';
      return;
    }
    if (password.value.length < 6) {
      errorMessage.value = 'La contraseña debe tener al menos 6 caracteres';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final repo = buildAuthRepository();
      final usecase = LoginUser(repo);
      final result = await usecase(LoginParams(email: email.value, password: password.value));
      if (result.success && result.token.isNotEmpty) {
        await TokenStorage.saveToken(result.token, expiresAtUtc: result.expiresAtUtc);
        if (result.roles.isNotEmpty) {
          await TokenStorage.saveRoles(result.roles);
        }
        await CompanySession.saveFromLogin(result.companies.map((c) => c.toJson()).toList());
        final next = await CompanySession.nextRoute();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(next);
        });
      } else if (result.statusCode == 403) {
        final ctx = Get.context;
        const msg = 'Tu cuenta aún no ha sido aprobada. Pronto un administrador te dará acceso.';
        if (ctx != null) {
          showDialog(
            context: ctx,
            barrierDismissible: false,
            builder: (context) {
              final primary = Theme.of(context).colorScheme.primary;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(Icons.info_rounded, color: primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Cuenta pendiente de aprobación',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      msg,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cuando sea aprobada podrás iniciar sesión.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              );
            },
          );
        } else {
          Get.dialog(
            Builder(builder: (context) {
              final primary = Theme.of(context).colorScheme.primary;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(Icons.info_rounded, color: primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Cuenta pendiente de aprobación',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      msg,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cuando sea aprobada podrás iniciar sesión.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              );
            }),
            barrierDismissible: false,
          );
        }
      } else {
        _safeShowSnack('Credenciales inválidas', 'Verifica tu correo y contraseña');
      }
    } catch (e) {
      debugPrint('[AuthController] Login error: $e');
      _safeShowSnack('Credenciales inválidas', 'Las credenciales son incorrectas, vuelve a intentarlo.');
    } finally {
      isLoading.value = false;
    }
  }

  // Método para registro
  Future<void> register() async {
    if (email.value.isEmpty || password.value.isEmpty || confirmPassword.value.isEmpty) {
      errorMessage.value = 'Por favor, completa todos los campos';
      return;
    }
    if (!email.value.isEmail) {
      errorMessage.value = 'Correo inválido';
      return;
    }
    if (password.value.length < 6) {
      errorMessage.value = 'La contraseña debe tener al menos 6 caracteres';
      return;
    }

    if (password.value != confirmPassword.value) {
      errorMessage.value = 'Las contraseñas no coinciden';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final repo = buildAuthRepository();
      final usecase = RegisterUser(repo);
      final fn = firstName.value.trim();
      final ln = lastName.value.trim();
      if (fn.isEmpty || ln.isEmpty) {
        errorMessage.value = 'Por favor, completa nombres y apellidos';
        isLoading.value = false;
        return;
      }
      final phoneClean = phoneNumber.value.replaceAll(RegExp(r'\D'), '');
      final result = await usecase(RegisterParams(
        firstName: fn,
        lastName: ln,
        email: email.value,
        password: password.value,
        confirmPassword: confirmPassword.value,
        phoneNumber: phoneClean,
      ));
      debugPrint('[AuthController] RegisterResult success=${result.success} message=${result.message}');
      if (result.success) {
        try {
          final ctx = Get.context;
          final msg = result.message.isNotEmpty
              ? result.message
              : 'Tu solicitud de registro fue enviada correctamente y está pendiente de aprobación. '
                  'Te notificaremos cuando un administrador habilite tu acceso.';
          if (ctx != null) {
            showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (context) {
                final primary = Theme.of(context).colorScheme.primary;
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.mark_email_read_rounded, color: primary),
                      const SizedBox(width: 8),
                      const Text('¡Registro enviado!'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg),
                      const SizedBox(height: 8),
                      const Text(
                        'Mientras tanto, puedes ir al inicio de sesión.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        changeTab(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ir a iniciar sesión'),
                    ),
                  ],
                );
              },
            );
          } else {
            Get.dialog(
              Builder(builder: (context) {
                final primary = Theme.of(context).colorScheme.primary;
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.mark_email_read_rounded, color: primary),
                      const SizedBox(width: 8),
                      const Text('¡Registro enviado!'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg),
                      const SizedBox(height: 8),
                      const Text(
                        'Mientras tanto, puedes ir al inicio de sesión.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        changeTab(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ir a iniciar sesión'),
                    ),
                  ],
                );
              }),
              barrierDismissible: false,
            );
          }
        } catch (e) {
          debugPrint('[AuthController] Dialog error: $e');
          changeTab(0);
        }
      } else {
        errorMessage.value = '';
        _safeShowSnack('Registro fallido', 'No se pudo completar el registro. Contacta a un administrador.');
      }
    } catch (e) {
      debugPrint('[AuthController] Register error: $e');
      errorMessage.value = '';
      _safeShowSnack('Registro fallido', 'No se pudo completar el registro. Contacta a un administrador.');
    } finally {
      isLoading.value = false;
    }
  }
}
