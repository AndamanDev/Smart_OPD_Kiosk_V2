import 'package:flutter/material.dart';
import '../models/sound_mode.dart';
import '../providers/auth_provider.dart';
import 'widgets/settings_screen/sound_mode_selector.dart';
import '../models/display_mode.dart';
import '../models/working_mode.dart';
import '../models/device_models.dart';
import 'package:provider/provider.dart';
import '../providers/kiosk_state_provider.dart';
import '../providers/serial_provider.dart';
import '../providers/settings_provider.dart';
import '../providers_server/serial_server.dart';
import 'widgets/settings_screen/device_setting_selector.dart';
import 'widgets/settings_screen/display_mode_selector.dart';
import 'widgets/settings_screen/hospital_logo_selector.dart';
import 'widgets/settings_screen/server_setting_selector.dart';
import 'widgets/settings_screen/settings_action_buttons.dart';
import 'widgets/settings_screen/working_mode_selector.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final SerialServer _server = SerialServer();

  WorkingMode _selectedMode = WorkingMode.combined;
  SoundMode _soundMode = SoundMode();
  DisplayMode _displayMode = const DisplayMode();

  final TextEditingController _logoPathController = TextEditingController();

  // BP
  BloodPressureDevice _bpDevice = BloodPressureDevice.andTM2655;
  String _bpPort = '';

  // Scale
  ScaleDevice _scaleDevice = ScaleDevice.bam205A;
  String _scaleReadPort = '';
  String _scaleControlPort = '';

  List<String> get _availablePorts =>
      SerialPort.availablePorts.toSet().toList();

  // Server
  late TextEditingController _serverIpController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _deviceNameController;

  late TextEditingController _delayBPController;
  late TextEditingController _delayScaleController;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsProvider>();

    _selectedMode = settings.workingMode;
    _soundMode = settings.soundMode;
    _displayMode = settings.displayMode;

    _serverIpController = TextEditingController(text: settings.serverIp);
    _usernameController = TextEditingController(text: settings.username);
    _passwordController = TextEditingController(text: settings.password);
    _deviceNameController = TextEditingController(text: settings.deviceName);

    _bpPort = settings.bpPort;
    _scaleReadPort = settings.scaleReadPort;
    _scaleControlPort = settings.scaleControlPort;
    _bpDevice = settings.bpDevice;
    _scaleDevice = settings.scaleDevice;

    _delayBPController = TextEditingController(
      text: settings.delayBPSeconds.toString(),
    );

    _delayScaleController = TextEditingController(
      text: settings.delayScaleSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _deviceNameController.dispose();
    _logoPathController.dispose();
    _delayBPController.dispose();
    _delayScaleController.dispose();
    super.dispose();
  }

  List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบ (System Settings)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            WorkingModeSelector(
              value: _selectedMode,
              onChanged: (mode) {
                setState(() {
                  _selectedMode = mode;

                  if (mode == WorkingMode.bloodPressureOnly) {
                    _bpDevice = BloodPressureDevice.andTM2655;
                    _scaleReadPort = '';
                    _scaleControlPort = '';
                  }

                  if (mode == WorkingMode.scaleOnly) {
                    _scaleDevice = ScaleDevice.bam205A;
                    _bpPort = '';
                  }

                  if (mode == WorkingMode.combined) {
                    _bpPort = '';
                    _scaleReadPort = '';
                    _scaleControlPort = '';
                  }
                });
              },
            ),

            const Divider(height: 30),

            DeviceSettingSelector(
              workingMode: _selectedMode,
              availablePorts: _availablePorts,

              bpDevice: _bpDevice,
              bpPort: _bpPort,
              onBpDeviceChanged: (v) => setState(() => _bpDevice = v),
              onBpPortChanged: (v) => setState(() => _bpPort = v),

              scaleDevice: _scaleDevice,
              scaleReadPort: _scaleReadPort,
              scaleControlPort: _scaleControlPort,
              onScaleDeviceChanged: (v) => setState(() => _scaleDevice = v),
              onScaleReadPortChanged: (v) => setState(() => _scaleReadPort = v),
              onScaleControlPortChanged: (v) =>
                  setState(() => _scaleControlPort = v),
            ),

            const Divider(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ตั้งค่าความหน่วง (วินาที)',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // ส่วนที่ 1: เครื่องวัดความดัน
                      Expanded(
                        child: _buildDelayInput(
                          label: 'เครื่องวัดความดัน',
                          controller: _delayBPController,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildDelayInput(
                          label: 'เครื่องชั่งน้ำหนัก/ส่วนสูง',
                          controller: _delayScaleController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 30),

            SoundModeSelector(
              value: _soundMode,
              onChanged: (newSettings) {
                setState(() {
                  _soundMode = newSettings;
                });
              },
            ),

            const Divider(height: 30),

            DisplayModeSelector(
              value: _displayMode,
              onChanged: (newValue) {
                setState(() {
                  _displayMode = newValue;
                });
              },
            ),

            const Divider(height: 30),

            HospitalLogoSelector(controller: _logoPathController),

            const Divider(height: 30),

            ServerSettingSelector(
              ipController: _serverIpController,
              usernameController: _usernameController,
              passwordController: _passwordController,
              deviceNameController: _deviceNameController,
            ),

            const Divider(height: 30),

            SettingsActionButtons(
              onCancel: () async {
                final serial = context.read<SerialProvider>();
                serial.stop();
                context.read<KioskStageProvider>().reset(serial);
              },

              onSave: () async {
                final settings = context.read<SettingsProvider>();
                final auth = context.read<AuthProvider>();

                var bpDevice = _bpDevice;
                var bpPort = _bpPort;
                var scaleDevice = _scaleDevice;
                var scaleReadPort = _scaleReadPort;
                var scaleControlPort = _scaleControlPort;

                if (_selectedMode == WorkingMode.bloodPressureOnly) {
                  scaleDevice = ScaleDevice.none;
                  scaleReadPort = '';
                  scaleControlPort = '';
                } else if (_selectedMode == WorkingMode.scaleOnly) {
                  bpDevice = BloodPressureDevice.none;
                  bpPort = '';
                }

                await settings.save(
                  workingMode: _selectedMode,
                  soundMode: _soundMode,
                  displayMode: _displayMode,
                  bpDevice: bpDevice,
                  bpPort: bpPort,
                  scaleDevice: scaleDevice,
                  scaleReadPort: scaleReadPort,
                  scaleControlPort: scaleControlPort,
                  serverIp: _serverIpController.text,
                  username: _usernameController.text,
                  password: _passwordController.text,
                  deviceName: _deviceNameController.text,
                  delayBPSeconds: int.tryParse(_delayBPController.text) ?? 180,
                  delayScaleSeconds:
                      int.tryParse(_delayScaleController.text) ?? 180,
                );

                final serial = context.read<SerialProvider>();
                serial.stop();

                await auth.logout();

                context.read<KioskStageProvider>().setStage(KioskStage.loading);

                // context.read<KioskStageProvider>().reset(serial);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            isDense: true,
            suffixText: 'วินาที',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
