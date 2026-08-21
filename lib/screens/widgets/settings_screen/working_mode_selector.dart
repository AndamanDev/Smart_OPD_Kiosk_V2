import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
        ),
        const SizedBox(height: 12),

        ...WorkingMode.values
            .where((mode) => mode != WorkingMode.combined)
            .map(
              (mode) => RadioListTile<WorkingMode>(
                title: Text(mode.label, style: const TextStyle(fontSize: 22)),
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
