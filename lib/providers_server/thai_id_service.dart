import 'dart:async';
import 'dart:typed_data';
import 'package:dart_pcsc/dart_pcsc.dart';

import '../models/thai_id_model.dart';

class ThaiIDService {
  late Context _context;
  bool cardPresent = false;

  final StreamController<ThaiIDModel?> _controller =
      StreamController.broadcast();

  Stream<ThaiIDModel?> get stream => _controller.stream;

  ////////////////////////////////////////////////////////////
  /// START LISTEN CARD
  ////////////////////////////////////////////////////////////

  Future<void> start() async {
    _context = Context(Scope.user);
    await _context.establish();

    final readers = await _context.listReaders();

    if (readers.isEmpty) {
      print('No Reader');
      return;
    }

    final reader = readers.first;

    while (true) {
      Card? card;

      try {
        card = await _context.connect(
          reader,
          ShareMode.shared,
          Protocol.any,
        );

        if (!cardPresent) {
          cardPresent = true;

          final data = await readThaiID(card);

          _controller.add(data);
        }

        await card.disconnect(Disposition.leaveCard);
      } catch (_) {
        if (cardPresent) {
          cardPresent = false;
          _controller.add(null);
        }
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  ////////////////////////////////////////////////////////////
  /// READ THAI ID
  ////////////////////////////////////////////////////////////

  Future<ThaiIDModel> readThaiID(Card card) async {
    await transmitFull(
      card,
      Uint8List.fromList([
        0x00,
        0xA4,
        0x04,
        0x00,
        0x08,
        0xA0,
        0x00,
        0x00,
        0x00,
        0x54,
        0x48,
        0x00,
        0x01,
      ]),
    );

    final id = await readData(card, 0x0004, 13);
    final thName = await readData(card, 0x0011, 100);
    final enName = await readData(card, 0x0075, 100);
    final birth = await readData(card, 0x00D9, 8);
    final gender = await readData(card, 0x00E1, 1);
    final issuer = await readData(card, 0x00E2, 100);
    final issueDate = await readData(card, 0x0146, 8);
    final expireDate = await readData(card, 0x014E, 8);
    final addr = await readAddress(card);
    final photo = await readPhoto(card);

    return ThaiIDModel(
      id: id,
      thName: thName,
      enName: enName,
      birth: formatThaiDate(birth),
      gender: gender == "1" ? "Male" : "Female",
      issuer: issuer,
      issueDate: formatThaiDate(issueDate),
      expireDate: formatThaiDate(expireDate),
      address: addr,
      photo: photo,
    );
  }

  ////////////////////////////////////////////////////////////
  /// HELPERS
  ////////////////////////////////////////////////////////////

  Future<Uint8List> transmitFull(Card card, Uint8List cmd) async {
    final response = await card.transmit(cmd);

    int sw1 = response[response.length - 2];
    int sw2 = response[response.length - 1];

    if (sw1 == 0x61) {
      final more = await card.transmit(
        Uint8List.fromList([0x00, 0xC0, 0x00, 0x00, sw2]),
      );

      return Uint8List.fromList([
        ...response.sublist(0, response.length - 2),
        ...more,
      ]);
    }

    return response;
  }

  Future<String> readData(Card card, int offset, int length) async {
    final cmd = Uint8List.fromList([
      0x80,
      0xB0,
      (offset >> 8) & 0xFF,
      offset & 0xFF,
      0x02,
      0x00,
      length,
    ]);

    final resp = await transmitFull(card, cmd);
    return tis620ToString(resp.sublist(0, length));
  }

  Future<Uint8List> readRaw(Card card, int offset, int length) async {
    final cmd = Uint8List.fromList([
      0x80,
      0xB0,
      (offset >> 8) & 0xFF,
      offset & 0xFF,
      0x02,
      0x00,
      length,
    ]);

    final resp = await transmitFull(card, cmd);
    return resp.sublist(0, length);
  }

  Future<String> readAddress(Card card) async {
    final part1 = await readRaw(card, 0x00F6, 100);
    final part2 = await readRaw(card, 0x015A, 100);

    return tis620ToString(
        Uint8List.fromList([...part1, ...part2]));
  }

  Future<Uint8List> readPhoto(Card card) async {
    const startOffset = 0x017B;

    List<int> photoBytes = [];
    int offset = startOffset;

    while (true) {
      final chunk = await readRaw(card, offset, 0xFF);
      photoBytes.addAll(chunk);

      for (int i = 0; i < photoBytes.length - 1; i++) {
        if (photoBytes[i] == 0xFF &&
            photoBytes[i + 1] == 0xD9) {
          return Uint8List.fromList(
              photoBytes.sublist(0, i + 2));
        }
      }

      offset += 0xFF;
    }
  }

  String tis620ToString(Uint8List data) {
    final buffer = StringBuffer();

    for (final b in data) {
      if (b == 0x23) {
        buffer.write(' ');
      } else if (b >= 0xA1 && b <= 0xFB) {
        buffer.writeCharCode(b + 0x0E00 - 0xA0);
      } else if (b != 0x00) {
        buffer.writeCharCode(b);
      }
    }

    return buffer.toString().trim();
  }

  String formatThaiDate(String yyyymmdd) {
    if (yyyymmdd.length != 8) return yyyymmdd;

    return "${yyyymmdd.substring(6, 8)}/"
        "${yyyymmdd.substring(4, 6)}/"
        "${yyyymmdd.substring(0, 4)}";
  }
}