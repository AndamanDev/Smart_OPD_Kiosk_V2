import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ThaiIdScanner extends StatefulWidget {
  const ThaiIdScanner({super.key});

  @override
  State<ThaiIdScanner> createState() => _ThaiIdScannerState();
}

class _ThaiIdScannerState extends State<ThaiIdScanner> {

  CameraController? controller;
  Interpreter? interpreter;

  bool detecting = false;
  bool captured = false;

  Rect? cardBox;

  String result = "";

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future initAll() async {

    final cameras = await availableCameras();

    controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();

    interpreter = await Interpreter.fromAsset(
      "assets/model/idcard_detector.tflite",
    );

    controller!.startImageStream(processCamera);

    setState(() {});
  }

  /// YUV420 → RGB
  img.Image convert(CameraImage image) {

    final width = image.width;
    final height = image.height;

    final imgBuffer = img.Image(width: width, height: height);

    final plane = image.planes[0];

    int index = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {

        final pixel = plane.bytes[index];

        imgBuffer.setPixelRgb(x, y, pixel, pixel, pixel);

        index++;
      }
    }

    return imgBuffer;
  }

  /// preprocess → 640x640
  Float32List preprocess(img.Image image) {

    img.Image resized = img.copyResize(
      image,
      width: 640,
      height: 640,
    );

    Float32List input = Float32List(1 * 640 * 640 * 3);

    int index = 0;

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {

        final pixel = resized.getPixel(x, y);

        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  Future processCamera(CameraImage image) async {

    if (detecting || captured) return;

    detecting = true;

    try {

      img.Image frame = convert(image);

      Float32List input = preprocess(frame);

      var inputTensor = input.reshape([1,640,640,3]);

      var output = List.generate(
        1,
        (_) => List.generate(
          8400,
          (_) => List.filled(6, 0.0),
        ),
      );

      interpreter!.run(inputTensor, output);

      double bestConf = 0;
      Rect? bestBox;

      for (int i = 0; i < 8400; i++) {

        double x = output[0][i][0];
        double y = output[0][i][1];
        double w = output[0][i][2];
        double h = output[0][i][3];
        double conf = output[0][i][4];

        if (conf > bestConf) {

          bestConf = conf;

          bestBox = Rect.fromCenter(
            center: Offset(x, y),
            width: w,
            height: h,
          );
        }
      }

      cardBox = bestBox;

      if (bestConf > 0.8 && !captured) {

        captured = true;

        await captureCard();
      }

      setState(() {});

    } catch (e) {

      print(e);
    }

    detecting = false;
  }

  Future captureCard() async {

    final file = await controller!.takePicture();

    File imgFile = File(file.path);

    img.Image? original =
        img.decodeImage(await imgFile.readAsBytes());

    img.Image crop = img.copyCrop(
      original!,
      x: (original.width * 0.1).toInt(),
      y: (original.height * 0.2).toInt(),
      width: (original.width * 0.8).toInt(),
      height: (original.height * 0.5).toInt(),
    );

    File cropFile = File("${imgFile.path}_crop.jpg")
      ..writeAsBytesSync(img.encodeJpg(crop));

    await runOCR(cropFile);
  }

  Future runOCR(File file) async {

    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.latin);

    final inputImage = InputImage.fromFile(file);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    String text = recognizedText.text;

    result = parseThaiId(text);

    setState(() {});
  }

  String parseThaiId(String text) {

    RegExp idRegex = RegExp(r'\d{13}');
    String id = idRegex.firstMatch(text)?.group(0) ?? "";

    return "ID: $id\n$text";
  }

  @override
  Widget build(BuildContext context) {

    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.previewSize!.height,
                height: controller!.value.previewSize!.width,
                child: CameraPreview(controller!),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(10),
              child: Text(
                result,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}