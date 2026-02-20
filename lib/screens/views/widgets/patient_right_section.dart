import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  const PatientRightSection({
    super.key,
    required this.mode,
    this.height,
    this.isError = false,
    required this.isScaleDone,
    required this.image,
    required this.patient,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError ? Colors.red : Colors.grey.shade400,
          width: 2,
        ),
      ),
        child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 5),
              Text(
                "สวัสดี (Welcome)",
                style: TextStyle(fontSize: 24, color: Colors.grey[700]),
              ),

              const SizedBox(height: 12),

              Text(
                patient['Name'] ?? "Unknown",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:5,
                    vertical: 5
                  ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "HN: ${patient['HN'] ?? "Unknown"}",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
