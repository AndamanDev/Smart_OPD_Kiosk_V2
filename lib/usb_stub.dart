import 'usb_types.dart';

class UsbPort {
  static const int DATABITS_8 = 8;
  static const int STOPBITS_1 = 1;
  static const int PARITY_NONE = 0;

  Future<void> open() async {}
  Future<void> close() async {}
  Future<void> setDTR(bool value) async {}
  Future<void> setRTS(bool value) async {}

  Future<void> setPortParameters(
      int baudRate,
      int dataBits,
      int stopBits,
      int parity) async {}

  Stream<List<int>>? get inputStream => null;
}

class UsbSerialWrapper {
  static Future<List<UsbDeviceInfo>> listDevices() async {
    return [];
  }

  static Future<UsbPort?> createPort(UsbDeviceInfo device) async {
    return null;
  }
}