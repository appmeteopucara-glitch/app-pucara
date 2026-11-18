/// Variables del pronóstico que aplican a cada faena, según el Excel
/// "Listado de variables" del cliente. Están fijas en la app.
enum ForecastVar {
  cloud, // cobertura nubosa (ícono)
  temp, // temperatura mín/máx
  isoMinMax, // nivel de isoterma 0°C máximo / mínimo
  isoHeight, // altura de isoterma 0°C
  electric, // prob. actividad eléctrica
  precip, // prob. precipitación
  water, // acumulación de agua
  snow, // acumulación de nieve
  windIntensity, // intensidad del viento
  gust, // rachas máximas
  windDir, // dirección del viento
  humidity, // humedad relativa
}

class SiteVariables {
  static const _snowRain = {
    ForecastVar.precip,
    ForecastVar.water,
    ForecastVar.snow,
  };

  static const _basicMine = {
    ForecastVar.cloud,
    ForecastVar.electric,
    ForecastVar.water,
    ForecastVar.snow,
    ForecastVar.windIntensity,
    ForecastVar.gust,
    ForecastVar.windDir,
    ForecastVar.temp,
  };

  /// Clave: nombre de la faena normalizado (ver [normalize]).
  static final Map<String, Set<ForecastVar>> _bySite = {
    // (1) El Teniente
    'joachim': {
      ForecastVar.cloud,
      ForecastVar.isoMinMax,
      ForecastVar.electric,
      ForecastVar.precip,
      ForecastVar.water,
      ForecastVar.snow,
      ForecastVar.windIntensity,
      ForecastVar.gust,
      ForecastVar.windDir,
      ForecastVar.temp,
    },
    'adit 42': _snowRain,
    'sewell': _snowRain,
    // (2) Los Pelambres
    'los pelambres': {..._basicMine, ForecastVar.isoMinMax},
    'el chacay': _basicMine,
    'el mauro': _basicMine,
    'punta chungo': _basicMine,
    // (3) Caserones
    'mina plantas': {
      ForecastVar.cloud,
      ForecastVar.electric,
      ForecastVar.precip,
      ForecastVar.water,
      ForecastVar.snow,
      ForecastVar.windIntensity,
      ForecastVar.gust,
      ForecastVar.windDir,
      ForecastVar.temp,
      ForecastVar.humidity,
    },
    'planta piloto muro': {
      ForecastVar.cloud,
      ForecastVar.electric,
      ForecastVar.water,
      ForecastVar.snow,
      ForecastVar.windIntensity,
      ForecastVar.gust,
      ForecastVar.temp,
    },
    'carrizalillo': {
      ForecastVar.cloud,
      ForecastVar.electric,
      ForecastVar.water,
      ForecastVar.snow,
      ForecastVar.windIntensity,
      ForecastVar.gust,
      ForecastVar.temp,
    },
    // (4) Teck Quebrada Blanca ("Cordillera" y "Mina" son el mismo sitio)
    'mina': {
      ForecastVar.cloud,
      ForecastVar.isoHeight,
      ForecastVar.electric,
      ForecastVar.precip,
      ForecastVar.water,
      ForecastVar.snow,
      ForecastVar.windIntensity,
      ForecastVar.gust,
      ForecastVar.windDir,
      ForecastVar.temp,
      ForecastVar.humidity,
    },
    'cordillera': {
      ForecastVar.cloud,
      ForecastVar.isoHeight,
      ForecastVar.electric,
      ForecastVar.precip,
      ForecastVar.water,
      ForecastVar.snow,
      ForecastVar.windIntensity,
      ForecastVar.gust,
      ForecastVar.windDir,
      ForecastVar.temp,
      ForecastVar.humidity,
    },
    'variante a97b': {
      ForecastVar.electric,
      ForecastVar.precip,
      ForecastVar.water,
      ForecastVar.snow,
    },
    'pampa': {
      ForecastVar.electric,
      ForecastVar.precip,
      ForecastVar.water,
      ForecastVar.snow,
    },
    'puerto': {
      ForecastVar.electric,
      ForecastVar.precip,
      ForecastVar.water,
      ForecastVar.snow,
    },
  };

  /// Minúsculas, sin tildes y sin signos: "Mina - Plantas" → "mina plantas".
  static String normalize(String value) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    var out = value.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// Faenas cuyo nombre es ambiguo entre empresas: solo valen si la empresa
  /// de la faena contiene alguna de estas palabras.
  static const Map<String, List<String>> _companyHints = {
    'mina': ['blanca', 'teck', 'qb'],
    'cordillera': ['blanca', 'teck', 'qb'],
  };

  /// Variables de la faena, o `null` si no está en el listado del cliente
  /// (en ese caso se muestran todas). Acepta nombres con texto extra, como
  /// "ADIT 42 - Teniente": gana la clave más larga contenida en el nombre.
  static Set<ForecastVar>? forSiteName(String? name, {String? company}) {
    if (name == null || name.trim().isEmpty) return null;
    final n = normalize(name);
    final companyN = normalize(company ?? '');

    bool allowed(String key) {
      final hints = _companyHints[key];
      if (hints == null) return true;
      return hints.any(companyN.contains);
    }

    final exact = _bySite[n];
    if (exact != null && allowed(n)) return exact;

    String? best;
    for (final key in _bySite.keys) {
      if (!' $n '.contains(' $key ') || !allowed(key)) continue;
      if (best == null || key.length > best.length) best = key;
    }
    if (best != null) return _bySite[best];

    // Último recurso: nombres con errores de tipeo ("Sewel", "Sewe", "Pelambre").
    final tokens = n.split(' ');
    String? fuzzy;
    var fuzzyScore = 1 << 20;
    for (final key in _bySite.keys) {
      if (key.length < 5 || !allowed(key)) continue;
      final words = key.split(' ').length;
      final maxDistance = key.length >= 8 ? 2 : 1;
      for (var i = 0; i + words <= tokens.length; i++) {
        final window = tokens.sublist(i, i + words).join(' ');
        var score = _distance(window, key);
        if (words == 1 && window.length >= 4 && key.startsWith(window)) score = 0;
        if (score <= maxDistance && score < fuzzyScore) {
          fuzzy = key;
          fuzzyScore = score;
        }
      }
    }
    return fuzzy == null ? null : _bySite[fuzzy];
  }

  /// Distancia de edición (Levenshtein).
  static int _distance(String a, String b) {
    if (a == b) return 0;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = <int>[i];
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur.add([prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y));
      }
      prev = cur;
    }
    return prev.last;
  }
}
