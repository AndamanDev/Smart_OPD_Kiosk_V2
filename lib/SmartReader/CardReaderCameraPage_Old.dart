import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class CardReaderCameraPage extends StatefulWidget {
  const CardReaderCameraPage({super.key});

  @override
  State<CardReaderCameraPage> createState() => _CardReaderCameraPageState();
}

class _CardReaderCameraPageState extends State<CardReaderCameraPage> {
 Interpreter? _interpreter;
  List<Map<String, dynamic>> _boxResults = [];
  File? _image;
  List<dynamic> _recognitions = [];
  final int _inputSize = 640;

  final List<String> _labels = [
    "Address",
    "Date_of_Birth",
    "Date_of_Expiry",
    "Date_of_Issue",
    "First_Name",
    "ID_Number",
    "Image",
    "Last_Name",
    "Thai_Name",
  ];

  Map<String, String> _extractedTexts = {};
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _prepareTesseract();
  }

String _formatThaiDate(String text) {

  text = text.replaceAll(RegExp(r'[^0-9]'), '');

  if (text.length < 8) return text;

  String day = text.substring(0, 2);
  String month = text.substring(2, 4);
  String year = text.substring(4, 8);

  int y = int.tryParse(year) ?? 0;

  // convert ค.ศ. -> พ.ศ.
  if (y < 2500) {
    y += 543;
  }

  return "$day/$month/$y";
}

  Future<void> _prepareTesseract() async {
    final directory = await getApplicationDocumentsDirectory();
    final tessDataDir = Directory('${directory.path}/tessdata');

    if (!await tessDataDir.exists()) {
      await tessDataDir.create(recursive: true);
    }

    await _copyTrainedData("tha");
    await _copyTrainedData("eng");
  }

  Future<void> _copyTrainedData(String lang) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tessdata/$lang.traineddata');

    if (!await file.exists()) {
      ByteData data = await rootBundle.load(
        'assets/tessdata/$lang.traineddata',
      );

      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await file.writeAsBytes(bytes);
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/idcard_detector.tflite',
      );
      print("✅ Model Loaded");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  // แปลงรูปภาพให้เป็น Float32 และ Normalize (0-1)
  Uint8List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * _inputSize * _inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future<void> _runInference(File file) async {
    if (_interpreter == null) return;

    setState(() {
      _boxResults = [];
      _recognitions = [];
    });

    try {
      final rawBytes = await file.readAsBytes();
      final rawImage = img.decodeImage(rawBytes);
      if (rawImage == null) return;

      // 1. Resize เป็น 640x640 สำหรับ Model
      final resizedImage = img.copyResize(
        rawImage,
        width: _inputSize,
        height: _inputSize,
      );
      var input = _imageToByteListFloat32(resizedImage);

      // 2. เตรียม Output [1, 13, 8400]
      var output = List.generate(
        1,
        (_) => List.generate(13, (_) => List.filled(8400, 0.0)),
      );
      _interpreter!.run(input, output);

      List<dynamic> results = [];
      var outputData = output[0];

      // เพิ่มบรรทัดนี้เพื่อเช็คค่า
      print("🔍 Sample Box Value: ${outputData[0][0]}, ${outputData[1][0]}");
      for (int i = 0; i < 8400; i++) {
        double maxScore = 0;
        int classId = -1;

        for (int c = 4; c < 13; c++) {
          if (outputData[c][i] > maxScore) {
            maxScore = outputData[c][i];
            classId = c - 4;
          }
        }

        if (maxScore > 0.35) {
          // ✅ ลบ / _inputSize ออก เพราะ Model คืนค่า 0.0 - 1.0 มาให้แล้ว
          double cx = outputData[0][i];
          double cy = outputData[1][i];
          double w = outputData[2][i];
          double h = outputData[3][i];

          double x = cx - (w / 2);
          double y = cy - (h / 2);

          results.add({
            "box": [x, y, w, h],
            "score": maxScore,
            "tag": _labels[classId],
          });
        }
      }

      setState(() {
        _image = file;
        _recognitions = nms(results); // กรองกรอบที่ซ้อนกัน
        _extractedTexts = {};
      });

      _extractTextFromBoxes(file, _recognitions);
    } catch (e) {
      print("❌ Inference Error: $e");
    }
  }

  // ฟังก์ชัน NMS
  List<dynamic> nms(List<dynamic> list) {
    if (list.isEmpty) return [];
    list.sort((a, b) => b['score'].compareTo(a['score']));
    List<dynamic> selected = [];
    while (list.isNotEmpty) {
      var first = list.removeAt(0);
      selected.add(first);
      list.removeWhere((next) => calculateIoU(first['box'], next['box']) > 0.4);
    }
    return selected;
  }

  double calculateIoU(List<double> box1, List<double> box2) {
    double x1 = max(box1[0], box2[0]);
    double y1 = max(box1[1], box2[1]);
    double x2 = min(box1[0] + box1[2], box2[0] + box2[2]);
    double y2 = min(box1[1] + box1[3], box2[1] + box2[3]);
    double intersection = max(0, x2 - x1) * max(0, y2 - y1);
    double union = (box1[2] * box1[3]) + (box2[2] * box2[3]) - intersection;
    return intersection / union;
  }

  Future<void> _extractTextFromBoxes(
    File imageFile,
    List<dynamic> recognitions,
  ) async {
    setState(() => _isExtracting = true);

    final List<Map<String, dynamic>> results = [];

    try {
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return;

      for (var re in recognitions) {
        final String tag = re["tag"];
        if (tag == "Image") continue;

        final box = re["box"];

        int left = max(0, (box[0] * originalImage.width).toInt());
        int top = max(0, (box[1] * originalImage.height).toInt());

        int width = min(
          (box[2] * originalImage.width).toInt(),
          originalImage.width - left,
        );

        int height = min(
          (box[3] * originalImage.height).toInt(),
          originalImage.height - top,
        );

        img.Image cropped = img.copyCrop(
          originalImage,
          x: left,
          y: top,
          width: width,
          height: height,
        );

        // ⭐ preprocess ให้ OCR อ่านไทยง่ายขึ้น
        cropped = img.copyResize(
          cropped,
          width: cropped.width * 2,
          height: cropped.height * 2,
        );

        cropped = img.grayscale(cropped);

        cropped = img.adjustColor(cropped, contrast: 1.7);

        cropped = img.gaussianBlur(cropped, radius: 1);

        final tempPath =
            '${Directory.systemTemp.path}/crop_${tag}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(img.encodeJpg(cropped));

        // ⭐ OCR ภาษาไทย
        String text = await FlutterTesseractOcr.extractText(
          tempFile.path,
          language: "tha+eng",
        );

        text = text.replaceAll('\n', ' ').trim();

        /// แปลงวันที่
        if (tag.contains("Date")) {
          text = _formatThaiDate(text);
        }

        results.add({
          "tag": tag,
          "text": text.replaceAll('\n', ' ').trim(),
          "image": tempFile,
        });
      }

      setState(() {
        _boxResults = results;
        _isExtracting = false;
      });
    } catch (e) {
      print("OCR Error: $e");
      setState(() => _isExtracting = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _boxResults = [];
        _recognitions = [];
        _image = null;
      });

      _runInference(File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _boxResults = [];
        _recognitions = [];
        _image = null;
      });

      _runInference(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thai ID Scanner Fix"),
        backgroundColor: Colors.blueGrey,
      ),
      body: _image == null
          ? const Center(child: Text("เลือกรูปบัตรประชาชน"))
          : Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return FutureBuilder<img.Image?>(
                        future: _getOriginalImage(file: _image!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );

                          final originalW = snapshot.data!.width.toDouble();
                          final originalH = snapshot.data!.height.toDouble();

                          double imageRatio = originalW / originalH;
                          double screenW = constraints.maxWidth;
                          double displayH = screenW / imageRatio;

                          if (displayH > constraints.maxHeight) {
                            displayH = constraints.maxHeight;
                            screenW = displayH * imageRatio;
                          }

                          return Center(
                            child: SizedBox(
                              width: screenW,
                              height: displayH,
                              child: Stack(
                                children: [
                                  Image.file(
                                    _image!,
                                    width: screenW,
                                    height: displayH,
                                    fit: BoxFit.fill,
                                  ),
                                  ..._recognitions.map((re) {
                                    final box = re["box"];
                                    return Positioned(
                                      left: box[0] * screenW,
                                      top: box[1] * displayH,
                                      width: box[2] * screenW,
                                      height: box[3] * displayH,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.limeAccent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          "${re["tag"]}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            backgroundColor: Colors.black54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildResultList(),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "camera",
            onPressed: _takePhoto,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "gallery",
            onPressed: _pickImage,
            child: const Icon(Icons.photo),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_isExtracting) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      );
    }

    if (_boxResults.isEmpty) return Container();

    return Container(
      height: 260,
      color: Colors.white,
      child: ListView.builder(
        itemCount: _boxResults.length,
        itemBuilder: (context, index) {
          final item = _boxResults[index];

          return GestureDetector(
            onTap: () {
              _showImagePreview(item["image"]);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: ListTile(
                leading: Image.file(
                  item["image"],
                  width: 70,
                  height: 40,
                  fit: BoxFit.cover,
                ),
                title: Text(
                  item["tag"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  item["text"],
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(child: Image.file(imageFile)),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<img.Image?> _getOriginalImage({required File file}) async {
    final bytes = await file.readAsBytes();
    return img.decodeImage(bytes);
  }
}
