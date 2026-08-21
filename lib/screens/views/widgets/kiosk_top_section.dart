import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/working_mode.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/serial_provider.dart';
import '../../../providers/settings_provider.dart';
import 'package:window_manager/window_manager.dart';

class KioskTopSection extends StatelessWidget {
  final ResponsiveConfig config;

  final String leftTitle;
  final String leftSubtitle;
  final String rightImage;

  final Color leftColor;
  final bool isError;

  const KioskTopSection({
    super.key,
    required this.config,
    required this.rightImage,
    this.leftTitle = "Digital Smart Healthcare",
    this.leftSubtitle = "",
    this.leftColor = Colors.white,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );

    final horizontalPadding = config.scale(40);
    final spacing = config.scale(12);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: config.scale(8),
      ),
      child: KioskCardBox(
        isError: isError,
        child: Row(
          children: [
        
            Expanded(
            flex: 1,
            child: GestureDetector(
              onDoubleTap: () async {
             
              },
              child:  Image.asset('assets/images/logo_main.png', fit: BoxFit.contain)
            ),
          ),

          /// ================= RIGHT (IMAGE CARD) =================
          Expanded(
            flex: 1,
            child: GestureDetector(
              onDoubleTap: () async {
                /// อ่าน provider ก่อน await กัน context ข้าม async gap
                final serial = context.read<SerialProvider>();
                final auth = context.read<AuthProvider>();

                /// ✅ ถามยืนยันก่อนปิดโปรแกรม
                final confirmed = await _confirmExit(context);
                if (confirmed != true) return;

                /// ✅ ANDROID
                if (!kIsWeb && Platform.isAndroid) {
                  serial.stop();
                  await auth.logout();
                  SystemNavigator.pop();
                  return;
                }

                /// ✅ DESKTOP
                if (!kIsWeb &&
                    (Platform.isWindows ||
                        Platform.isLinux ||
                        Platform.isMacOS)) {
                  serial.stop();
                  await auth.logout();
                  await windowManager.close();
                }
              },
              child: rightImage.startsWith('assets/')
                  ? Image.asset(rightImage, fit: BoxFit.contain)
                  : Image.file(File(rightImage), fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    ),
  );
  }

  /// Dialog ยืนยันก่อนปิดโปรแกรม
  Future<bool?> _confirmExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: const [
            Icon(Icons.power_settings_new_rounded,
                color: Color(0xFFE53E3E), size: 30),
            SizedBox(width: 10),
            Text(
              'ปิดโปรแกรม',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'THSarabunNew',
              ),
            ),
          ],
        ),
        content: const Text(
          'คุณต้องการปิดโปรแกรมใช่หรือไม่?',
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'THSarabunNew',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.darkGray,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'THSarabunNew',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ปิดโปรแกรม',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'THSarabunNew',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KioskCardBox extends StatelessWidget {
  final Widget child;
  final bool isError;
  final Color backgroundColor;

  const KioskCardBox({
    super.key,
    required this.child,
    this.isError = false,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: backgroundColor,
        // borderRadius: BorderRadius.circular(14),
        // border: Border.all(
        //   color: isError ? Colors.red.shade300 : Colors.grey.shade300,
        //   width: 2,
        // ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.15),
        //     blurRadius: 16,
        //     spreadRadius: 2,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
