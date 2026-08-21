// import 'package:flutter/material.dart';
// import '../providers_server/thai_id_reader.dart';

// class ThaiIdScreen extends StatefulWidget {
//   const ThaiIdScreen({super.key});

//   @override
//   State<ThaiIdScreen> createState() => _ThaiIdScreenState();
// }

// class _ThaiIdScreenState extends State<ThaiIdScreen> {

//   final ThaiIdReader reader = ThaiIdReader();

//   ThaiIdData? data;
//   bool loading = true;
//   String status = "กำลังรอเสียบบัตรประชาชน...";

//   @override
//   void initState() {
//     super.initState();
//     startRead();
//   }

//   Future<void> startRead() async {
//     try {
//       await reader.init();
//       await reader.waitCard();

//       final result = await reader.readAll();

//       setState(() {
//         data = result;
//         loading = false;
//         status = "อ่านบัตรสำเร็จ";
//       });

//     } catch (e) {
//       setState(() {
//         status = "ERROR : $e";
//         loading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     reader.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: AppBar(title: const Text("Thai ID Reader")),
//       body: Center(
//         child: loading
//             ? Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const CircularProgressIndicator(),
//                   const SizedBox(height: 20),
//                   Text(status),
//                 ],
//               )
//             : data == null
//                 ? Text(status)
//                 : Card(
//                     elevation: 6,
//                     margin: const EdgeInsets.all(24),
//                     child: Padding(
//                       padding: const EdgeInsets.all(24),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [

//                           Text("เลขบัตร: ${data!.cid}",
//                               style: const TextStyle(fontSize: 22)),

//                           const SizedBox(height: 10),

//                           Text("ชื่อ: ${data!.name}",
//                               style: const TextStyle(fontSize: 22)),

//                           const SizedBox(height: 10),

//                           Text("วันเกิด: ${data!.birth}",
//                               style: const TextStyle(fontSize: 22)),

//                           const SizedBox(height: 10),

//                           Text("เพศ: ${data!.gender}",
//                               style: const TextStyle(fontSize: 22)),

//                           const SizedBox(height: 10),

//                           Text("ที่อยู่: ${data!.address}",
//                               style: const TextStyle(fontSize: 22)),
//                         ],
//                       ),
//                     ),
//                   ),
//       ),
//     );
//   }
// }