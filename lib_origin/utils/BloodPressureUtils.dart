import 'package:flutter/material.dart';

class BloodReading {
  final int systolic;
  final int diastolic;
  final int pulse;

  const BloodReading({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
  });

  bool get isEmpty => systolic == 0 && diastolic == 0 && pulse == 0;
}

class BloodPressureUtils {

  static BloodReading parse(String raw) {
    final parts = raw.split(',');

    if (parts.length < 10) {
      debugPrint("Invalid packet: $raw");
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }

    final sys = int.tryParse(parts[7].trim());
    final dia = int.tryParse(parts[8].trim());
    final pul = int.tryParse(parts[9].trim());

    if (sys == null || dia == null || pul == null) {
      debugPrint("Parse error: $raw");
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }

    return BloodReading(
      systolic: sys,
      diastolic: dia,
      pulse: pul,
    );
  }

  /// ---------- Validation ----------
  static bool isValid(int s, int d, int p) {
    if (s < 60 || s > 250) return false;
    if (d < 30 || d > 150) return false;
    if (p < 30 || p > 200) return false;
    return true;
  }

  /// ---------- Colors ----------
  static Color sysColor(int v, int max) {
    if (v == 0) return Colors.grey;
    if (v < (max - 20)) return Colors.green;
    if (v < max) return Colors.orange;
    return Colors.red;
  }

  static Color diaColor(int v) {
    if (v == 0) return Colors.grey;
    if (v < 80) return Colors.green;
    if (v < 90) return Colors.orange;
    return Colors.red;
  }

  static Color pulseColor(int v) {
    if (v == 0) return Colors.grey;
    if (v < 60 || v > 100) return Colors.orange;
    return Colors.green;
  }
}
