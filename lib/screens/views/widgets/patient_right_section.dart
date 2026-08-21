import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_config.dart';
import '../../../models/working_mode.dart';

class PatientRightSection extends StatelessWidget {
  final WorkingMode mode;
  final double? height;
  final bool isError;
  final bool isScaleDone;
  final String image;
  final Map<String, dynamic> patient;
  final ResponsiveConfig config;

  final bool showBorder;

  const PatientRightSection({
    super.key,
    required this.mode,
    this.height,
    this.isError = false,
    required this.isScaleDone,
    required this.image,
    required this.patient,
    required this.config,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: showBorder ? BorderRadius.circular(14) : null,
        border: showBorder
            ? Border.all(
                color: isError ? Colors.red : Colors.grey.shade400,
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 5),
                Text(
                  "สวัสดี (Welcome)",
                  style: TextStyle(fontSize: 30, color: const Color.fromARGB(255, 0, 0, 0) , fontWeight:  FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  patient['FULLNAME'] ??
                      patient['Name'] ??
                      patient['name'] ??
                      "-",
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 121, 115, 115),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "HN: ${patient['HN'] ?? "-"}",
                    style: const TextStyle(fontSize: 28, color: Colors.white , fontWeight:  FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
