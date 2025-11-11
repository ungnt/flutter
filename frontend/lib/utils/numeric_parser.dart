class NumericParser {
  static double? parseDoubleOrNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value
        .trim()
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d.-]'), '');

    try {
      return double.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  static double parseDouble(String? value, {double defaultValue = 0.0}) {
    return parseDoubleOrNull(value) ?? defaultValue;
  }

  static int? parseIntOrNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^\d-]'), '');

    try {
      return int.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  static int parseInt(String? value, {int defaultValue = 0}) {
    return parseIntOrNull(value) ?? defaultValue;
  }
}
