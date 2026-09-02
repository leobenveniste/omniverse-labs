class PortionCalculator {
  static double calculateAmount({
    required double baseAmount,
    required int baseServings,
    required int targetServings,
  }) {
    if (baseAmount <= 0 || baseServings <= 0 || targetServings <= 0) {
      return baseAmount;
    }
    return (baseAmount / baseServings) * targetServings;
  }

  static String formatAmount(double amount) {
    if (amount <= 0) return '';

    final whole = amount.floor();
    final remainder = amount - whole;

    if (remainder.abs() < 0.05) {
      return whole.toString();
    }

    if ((remainder - 0.5).abs() < 0.05) {
      return whole == 0 ? '½' : '$whole ½';
    }
    if ((remainder - 0.25).abs() < 0.05) {
      return whole == 0 ? '¼' : '$whole ¼';
    }
    if ((remainder - 0.75).abs() < 0.05) {
      return whole == 0 ? '¾' : '$whole ¾';
    }
    if ((remainder - 0.33).abs() < 0.06) {
      return whole == 0 ? '⅓' : '$whole ⅓';
    }
    if ((remainder - 0.66).abs() < 0.06) {
      return whole == 0 ? '⅔' : '$whole ⅔';
    }

    if (amount >= 100) {
      return amount.round().toString();
    } else if (amount >= 10) {
      return amount.toStringAsFixed(1).replaceAll('.0', '');
    } else {
      return amount.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }

  static String formatIngredientDisplay({
    required double amount,
    required String unit,
    required String name,
    String? notes,
  }) {
    final buffer = StringBuffer();
    if (amount > 0) {
      buffer.write(formatAmount(amount));
      buffer.write(' ');
    }
    if (unit.trim().isNotEmpty) {
      buffer.write(unit.trim());
      buffer.write(' ');
    }
    buffer.write(name.trim());
    if (notes != null && notes.trim().isNotEmpty) {
      buffer.write(' (${notes.trim()})');
    }
    return buffer.toString().trim();
  }

  static String formatIngredientAmount(double amount, String unit) {
    final formatted = formatAmount(amount);
    if (formatted.isEmpty) return unit.trim();
    if (unit.trim().isEmpty) return formatted;
    return '$formatted ${unit.trim()}';
  }
}
