import 'package:flutter/material.dart';

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
    bool _isObscured = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตั้งค่า Path Api (Path Api Settings)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: loginController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'กรุณากรอก Login Path';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Login Path',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: TextFormField(
                controller: getPatientsController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'กรุณากรอก GetPatients Path';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'GetPatients Path',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: savevitalController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'กรุณากรอก SaveVitals Path';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'SaveVitals Path',
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
