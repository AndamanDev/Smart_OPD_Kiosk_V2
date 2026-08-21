import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Primary Green / เขียวหลัก
  static const Color primaryGreen = Color(0xFF1F7A3D);

  /// Dark Green / เขียวเข้ม
  static const Color darkGreen = Color(0xFF14532D);

  /// Light Green / พื้นหลังอ่อน
  static const Color lightGreen = Color(0xFFEAF7EF);

  /// Dark Gray / ข้อความ
  static const Color darkGray = Color(0xFF374151);

  /// Border / เส้นขอบ
  static const Color border = Color(0xFFE5E7EB);

  static const Color white = Color(0xFFFFFFFF);
} 

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryGreen,
        onPrimary: Colors.white,
        primaryContainer: AppColors.darkGreen,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.lightGreen,
        onSecondary: AppColors.darkGray,
        surface: Colors.white,
        onSurface: AppColors.darkGray,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.lightGreen,
      fontFamily: 'THSarabunNew',
      textTheme: const TextTheme().copyWith(
        bodyLarge: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.darkGray),
        bodyMedium: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.darkGray),
        bodySmall: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.darkGray),
        titleLarge: TextStyle(fontFamily: 'THSarabunNew', 
          color: AppColors.darkGray,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(fontFamily: 'THSarabunNew', 
          color: AppColors.darkGray,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(fontFamily: 'THSarabunNew', 
          color: AppColors.darkGray,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(fontFamily: 'THSarabunNew', 
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontFamily: 'THSarabunNew', 
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          textStyle: TextStyle(fontFamily: 'THSarabunNew', 
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          textStyle: TextStyle(fontFamily: 'THSarabunNew', 
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: TextStyle(fontFamily: 'THSarabunNew', 
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        labelStyle: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.darkGray),
        hintStyle: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.darkGray.withOpacity(0.5)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 6,
        shadowColor: const Color(0x0F000000), // rgba(0,0,0,0.06)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.primaryGreen,
      ),
    );
  }
}

/// Soft shadow decoration ตามสเปค:
/// border-radius: 16px | box-shadow: 0 6px 24px rgba(0,0,0,0.06) | background: #FFFFFF
class AppCardDecoration {
  AppCardDecoration._();

  static BoxDecoration get standard => const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000), // rgba(0,0,0,0.06)
            blurRadius: 24,
            spreadRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      );

      static BoxDecoration get standardtop => BoxDecoration(
        color: Color(0xFF5A5A5A),
        borderRadius: BorderRadius.circular(32),
      );
}

/// Widget helper — ใช้แทน Card ทั่วแอพ
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration ?? AppCardDecoration.standard,
      child: child,
    );
  }
}
