import 'package:pronosticosapp/features/weather/domain/site_variables.dart';

/// Logo de cada empresa para los PDF, según el nombre que llega del backend
/// (por ejemplo "Teniente", "Codelco División El Teniente" o "MLP").
class CompanyLogos {
  static const _base = 'assets/images/company_logos/';

  /// Palabras del nombre de la empresa → archivo del logo.
  static const Map<String, List<String>> _keywords = {
    'el_teniente.png': ['teniente', 'codelco'],
    'los_pelambres.png': ['pelambres', 'mlp', 'antofagasta'],
    'caserones.png': ['caserones', 'lundin'],
    'quebrada_blanca.png': ['blanca', 'teck', 'qb'],
  };

  /// Ruta del asset, o null si la empresa no tiene logo.
  static String? assetFor(String? companyName) {
    if (companyName == null || companyName.trim().isEmpty) return null;
    final words = SiteVariables.normalize(companyName).split(' ');
    for (final entry in _keywords.entries) {
      if (entry.value.any(words.contains)) return '$_base${entry.key}';
    }
    return null;
  }
}
