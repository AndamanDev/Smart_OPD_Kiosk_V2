import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ServerSettingSelector extends StatelessWidget {
  final TextEditingController ipController;
  final TextEditingController accessKeyController;
  final TextEditingController secretKeyController;
  final TextEditingController deviceNameController;

  const ServerSettingSelector({
    super.key,
    required this.ipController,
    required this.accessKeyController,
    required this.secretKeyController,
    required this.deviceNameController,
  });

  @override
  Widget build(BuildContext context) {
    bool _secretObscured = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตั้งค่า Server (Server Settings)',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),

        // -------- Row 1 : IP Server --------
        TextFormField(
          controller: ipController,
          style: const TextStyle(fontSize: 18),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'กรุณากรอก IP Server';
            }
            return null;
          },
          decoration: const InputDecoration(
            labelText: 'IP Server',
            labelStyle: TextStyle(fontSize: 18),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        // -------- Row 2 : Access-Key / Secret-Key --------
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: accessKeyController,
                style: const TextStyle(fontSize: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'กรุณากรอก Access Key';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'X-Access-Key-Id',
                  labelStyle: TextStyle(fontSize: 18),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatefulBuilder(
                builder: (context, setInnerState) {
                  return TextFormField(
                    controller: secretKeyController,
                    style: const TextStyle(fontSize: 18),
                    obscureText: _secretObscured,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'กรุณากรอก Secret Key';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Secret Key',
                      labelStyle: const TextStyle(fontSize: 18),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _secretObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setInnerState(() {
                            _secretObscured = !_secretObscured;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // -------- Row 3 : Device Name --------
        TextFormField(
          controller: deviceNameController,
          style: const TextStyle(fontSize: 18),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'กรุณากรอกชื่ออุปกรณ์';
            }
            return null;
          },
          decoration: const InputDecoration(
            labelText: 'ชื่ออุปกรณ์',
            labelStyle: TextStyle(fontSize: 18),
            border: OutlineInputBorder(),
            counterText: "",
          ),
        ),
      ],
    );
  }
}
