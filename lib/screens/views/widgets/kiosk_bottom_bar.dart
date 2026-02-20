import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/kiosk_state_provider.dart';
import '../../../providers/serial_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers_server/sound_server.dart';

class KioskBottomBar extends StatelessWidget {
  const KioskBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final base = (c.maxWidth * 0.025).clamp(14, 28).toDouble();

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: base * 0.5,
            vertical: base * 0.2,
          ),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              Expanded(child: _connect(context, base)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _setting(context, base),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // CONNECTION STATUS
  // =========================================================
  Widget _connect(BuildContext context, double base) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final ok = auth.token != null && !auth.isTokenExpired;

        return LayoutBuilder(
          builder: (context, c) {

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.dns,
                  // size: base * 1.3,
                  size: 28,
                  color: ok ? Colors.green : Colors.red,
                ),

                SizedBox(width: base * 0.4),

                // -------- STATUS TEXT --------
                Flexible(
                  flex: 2,
                  child: Text(
                    ok ? "เชื่อมต่อแล้ว" : "ขาดการเชื่อมต่อ",
                    maxLines: 1,
                    // overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // fontSize: base,
                      fontSize: 20,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(width: base * 0.6),

                Consumer<SettingsProvider>(
                  builder: (_, s, __) {
                    // return Flexible(
                    //   flex: 6,
                    //   child: Text(
                    //     "ชื่อเครื่อง ${s.deviceName} "
                    //     "[${s.workingMode.name == 'combined'
                    //         ? '${s.scaleDevice.name} -> ${s.bpDevice.name}'
                    //         : s.workingMode.name == 'scaleOnly'
                    //         ? s.scaleDevice.name
                    //         : s.workingMode.name == 'bloodPressureOnly'
                    //         ? s.bpDevice.name
                    //         : ''}]",
                    //     maxLines: 1,
                    //     softWrap: false,
                    //     // overflow: TextOverflow.clip,
                    //     style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                    //   ),
                    // );
       return             Flexible(
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
    overflow: TextOverflow.ellipsis, // 👈 สำคัญมาก
    style: TextStyle(
      fontSize: 20,
      color: Colors.grey[700],
    ),
  ),
);
                  },
                ),
              ],
            );
          },
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
        Flexible(
          child: TextButton(
            style: TextButton.styleFrom(
              overlayColor: Colors.blue.withOpacity(0.15),
            ),
            onPressed: () {
              context.read<SoundServer>().stop();

              final serial = context.read<SerialProvider>();
              serial.stop();

              context.read<KioskStageProvider>().reset(serial);
              context.read<KioskStageProvider>().setStage(KioskStage.settings);
            },
            child: Text(
              "Setting",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // fontSize: base,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),

        SizedBox(width: base * 0.3),

        InkWell(
          borderRadius: BorderRadius.circular(100),
          splashColor: Colors.blue.withOpacity(0.2),
          onTap: () {
            context.read<SoundServer>().stop();

            final serial = context.read<SerialProvider>();
            serial.stop();

            context.read<KioskStageProvider>().reset(serial);

            context.read<KioskStageProvider>().reset(serial);
          },
          child: Container(
            padding: EdgeInsets.all(base * 0.1),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // child: Icon(Icons.home, size: base * 1.3, color: Colors.blue),
            child: Icon(Icons.home, size: 30, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
