import 'package:usb_serial/usb_serial.dart';
import 'usb_types.dart';

class UsbSerialWrapper {
  static Future<List<UsbDeviceInfo>> listDevices() async {
    final devices = await UsbSerial.listDevices();

    return devices
        .map((d) => UsbDeviceInfo(d))
        .toList();
  }

  static Future<UsbPort?> createPort(UsbDeviceInfo device) {
    final realDevice = device.raw as UsbDevice;
    return realDevice.create();
  }
}