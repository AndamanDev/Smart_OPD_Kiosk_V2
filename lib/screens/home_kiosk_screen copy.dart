
import 'package:flutter/material.dart';

/// =======================================================
/// BREAKPOINTS
/// =======================================================

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// =======================================================
/// RESPONSIVE CONFIG
/// =======================================================

class ResponsiveConfig {
  final double width;
  final double height;

  ResponsiveConfig({required this.width, required this.height});

  bool get isLandscape => width > height;

  double scale(double size) {
    if (width >= Breakpoints.tablet) return size * 1.2;
    if (width >= Breakpoints.mobile) return size * 1.1;
    return size;
  }
}

/// =======================================================
/// LAYOUT RATIO (PRO WAY)
/// =======================================================

class LayoutRatio {
  static const int left = 1;
  static const int right = 1;
}

/// =======================================================
/// ROOT
/// =======================================================

class HomeKioskScreen extends StatelessWidget {
  const HomeKioskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        return MainLayout(config: config);
      },
    );
  }
}

/// =======================================================
/// MAIN LAYOUT (3 SECTIONS)
/// =======================================================

class MainLayout extends StatelessWidget {
  final ResponsiveConfig config;

  const MainLayout({super.key, required this.config});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// ================= TOP =================
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  flex: LayoutRatio.left,
                  child: _box("TOP LEFT", Colors.blue),
                ),
                Expanded(
                  flex: LayoutRatio.right,
                  child: _box("TOP RIGHT", Colors.green),
                ),
              ],
            ),
          ),

          /// ================= MIDDLE =================
          Expanded(
            flex: 6,
            child: config.isLandscape
                ? _buildMiddleLandscape()
                : _buildMiddlePortrait(),
          ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.black87,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }

  /// ============================================
  /// LANDSCAPE
  /// ============================================

  Widget _buildMiddleLandscape() {
    return Row(
      children: [
        /// ================= LEFT =================
        Expanded(
          flex: LayoutRatio.left,
          child: Padding(
            padding: const EdgeInsets.only(left: 50, right: 50),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: Colors.orange.withOpacity(0.2),
                    child: const Center(child: Text("IMAGE 1:1")),
                  ),
                ),
              ),
            ),
          ),
        ),

        /// ================= RIGHT =================
        Expanded(
          flex: LayoutRatio.right,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 50, right: 50),

                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purple, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("RIGHT TOP")),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 50, right: 50),

                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("RIGHT BOTTOM")),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ============================================
  /// PORTRAIT
  /// ============================================

  Widget _buildMiddlePortrait() {
    return Column(
      children: [
        /// RIGHT TOP (เล็กลง)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _textCard("RIGHT TOP", Colors.purple),
          ),
        ),

        const SizedBox(height: 12),

        /// IMAGE 1:1 (เด่นสุด)
        Expanded(
          flex: 5, // 👈 เพิ่มน้ำหนักตรงนี้
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                border: Border.all(color: Colors.orange, width: 4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: Colors.orange.withOpacity(0.2),
                    child: const Center(
                      child: Text(
                        "IMAGE 1:1",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// RIGHT BOTTOM (เล็กลง)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _textCard("RIGHT BOTTOM", Colors.teal),
          ),
        ),
      ],
    );
  }

  Widget _textCard(String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: config.scale(18),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ============================================
  /// REUSABLE BOX
  /// ============================================

  Widget _box(String text, Color color) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: config.scale(18),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
