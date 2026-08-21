class ScaleReading {
  final double weight;
  final double height;
  final double bmi;

  const ScaleReading({
    required this.weight,
    required this.height,
    required this.bmi,
  });

  bool get isValid => weight > 0 && height > 0;
}

class ScaleUtils {
  static ScaleReading parse(String raw) {
    try {
      final parts = raw.split(',');

      if (parts.length != 4) {
        return const ScaleReading(weight: 0, height: 0, bmi: 0);
      }

      if (parts[0] != "SCALE") {
        return const ScaleReading(weight: 0, height: 0, bmi: 0);
      }

      return ScaleReading(
        weight: double.tryParse(parts[1]) ?? 0,
        height: double.tryParse(parts[2]) ?? 0,
        bmi: double.tryParse(parts[3]) ?? 0,
      );
    } catch (_) {
      return const ScaleReading(weight: 0, height: 0, bmi: 0);
    }
  }
}
