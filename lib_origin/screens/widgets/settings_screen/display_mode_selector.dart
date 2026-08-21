import 'package:flutter/material.dart';
import '../../../models/display_mode.dart';

class DisplayModeSelector extends StatelessWidget {
  final DisplayMode value;
  final ValueChanged<DisplayMode> onChanged;

  const DisplayModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตั้งค่าการแสดงผล (Display Settings)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),

        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'แสดงสีแจ้งเตือนช่วงผลการวัด (Show Result Colors)',
          ),
          value: value.showResultColors,
          onChanged: (checked) {
            onChanged(
              value.copyWith(showResultColors: checked ?? false),
            );
          },
        ),
      ],
    );
  }
}
