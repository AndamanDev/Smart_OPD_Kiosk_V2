import 'package:flutter/material.dart';
import '../../../models/sound_mode.dart';

class SoundModeSelector extends StatelessWidget {
  final SoundMode value;
  final ValueChanged<SoundMode> onChanged;

  const SoundModeSelector({
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
          'ตั้งค่าเสียง (Audio Settings)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),

        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('เสียงกระดิ่ง (Bell Sound)'),
          value: value.bellSound,
          onChanged: (checked) {
            onChanged(value.copyWith(bellSound: checked ?? false));
          },
        ),

        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('เสียงภาษาไทย (Thai Voice)'),
          value: value.thaiVoice,
          onChanged: (checked) {
            onChanged(value.copyWith(thaiVoice: checked ?? false));
          },
        ),

        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('เสียงภาษาอังกฤษ (English Voice) - รอพัฒนา'),
          value: value.englishVoice,
          onChanged: null, // disable ไว้ก่อน
        ),

        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('เสียงอ่านค่าที่วัดได้ (Read Values) - รอพัฒนา'),
          value: value.readValues,
          onChanged: null, // disable ไว้ก่อน
        ),
      ],
    );
  }
}
