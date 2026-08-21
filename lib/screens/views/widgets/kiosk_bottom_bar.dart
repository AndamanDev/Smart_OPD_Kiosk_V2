import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/kiosk_state_provider.dart';
import '../../../providers/serial_provider.dart';
import '../../../providers/server_status_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers_server/sound_server.dart';

class KioskBottomBar extends StatelessWidget {
  final ResponsiveConfig config;
  const KioskBottomBar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = config.scale(40);
    final base = (config.width * 0.025).clamp(14, 28).toDouble();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: base * 0.3,
      ),
      color: AppColors.white,
          child: Card(
            color: const Color.fromARGB(255, 241, 241, 241),
            elevation: 3,
            shadowColor: const Color(0x0F000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: base * 0.6,
                vertical: base * 0.3,
              ),
              child: Row(
                children: [
                  /// ---- LEFT ----
                  Expanded(child: _connect(context, base)),

                  SizedBox(width: base * 0.4),

                  /// ---- RIGHT ----
                  _setting(context, base),
                ],
              ),
            ),
          ),
        );
  }

  // =========================================================
  // CONNECTION STATUS
  // =========================================================
  Widget _connect(BuildContext context, double base) {
    return Consumer<ServerStatusProvider>(
      builder: (_, server, __) {
        Widget iconWidget;
        Color color;
        String text;

        switch (server.state) {
          case AuthConnectionState.connected:
            iconWidget = Image.asset(
              'assets/images/wifi_connected.png',
              width: 36,
              height: 36,
            );
            color = AppColors.primaryGreen;
            text = "เชื่อมต่อแล้ว";
            break;

          case AuthConnectionState.reconnecting:
            iconWidget = Icon(Icons.sync, size: 28, color: Colors.orange);
            color = Colors.orange;
            text = "กำลังเชื่อมต่อใหม่...";
            break;

          case AuthConnectionState.disconnected:
            iconWidget = Icon(Icons.cloud_off, size: 28, color: Colors.red);
            color = Colors.red;
            text = "ขาดการเชื่อมต่อ";
            break;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,

            SizedBox(width: base * 0.4),

            Flexible(
              flex: 2,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 26,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(width: base * 0.6),

            Container(width: 1, height: base * 0.8, color: Colors.grey),

            SizedBox(width: base * 0.6),

            Consumer<SettingsProvider>(
              builder: (_, s, __) {
                return Flexible(
                  flex: 6,
                  child: Text(
                    "ชื่อเครื่อง ${s.deviceName} "
                    "[${s.workingMode.name == 'combined'
                        ? '${s.scaleDevice.name} -> ${s.bpDevice.name}'
                        : s.workingMode.name == 'scaleOnly'
                        ? s.scaleDevice.name
                        : s.workingMode.name == 'bloodPressureOnly'
                        ? s.bpDevice.name
                        : ''}]",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SETTINGS / HOME
  // =========================================================

  Widget _setting(BuildContext context, double base) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: base * 0.8, color: Colors.grey),

        Flexible(
          child: TextButton(
            style: TextButton.styleFrom(
              overlayColor: AppColors.primaryGreen.withOpacity(0.15),
            ),
            onPressed: () async {
              final confirmed = await _showPinDialog(context);
              if (confirmed != true) return;

              context.read<SoundServer>().stop();

              final serial = context.read<SerialProvider>();
              serial.stop();

              context.read<KioskStageProvider>().reset(serial);
              context.read<KioskStageProvider>().setStage(KioskStage.settings);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/i_setting.png',
                  width: 36,
                  height: 36,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  "Setting",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: base * 0.3),

        Container(width: 1, height: base * 0.8, color: Colors.grey),

        SizedBox(width: base * 0.6),
        InkWell(
          borderRadius: BorderRadius.circular(100),
          splashColor: AppColors.primaryGreen.withOpacity(0.2),
          onTap: () async {
            // context.read<SoundServer>().stop();

            // final serial = context.read<SerialProvider>();
            // serial.stop();

            // context.read<KioskStageProvider>().reset(serial);

            // context.read<KioskStageProvider>().reset(serial);

            final auth = context.read<AuthProvider>();

            final serial = context.read<SerialProvider>();
            serial.stop();

            await auth.logout();

            context.read<KioskStageProvider>().setStage(KioskStage.loading);
          },
          child: Container(
            padding: EdgeInsets.all(base * 0.1),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            // child: Icon(Icons.home, size: base * 1.3, color: Colors.blue),
            child: Image.asset(
              'assets/images/i_home.png',
              width: 36,
              height: 36,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PIN DIALOG
  // =========================================================

  Future<bool?> _showPinDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _PinDialog(),
    );
  }
}

// =========================================================
// PIN DIALOG WIDGET
// =========================================================

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  static const String _correctPin = '10210';
  static const int _pinLength = 5;

  String _pin = '';
  bool _hasError = false;

  void _onKey(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _hasError = false;
    });
    if (_pin.length == _pinLength) {
      _verify();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _hasError = false;
    });
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _hasError = false;
    });
  }

  void _verify() {
    if (_pin == _correctPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _hasError = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    // scale ตามความสูงหน้าจอ เพื่อให้ dialog ไม่เกินจอ
    final maxDialogH = screen.height * 0.92;
    // dialog กว้าง 38% แต่ clamp ไว้
    final dialogW = (screen.width * 0.38).clamp(300.0, 520.0);

    // scale คำนวณจากความสูงจอ → กันปุ่มเกินจอแนวตั้ง
    final scaleByW = dialogW / 420;
    final scaleByH = (maxDialogH / 700).clamp(0.6, 1.2); // 700 คือ content ปกติ
    final scale = scaleByW < scaleByH ? scaleByW : scaleByH;

    final iconBox = 56.0 * scale;
    final iconSize = 30.0 * scale;
    final dotSize = 18.0 * scale;
    final dotMargin = 9.0 * scale;
    final btnW = 80.0 * scale;
    final btnH = 58.0 * scale;
    final btnFontSize = 24.0 * scale;
    final backIconSize = 22.0 * scale;
    final hPad = 28.0 * scale;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.04,
        vertical: screen.height * 0.04,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogW,
          maxHeight: maxDialogH,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 40,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header bar ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1F7A3D), Color(0xFF2E9E55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_rounded,
                          size: iconSize, color: Colors.white),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      'กรุณาป้อนรหัสเพื่อตั้งค่า',
                      style: TextStyle(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'THSarabunNew',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body (scrollable) ────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      hPad, 20 * scale, hPad, 18 * scale),
                  child: Column(
                    children: [
                      // PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pinLength, (i) {
                          final filled = i < _pin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin:
                                EdgeInsets.symmetric(horizontal: dotMargin),
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hasError
                                  ? const Color(0xFFE53E3E)
                                  : filled
                                      ? const Color(0xFF1F7A3D)
                                      : const Color(0xFFEAF7EF),
                              border: Border.all(
                                color: _hasError
                                    ? const Color(0xFFE53E3E)
                                    : filled
                                        ? const Color(0xFF1F7A3D)
                                        : const Color(0xFFB0D6BC),
                                width: 2,
                              ),
                              boxShadow: filled && !_hasError
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x441F7A3D),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),

                      // Error message
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _hasError
                            ? Container(
                                key: const ValueKey('err'),
                                margin: EdgeInsets.only(top: 10 * scale),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14 * scale,
                                    vertical: 7 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5F5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFEB2B2),
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: const Color(0xFFE53E3E),
                                        size: 16 * scale),
                                    SizedBox(width: 6 * scale),
                                    Text(
                                      'รหัส PIN ไม่ถูกต้อง กรุณาลองใหม่',
                                      style: TextStyle(
                                        color: const Color(0xFFE53E3E),
                                        fontSize: 14 * scale,
                                        fontFamily: 'THSarabunNew',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(
                                key: const ValueKey('no_err'),
                                height: 10 * scale),
                      ),

                      SizedBox(height: 16 * scale),

                      // Number pad
                      ..._buildNumPad(
                          btnW, btnH, btnFontSize, backIconSize, scale),

                      SizedBox(height: 14 * scale),

                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10 * scale),
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'ยกเลิก',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontFamily: 'THSarabunNew',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNumPad(double btnW, double btnH, double fontSize,
      double backIconSize, double scale) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    Widget buildKey(String key) {
      final isDelete = key == '⌫';
      final isClear = key == 'C';
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 6 * scale),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (isDelete) {
                _onDelete();
              } else if (isClear) {
                _onClear();
              } else {
                _onKey(key);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: btnW,
              height: btnH,
              decoration: BoxDecoration(
                color: isDelete
                    ? const Color(0xFFF0F0F0)
                    : isClear
                        ? const Color(0xFFFFF0F0)
                        : const Color(0xFFEAF7EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDelete
                      ? const Color(0xFFDDDDDD)
                      : isClear
                          ? const Color(0xFFFFB2B2)
                          : const Color(0xFFB0D6BC),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: isDelete
                    ? Icon(Icons.backspace_outlined,
                        color: const Color(0xFF374151), size: backIconSize)
                    : isClear
                        ? Icon(Icons.clear_rounded,
                            color: const Color(0xFFE53E3E), size: backIconSize)
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F7A3D),
                              fontFamily: 'THSarabunNew',
                            ),
                          ),
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> result = rows.map((row) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * scale),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map(buildKey).toList(),
        ),
      );
    }).toList();

    // แถวสุดท้าย: ล้าง | 0 | ⌫
    result.add(
      Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * scale),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildKey('C'),
            buildKey('0'),
            buildKey('⌫'),
          ],
        ),
      ),
    );

    return result;
  }
}
