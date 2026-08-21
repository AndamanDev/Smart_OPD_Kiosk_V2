class PortMapper {
  static final Map<String, String> _map = {};

  /// ⭐ update mapping (ต้องเรียกก่อนใช้)
  static void update(List<String> realPorts) {
    _map.clear();

    for (int i = 0; i < realPorts.length; i++) {
      final comName = 'COM${i + 1}';
      _map[comName] = realPorts[i];
    }
  }

  /// ใช้สำหรับ UI
  static List<String> mapPorts(List<String> realPorts) {
    update(realPorts);
    return _map.keys.toList();
  }

  /// ใช้ตอนเปิด serial
  static String? realPort(String comPort) {
    return _map[comPort];
  }
}