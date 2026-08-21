import 'package:flutter/material.dart';
import '../../../models/working_mode.dart';

class WorkingModeSelector extends StatelessWidget {
  final WorkingMode value;
  final ValueChanged<WorkingMode> onChanged;

  const WorkingModeSelector({
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
          'โหมดการทำงาน (Operation Mode)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),

        ...WorkingMode.values.map(
          (mode) => RadioListTile<WorkingMode>(
            title: Text(mode.label),
            value: mode,
            groupValue: value,
            onChanged: (selected) {
              if (selected != null) {
                onChanged(selected);
              }
            },
          ),
        ),
      ],
    );
  }
}
