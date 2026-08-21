enum BloodPressureDevice { none, andTM2655, omron9030, terumoBR500 }

enum ScaleDevice { none, bam205A, bam303A }

extension BloodPressureDeviceLabel on BloodPressureDevice {
  String get label {
    switch (this) {
      case BloodPressureDevice.none:
        return '';
      case BloodPressureDevice.andTM2655:
        return 'AND TM-2655';
      case BloodPressureDevice.omron9030:
        return 'Omron 9030';
      case BloodPressureDevice.terumoBR500:
        return 'Terumo BR-500';
    }
  }

  /// baud rate สำหรับแต่ละเครื่อง
  int get baudRate {
    switch (this) {
      case BloodPressureDevice.terumoBR500:
        return 9600;
        // return 19200;
      default:
        return 9600;
    }
  }
}

extension ScaleDeviceLabel on ScaleDevice {
  String get label {
    switch (this) {
      case ScaleDevice.none:
        return '';
      case ScaleDevice.bam205A:
        return 'BAM 205A';
      case ScaleDevice.bam303A:
        return 'BAM 303A';
    }
  }
}
