import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingNewView extends StatelessWidget {
  const LoadingNewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          /// ===== Medical Icon =====
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              size: 70,
              color: Colors.blue,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(0.95, 0.95),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),

          const SizedBox(height: 40),

          /// ===== Main Text =====
          Text(
            "กำลังค้นหาข้อมูลผู้ป่วย",
            style: GoogleFonts.kanit(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade800,
            ),
          ),

          const SizedBox(height: 14),

          /// ===== Animated Dots =====
          Text(
            "กรุณารอสักครู่",
            style: GoogleFonts.kanit(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 600.ms)
              .then(delay: 300.ms)
              .fadeOut(duration: 600.ms),
        ],
      ),
    );
  }
}