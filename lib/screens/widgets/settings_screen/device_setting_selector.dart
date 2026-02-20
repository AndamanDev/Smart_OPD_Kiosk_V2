import 'package:flutter/material.dart';
import '../../../models/device_models.dart';
import '../../../models/working_mode.dart';

class DeviceSettingSelector extends StatelessWidget {
  final WorkingMode workingMode;

  // BP
  final BloodPressureDevice bpDevice;
  final String bpPort;
  final ValueChanged<BloodPressureDevice> onBpDeviceChanged;
  final ValueChanged<String> onBpPortChanged;

  // Scale
  final ScaleDevice scaleDevice;
  final String scaleReadPort;
  final String scaleControlPort;
  final ValueChanged<ScaleDevice> onScaleDeviceChanged;
  final ValueChanged<String> onScaleReadPortChanged;
  final ValueChanged<String> onScaleControlPortChanged;

  final List<String> availablePorts;

  const DeviceSettingSelector({
    super.key,
    required this.workingMode,

    required this.bpDevice,
    required this.bpPort,
    required this.onBpDeviceChanged,
    required this.onBpPortChanged,

    required this.scaleDevice,
    required this.scaleReadPort,
    required this.scaleControlPort,
    required this.onScaleDeviceChanged,
    required this.onScaleReadPortChanged,
    required this.onScaleControlPortChanged,

    required this.availablePorts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตั้งค่าเครื่องวัด (Device Settings)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),

        if (workingMode != WorkingMode.scaleOnly) ...[
          _buildBloodPressureSection(),
          const SizedBox(height: 20),
        ],

        if (workingMode != WorkingMode.bloodPressureOnly) _buildScaleSection(),
      ],
    );
  }

  // ---------------- BP ----------------
  Widget _buildBloodPressureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เลือกรุ่นเครื่องวัดความดัน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Row(
          children: BloodPressureDevice.values
              .where((d) => d != BloodPressureDevice.none)
              .map((device) {
                return Expanded(
                  child: RadioListTile<BloodPressureDevice>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(device.label),
                    value: device,
                    groupValue: bpDevice,
                    onChanged: (v) {
                      if (v != null) onBpDeviceChanged(v);
                    },
                  ),
                );
              })
              .toList(),
        ),

        const SizedBox(height: 8),

        _buildPortDropdown(
          label: 'Port เครื่องวัดความดัน',
          value: bpPort,
          onChanged: onBpPortChanged,
          disabledPorts: [
            scaleReadPort,
            scaleControlPort,
          ].where((p) => p.isNotEmpty).toList(),
        ),
      ],
    );
  }

  // ---------------- Scale ----------------
  Widget _buildScaleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เลือกรุ่นเครื่องชั่ง / ส่วนสูง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Row(
          children: ScaleDevice.values.where((d) => d != ScaleDevice.none).map((
            device,
          ) {
            final disabled = device.label.contains('303');

            return Expanded(
              child: RadioListTile<ScaleDevice>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(device.label),
                value: device,
                groupValue: scaleDevice,

                onChanged: disabled
                    ? null
                    : (v) {
                        if (v != null) onScaleDeviceChanged(v);
                      },
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        _buildPortDropdown(
          label: 'Port อ่านค่าเครื่อง',
          value: scaleReadPort,
          onChanged: onScaleReadPortChanged,
          disabledPorts: [
            bpPort,
            scaleControlPort,
          ].where((p) => p.isNotEmpty).toList(),
        ),
        const SizedBox(height: 8),
        _buildPortDropdown(
          label: 'Port ควบคุมการเคลื่อนที่',
          value: scaleControlPort,
          onChanged: onScaleControlPortChanged,
          disabledPorts: [
            bpPort,
            scaleReadPort,
          ].where((p) => p.isNotEmpty).toList(),
        ),
      ],
    );
  }

  Widget _buildPortDropdown({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    required List<String> disabledPorts,
  }) {
    // ✅ Filter ports + กันซ้ำ
    final ports = availablePorts.toSet().toList();

    // ✅ ถ้า value ไม่มีใน list → set null กัน crash
    final safeValue = (value.isNotEmpty && ports.contains(value))
        ? value
        : null;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),

      value: safeValue,

      items: ports.map((p) {
        final isDisabled = disabledPorts.contains(p);

        return DropdownMenuItem<String>(
          value: p,
          enabled: !isDisabled,
          child: Text(
            p,
            style: TextStyle(color: isDisabled ? Colors.grey : null),
          ),
        );
      }).toList(),

      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
