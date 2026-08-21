import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class ThaiIdYoloScanner extends StatefulWidget {
  const ThaiIdYoloScanner({super.key});

  @override
  State<ThaiIdYoloScanner> createState() => _ThaiIdYoloScannerState();
}

class _ThaiIdYoloScannerState extends State<ThaiIdYoloScanner> {

  Interpreter? interpreter;

  File? imageFile;

  List detections = [];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {

    interpreter = await Interpreter.fromAsset(
      "assets/model/idcard_detector.tflite",
    );

    print("MODEL LOADED");
  }

  Future pickImage() async {

    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return;

    imageFile = File(picked.path);

    setState(() {});

    runModel(imageFile!);
  }

  Future runModel(File file) async {

    img.Image image =
        img.decodeImage(await file.readAsBytes())!;

    img.Image resized =
        img.copyResize(image, width: 640, height: 640);

    var input = List.generate(
      1,
      (_) => List.generate(
        640,
        (y) => List.generate(
          640,
          (x) {

            final pixel = resized.getPixel(x, y);

            return [
              pixel.r / 255,
              pixel.g / 255,
              pixel.b / 255
            ];
          },
        ),
      ),
    );

 var output = List.generate(
  1,
  (_) => List.generate(
    13,
    (_) => List.filled(8400, 0.0),
  ),
);

print(interpreter!.getOutputTensor(0).shape);

    interpreter!.run(input, output);

    parseOutput(output, image);
  }

double sigmoid(double x) {
  return 1 / (1 + math.exp(-x));
}

void parseOutput(List output, img.Image original) {

  List results = [];

  int numBoxes = 8400;

  double scaleX = original.width / 640;
  double scaleY = original.height / 640;

  for (int i = 0; i < numBoxes; i++) {

    double x = output[0][0][i];
    double y = output[0][1][i];
    double w = output[0][2][i];
    double h = output[0][3][i];

    double objConf = sigmoid(output[0][4][i]);

    double bestClassScore = 0;
    int bestClass = -1;

    for (int c = 5; c < 13; c++) {

      double score = sigmoid(output[0][c][i]);

      if (score > bestClassScore) {
        bestClassScore = score;
        bestClass = c - 5;
      }

    }

    double confidence = objConf * bestClassScore;

    if (confidence > 0.5) {

      double left = (x - w / 2) * scaleX;
      double top = (y - h / 2) * scaleY;

      double width = w * scaleX;
      double height = h * scaleY;

      results.add({
        "x": left,
        "y": top,
        "w": width,
        "h": height,
        "class": bestClass,
        "confidence": confidence
      });
    }
  }

  print("detections: ${results.length}");

  setState(() {
    detections = results;
  });
}

  Widget buildBoxes() {

    if (imageFile == null) return const SizedBox();

    return Stack(
      children: [
Image.file(
  imageFile!,
  width: 640,
  height: 640,
  fit: BoxFit.contain,
),

        ...detections.map((box) {

          return Positioned(
            left: box["x"],
            top: box["y"],
            child: Container(
              width: box["w"],
              height: box["h"],
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),
          );

        }).toList()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thai ID Detector"),
      ),
      body: Column(
        children: [

          Expanded(
            child: Center(
              child: buildBoxes(),
            ),
          ),

          ElevatedButton(
            onPressed: pickImage,
            child: const Text("Select Image"),
          ),

          const SizedBox(height: 30)
        ],
      ),
    );
  }
}
