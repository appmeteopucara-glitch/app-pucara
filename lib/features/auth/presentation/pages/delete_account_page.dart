import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/features/auth/data/auth_providers.dart';
import 'package:pronosticosapp/features/auth/domain/usecases/delete_account.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _passwordController.text.isNotEmpty && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await DeleteAccount(buildAuthRepository())(_passwordController.text);
    if (!mounted) return;

    if (result.success) {
      await _closeSession('Tu cuenta fue eliminada');
      return;
    }
    if (result.sessionExpired) {
      await _closeSession('Tu sesión expiró. Inicia sesión nuevamente.');
      return;
    }
    setState(() {
      _loading = false;
      _error = result.message;
      if (result.statusCode == 400) _passwordController.clear();
    });
  }

  Future<void> _closeSession(String message) async {
    await TokenStorage.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    Get.offAllNamed(AppRoutes.auth);
  }

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
                      onPressed: _loading ? null : Get.back,
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const PucaraSectionTitle(
                  title: 'Eliminar cuenta',
                  subtitle: 'Esta acción no se puede deshacer.',
                ),
                const SizedBox(height: 22),
                const PucaraPanel(
                  child: Text(
                    'Se eliminarán tu nombre, correo y teléfono, y no podrás volver a iniciar sesión con esta cuenta. Los pronósticos que creaste se conservan para tu empresa, sin tu nombre. Esta acción no se puede deshacer.',
                    style: TextStyle(
                      color: PucaraColors.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  enabled: !_loading,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  autofillHints: const [AutofillHints.password],
                  decoration: pucaraInputDecoration(
                    hint: 'Contraseña',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: PucaraColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error,
                    style: const TextStyle(color: PucaraColors.danger, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PucaraColors.danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF35506B),
                    disabledForegroundColor: Colors.white70,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Eliminar mi cuenta'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading ? null : Get.back,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
