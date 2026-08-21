import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class HospitalLogoSelector extends StatefulWidget {
  final TextEditingController controller;

  const HospitalLogoSelector({super.key, required this.controller});

  @override
  State<HospitalLogoSelector> createState() => _HospitalLogoSelectorState();
}

class _HospitalLogoSelectorState extends State<HospitalLogoSelector> {
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) return;

    final sourcePath = result.files.single.path!;
    final sourceFile = File(sourcePath);

    final dir = await getApplicationSupportDirectory();
    final logoDir = Directory('${dir.path}/logo');

    if (!logoDir.existsSync()) {
      logoDir.createSync(recursive: true);
    }

    final newPath =
        '${logoDir.path}/hospital_logo_${DateTime.now().millisecondsSinceEpoch}.png';

    final newFile = File(newPath);

    // 🔥 ลบไฟล์เดิมก่อน
    if (newFile.existsSync()) {
      await newFile.delete();
    }

    await sourceFile.copy(newPath);

    imageCache.clear();
    imageCache.clearLiveImages();

    widget.controller.text = newPath;

    setState(() {});
  }

  Widget _buildPreview() {
    if (widget.controller.text.isNotEmpty &&
        File(widget.controller.text).existsSync()) {
      return Image.file(File(widget.controller.text), fit: BoxFit.contain);
    }

    return Image.asset(
      'assets/images/hospital_logo_new.png',
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'โลโก้โรงพยาบาล',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(fontSize: 22),
                readOnly: true,
                onTap: _pickImage,
                decoration: const InputDecoration(
                  labelText: 'เลือกไฟล์โลโก้',
                  labelStyle: TextStyle(fontSize: 22),
                  hintText: 'กดเพื่อเลือกไฟล์',
                  prefixIcon: Icon(Icons.image),
                  suffixIcon: Icon(Icons.folder_open),
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
}
