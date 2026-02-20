enum WorkingMode { bloodPressureOnly, scaleOnly, combined }

extension WorkingModeExtension on WorkingMode {
  String get label {
    switch (this) {
      case WorkingMode.bloodPressureOnly:
        return 'โหมดความดันโลหิต (Blood Pressure Only)';
      case WorkingMode.scaleOnly:
        return 'โหมดชั่งน้ำหนัก/ส่วนสูง (Scale Only)';
      case WorkingMode.combined:
        return 'โหมดรวม (Combined: Scale → BP)';
    }
  }

  String get illustrations {
    return switch (this) {
      WorkingMode.bloodPressureOnly => 'assets/images/bp_illustration_new.jpg',
      WorkingMode.scaleOnly => 'assets/images/weight_height_scale.png',
      WorkingMode.combined => 'assets/images/vital_sign_system.png',
    };
  }
}
