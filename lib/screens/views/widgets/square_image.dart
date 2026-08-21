import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/working_mode.dart';
import '../../../providers/kiosk_state_provider.dart';

class ModeSquareImage extends StatelessWidget {
  final WorkingMode mode;
  final double? height;
  final bool isError;
  final bool isScaleDone;

  const ModeSquareImage({
    super.key,
    required this.mode,
    this.height,
    this.isError = false,
    required this.isScaleDone,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = (mode == WorkingMode.combined)
        ? (!isScaleDone
              ? mode.illustrations
              : 'assets/images/bp_illustration_real.jpg')
        : mode.illustrations;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError ? Colors.red.shade400 : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          key: ValueKey(imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
