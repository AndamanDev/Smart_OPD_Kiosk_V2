import 'dart:io';
import 'package:flutter/material.dart';

class HospitalLogoSelector extends StatelessWidget {
  final TextEditingController controller;

  const HospitalLogoSelector({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'โลโก้โรงพยาบาล',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'ที่อยู่ไฟล์โลโก้ (File Path)',
                  hintText: 'C:\\path\\to\\logo.png',
                  border: OutlineInputBorder(),
                  helperText: 'ขนาดแนะนำ (Recommended Height): 200px',
                ),
              ),
            ),
            const SizedBox(width: 10),

            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildPreview(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (controller.text.isNotEmpty) {
      return Image.file(
        File(controller.text),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      );
    }

    return Image.asset(
      'assets/images/hospital_logo_new.png',
      fit: BoxFit.contain,
    );
  }
}
