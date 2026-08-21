import 'breakpoints.dart';

class ResponsiveConfig {
  final double width;
  final double height;

  ResponsiveConfig({
    required this.width,
    required this.height,
  });

  bool get isLandscape => width > height;

  double scale(double size) {
    if (width >= Breakpoints.tablet) return size * 1.2;
    if (width >= Breakpoints.mobile) return size * 1.1;
    return size;
  }
}
