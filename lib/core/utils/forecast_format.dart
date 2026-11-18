/// Texto para una variable opcional: placeholder cuando no hay dato.
const String kNoData = '—';

String fmtNum(num? value, [String unit = '']) {
  if (value == null) return kNoData;
  final text = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  return unit.isEmpty ? text : '$text $unit';
}

String fmtDeg(num? value) => value == null ? kNoData : '${fmtNum(value)}°C';

String fmtRange(num? a, num? b, [String unit = '']) {
  if (a == null && b == null) return kNoData;
  final suffix = unit.isEmpty ? '' : ' $unit';
  return '${a == null ? kNoData : fmtNum(a)} / ${b == null ? kNoData : fmtNum(b)}$suffix';
}

String fmtText(String? value) =>
    (value == null || value.trim().isEmpty) ? kNoData : value;
