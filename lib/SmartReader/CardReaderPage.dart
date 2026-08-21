
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardReaderPage extends StatefulWidget {
  const CardReaderPage({super.key});

  @override
  State<CardReaderPage> createState() => _CardReaderPageState();
}

class _CardReaderPageState extends State<CardReaderPage> {

 static const platform = MethodChannel("thai_id_reader");

  Uint8List? photoBytes;
  String logText = "";
  Map<String, dynamic> cardData = {}; 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    setupMethodChannel();
    Future.delayed(const Duration(milliseconds: 500), () => startReader());
  }

  void setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onLog":
          setState(() {
            logText +=
                "${DateTime.now().toString().split('.').first.split(' ').last}: ${call.arguments}\n";
          });
          _scrollToBottom();
          break;

        case "onCardRead":
          setState(() {
            cardData = Map<String, dynamic>.from(call.arguments);

            if (cardData['photoBytes'] != null) {
              photoBytes = cardData['photoBytes'] as Uint8List;
            }

            logText += ">>> [SUCCESS] ดึงข้อมูลและรูปภาพสำเร็จ\n";
          });
          _scrollToBottom();
          break;

        case "onCardRemoved": // เพิ่มส่วนนี้
          setState(() {
            cardData = {}; // ล้างข้อมูลตัวอักษร
            photoBytes = null; // ล้างรูปภาพ
            logText += ">>> [INFO] บัตรถูกดึงออก\n";
          });
          _scrollToBottom();
          break;
      }
    });
  }

  Future<void> startReader() async {
    try {
      await platform.invokeMethod("startReader");
    } on PlatformException catch (e) {
      setState(() {
        logText += "Error: ${e.message}\n";
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: Scaffold(
        appBar: AppBar(
          title: const Text("Thai ID Reader V2"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,

          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => cardData = {});
                startReader();
              },
            ),

            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => logText = ""),
            ),
          ],
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "ข้อมูลจากบัตรประชาชน",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const Divider(),
              infoText("ขนาดรูปภาพ: ${photoBytes != null ? '${photoBytes!.length} bytes' : 'ไม่มีข้อมูล'}"),
              // --- ส่วนแสดงรูปภาพที่เพิ่มเข้ามา ---
              if (photoBytes != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        photoBytes!,
                        width: 150,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              // -----------------------------
              const SizedBox(height: 10),

              infoText("เลขบัตร: ${cardData['cid'] ?? '-'}"),
              infoText("ชื่อไทย: ${cardData['nameTH'] ?? '-'}"),
              infoText("ชื่ออังกฤษ: ${cardData['nameEN'] ?? '-'}"),
              infoText("เกิดวันที่: ${formatDate(cardData['birthDate'])}"),
              infoText(
                "เพศ: ${cardData['gender'] == '1' ? 'ชาย' : (cardData['gender'] == '2' ? 'หญิง' : '-')}",
              ),
              infoText("ที่อยู่: ${cardData['address'] ?? '-'}"),
              infoText("วันออกบัตร: ${formatDate(cardData['issueDate'])}"),
              infoText("วันหมดอายุ: ${formatDate(cardData['expireDate'])}"),

              const SizedBox(height: 30),

              const Text(
                "Reader Log",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Container(
                height: 250,
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),

                padding: const EdgeInsets.all(10),

                child: ListView(
                  controller: _scrollController,
                  children: [
                    Text(
                      logText.isEmpty ? "Waiting for reader..." : logText,

                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: "monospace",
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  String formatDate(dynamic date) {
    if (date == null || date.toString().length != 8) return "-";

    String d = date.toString();

    return "${d.substring(6, 8)}/${d.substring(4, 6)}/${d.substring(0, 4)}";
  }
}
