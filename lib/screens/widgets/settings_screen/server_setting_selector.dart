import 'package:flutter/material.dart';

class ServerSettingSelector extends StatelessWidget {
  final TextEditingController ipController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController deviceNameController;

  const ServerSettingSelector({
    super.key,
    required this.ipController,
    required this.usernameController,
    required this.passwordController,
    required this.deviceNameController,
  });

  @override
  Widget build(BuildContext context) {
    bool _isObscured = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตั้งค่า Server (Server Settings)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),

        // -------- Row 1 : IP Server --------
        TextField(
          controller: ipController,
          decoration: const InputDecoration(
            labelText: 'IP Server',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        // -------- Row 2 : Username / Password --------
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return TextField(
                    controller: passwordController,
                    obscureText: _isObscured,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
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
        TextField(
          controller: deviceNameController,
          decoration: const InputDecoration(
            labelText: 'ชื่ออุปกรณ์',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
