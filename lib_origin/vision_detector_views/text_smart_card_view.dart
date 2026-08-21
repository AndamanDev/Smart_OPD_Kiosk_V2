import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'detector_view.dart';

class TextSmartCardView extends StatefulWidget {
  @override
  State<TextSmartCardView> createState() => _TextSmartCardViewState();
}

class _TextSmartCardViewState extends State<TextSmartCardView> {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  bool _canProcess = true;
  bool _isBusy = false;
  bool _isScanning = true; 
  
  String? _resultText;
  InputImage? _lastImage;
  var _cameraLensDirection = CameraLensDirection.back;

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  // --- สูตรคำนวณเลขบัตรประชาชน 13 หลัก (แบบที่ธนาคารใช้) ---
  bool _isValidThaiID(String id) {
    if (id.length != 13) return false;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(id[i]) * (13 - i);
    }
    int checkSum = (11 - (sum % 11)) % 10;
    return checkSum == int.parse(id[12]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('สแกนบัตรประชาชน', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. กล้องแบบ Clean View (ไม่มีเส้นสีเขียว)
          DetectorView(
            title: 'Scanner',
            customPaint: null, 
            text: null,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
          ),
          
          // 2. หน้ากากมืดเจาะรู (Smart Overlay)
          _buildSmartOverlay(context),
          
          // 3. ผลลัพธ์เมื่อสแกนสำเร็จ
          if (!_isScanning && _resultText != null) _buildResultSheet(),
        ],
      ),
    );
  }

  Widget _buildSmartOverlay(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.7),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 10),
            const Text("สแกนข้อมูลสำเร็จ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_resultText!, style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87)),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScanner,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), side: const BorderSide(color: Colors.blue)),
                    child: const Text("สแกนใหม่"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15), backgroundColor: Colors.blue),
                    child: const Text("ตกลง", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || !_isScanning) return;
    if (_isBusy) return;
    _isBusy = true;

    _lastImage = inputImage;
    
    // ตรวจสอบข้อมูลแบบ Real-time (เบื้องหลัง)
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    // ค้นหาเลข 13 หลักที่ "ถูกต้องตามสูตร" เพื่อทำ Auto-Capture
    String? foundId;
    final idReg = RegExp(r'(\d\s?\d{4}\s?\d{5}\s?\d{2}\s?\d)');
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String cleanText = line.text.replaceAll(' ', '');
        if (idReg.hasMatch(line.text) && _isValidThaiID(cleanText)) {
          foundId = cleanText;
          break;
        }
      }
    }

    // ถ้าเจอเลขบัตรที่ถูกต้อง ให้หยุดสแกนและโชว์ผลลัพธ์ทันที (Auto-Capture)
    if (foundId != null) {
      _extractIdData(recognizedText);
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }

void _extractIdData(RecognizedText recognizedText) {
  String? idNumber, nameTh, nameEn, lastNameEn;

  // 1. รวมข้อความจากทุกบรรทัดเข้าด้วยกัน (ป้องกันเลขบัตรถูกแยกเป็นหลายบรรทัด)
  List<String> allLines = [];
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      allLines.add(line.text);
    }
  }
  
  // รวมเป็น String ก้อนเดียว และลบช่องว่างส่วนเกิน
  final fullBlob = allLines.join(' '); 
  
  // 2. ปรับ Regex สำหรับเลข 13 หลักให้ "ดุดัน" ขึ้น
  // ดึงเฉพาะตัวเลขล้วนๆ ออกมาจาก Full Blob
  final idReg = RegExp(r'\d{1}\s?\d{4}\s?\d{5}\s?\d{2}\s?\d{1}');
  final match = idReg.firstMatch(fullBlob);
  if (match != null) {
    String rawId = match.group(0)!.replaceAll(' ', '');
    if (rawId.length == 13 && _isValidThaiID(rawId)) {
      idNumber = rawId;
    }
  }

  // 3. ปรับ Regex ภาษาไทย (รองรับกรณี AI อ่านชื่อกับนามสกุลแยกบรรทัดกัน)
  final thNameReg = RegExp(r'(นาย|นาง|นางสาว|ชื่อตัวและชื่อสกุล)\s?([ก-๙]+)');
  
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      final text = line.text.trim();

      // ค้นหาชื่อไทย (กรณีบรรทัดเดียว)
      if (nameTh == null && thNameReg.hasMatch(text)) {
        nameTh = text.replaceAll('ชื่อตัวและชื่อสกุล', '').trim();
      }

      // ค้นหาภาษาอังกฤษ (ตามโครงสร้างบัตรที่ส่งมา)
      if (nameEn == null && text.toLowerCase().contains('name')) {
        nameEn = text.replaceAll(RegExp(r'name', caseSensitive: false), '').trim();
      }
      if (lastNameEn == null && text.toLowerCase().contains('last name')) {
        lastNameEn = text.replaceAll(RegExp(r'last name', caseSensitive: false), '').trim();
      }
    }
  }

  // 4. Fallback: ถ้ายังหาชื่อไทยไม่เจอ ให้ลองดูบรรทัดถัดจากคำว่า "Identification Number"
  if (nameTh == null) {
    for (int i = 0; i < allLines.length; i++) {
      if (allLines[i].contains(RegExp(r'\d{13}')) && i + 1 < allLines.length) {
        // มักจะเป็นบรรทัดถัดจากเลขบัตร
        if (allLines[i+1].contains(RegExp(r'[ก-๙]'))) {
           nameTh = allLines[i+1].trim();
        }
      }
    }
  }

  setState(() {
    _isScanning = false;
    String cleanNameEn = nameEn?.replaceAll(RegExp(r'(Mr\.|Mrs\.|Miss)', caseSensitive: false), '').trim() ?? '';
    String fullEn = "$cleanNameEn ${lastNameEn ?? ''}".trim();

    _resultText = "🆔 เลขประจำตัว: ${idNumber ?? 'สแกนไม่ติด'}\n"
                  "🇹🇭 ชื่อ-นามสกุล: ${nameTh ?? 'สแกนไม่ติด'}\n"
                  "🇬🇧 Name-Surname: ${fullEn.isEmpty ? 'สแกนไม่ติด' : fullEn}";
  });
}

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _resultText = null;
    });
  }
}