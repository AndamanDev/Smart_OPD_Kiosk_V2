import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PathApiSettingSelector extends StatelessWidget {
  final TextEditingController loginController;
  final TextEditingController getPatientsController;
  final TextEditingController savevitalController;

  const PathApiSettingSelector({
    super.key,
    required this.loginController,
    required this.getPatientsController,
    required this.savevitalController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตั้งค่า Path Api (Path Api Settings)',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // -------- Login Path (ซ่อนไว้ ไม่ใช้งาน) --------
            Visibility(
              visible: false,
              child: Expanded(
                child: TextFormField(
                  controller: loginController,
                  decoration: const InputDecoration(
                    labelText: 'Login Path',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            Expanded(
              child: TextFormField(
                controller: getPatientsController,
                style: const TextStyle(fontSize: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'กรุณากรอก GetPatients Path';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'GetPatients Path',
                  labelStyle: TextStyle(fontSize: 18),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: savevitalController,
                style: const TextStyle(fontSize: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'กรุณากรอก SaveVitals Path';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'SaveVitals Path',
                  labelStyle: TextStyle(fontSize: 18),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
