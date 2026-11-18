import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';

/// Pantalla intermedia para elegir con qué empresa trabajar cuando el usuario
/// tiene acceso a más de una. Se abre tras el login o desde "Cambiar empresa".
class SelectCompanyPage extends StatefulWidget {
  const SelectCompanyPage({super.key});

  @override
  State<SelectCompanyPage> createState() => _SelectCompanyPageState();
}

class _SelectCompanyPageState extends State<SelectCompanyPage> {
  List<Map<String, dynamic>> _companies = [];
  String? _pendingId; // elegida en el select, aún sin confirmar
  bool _loading = true;
  late final bool _fromHome;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _fromHome = args is Map && args['fromHome'] == true;
    _load();
  }

  Future<void> _load() async {
    final companies = await TokenStorage.getCompanies();
    companies.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
    final selected = await TokenStorage.getSelectedCompanyId();
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _pendingId = selected;
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    final id = _pendingId;
    if (id == null) return;
    await TokenStorage.saveSelectedCompanyId(id);
    if (_fromHome) {
      Get.back(result: true);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_fromHome)
                        IconButton(
                          onPressed: Get.back,
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        ),
                      const Spacer(),
                      if (!_fromHome)
                        TextButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Cerrar sesión'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const PucaraSectionTitle(
                    title: 'Selecciona una empresa',
                    subtitle: 'Tu usuario tiene acceso a varias. Podrás cambiarla cuando quieras.',
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator(color: PucaraColors.accentBright)),
                    )
                  else if (_companies.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Tu usuario no tiene empresas asignadas.',
                          style: TextStyle(color: PucaraColors.textSecondary),
                        ),
                      ),
                    )
                  else ...[
                    InputDecorator(
                      decoration: pucaraInputDecoration(
                        hint: 'Selecciona una empresa',
                        icon: Icons.business_outlined,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF122540),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          iconEnabledColor: Colors.white,
                          isExpanded: true,
                          value: _companies.any((c) => c['id'].toString() == _pendingId) ? _pendingId : null,
                          hint: const Text(
                            'Selecciona una empresa',
                            style: TextStyle(color: PucaraColors.textSecondary),
                          ),
                          items: _companies
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c['id'].toString(),
                                  child: Text((c['name'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _pendingId = value),
                        ),
                      ),
                    ),
                    const Spacer(),
                    PucaraPrimaryButton(
                      label: 'CONTINUAR',
                      onPressed: _pendingId == null ? null : _confirm,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
