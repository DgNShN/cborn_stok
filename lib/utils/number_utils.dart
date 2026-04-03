import 'package:intl/intl.dart';

const double maxStockValue = 1000000;
const double maxPriceValue = 1000000000;

String formatNumber(
  double value, {
  int decimals = 2,
  bool trimTrailingZeros = false,
}) {
  if (!value.isFinite) {
    return 'Gecersiz';
  }

  if (value.abs() > maxPriceValue * 1000) {
    return 'Asiri buyuk';
  }

  final pattern = trimTrailingZeros ? '#,##0.##' : '#,##0.${'0' * decimals}';
  return NumberFormat(pattern, 'tr_TR').format(value);
}

double parseInputNumber(String text) {
  return double.parse(text.trim().replaceAll('.', '').replaceAll(',', '.'));
}

String? validateStockNumber(
  String? value, {
  double max = maxStockValue,
  bool allowZero = true,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Zorunlu alan';
  final parsed = double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
  if (parsed == null) return 'Gecerli sayi gir';
  if (!allowZero && parsed <= 0) return 'Sifirdan buyuk olmali';
  if (allowZero && parsed < 0) return 'Negatif olamaz';
  if (parsed > max) return 'En fazla ${formatNumber(max, trimTrailingZeros: true)} olabilir';
  return null;
}

String? validatePriceNumber(String? value) {
  return validateStockNumber(
    value,
    max: maxPriceValue,
  );
}
