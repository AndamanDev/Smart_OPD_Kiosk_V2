import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/working_mode.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/BloodPressureUtils.dart';
import '../../../utils/ScaleUtils.dart';

class ResultSection extends StatelessWidget {
  final WorkingMode mode;
  final bool isError;
  final bool isScaleDone;
  final String image;

  final ScaleReading scale;
  final BloodReading? blood;

  final String weight;
  final String height;
  final String bmi;
  final String unitweight;
  final String unitheight;
  final String unitbmi;

  final String sys;
  final String dia;
  final String pulse;

  final String unitsys;
  final String unitdia;
  final String unitpulse;

  const ResultSection({
    super.key,
    required this.mode,
    this.isError = false,
    required this.isScaleDone,
    required this.image,

    required this.scale,
    required this.blood,

    required this.weight,
    required this.height,
    required this.bmi,
    required this.unitweight,
    required this.unitheight,
    required this.unitbmi,

    required this.sys,
    required this.dia,
    required this.pulse,

    required this.unitsys,
    required this.unitdia,
    required this.unitpulse,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final base = (c.maxWidth * 0.085).clamp(18, 48).toDouble();

        final settings = context.watch<SettingsProvider>();

        return  Container(
            height: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14), // ให้เท่ากัน
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: _landscapeLayout(base, settings),
        );
      },
    );
  }

  Widget _landscapeLayout(double base, SettingsProvider settings) {
    final bp = blood;

    switch (mode) {
      case WorkingMode.scaleOnly:
        return _scaleColumn(base);

      case WorkingMode.bloodPressureOnly:
        return _bpColumn(base, bp, settings);

      case WorkingMode.combined:
        return Row(
          children: [
            Expanded(child: _scaleColumn(base)),
            const SizedBox(width: 8),
            Expanded(child: _bpColumn(base, bp, settings)),
          ],
        );
    }
  }

  Widget _scaleColumn(double base) {
    return Column(
      children: [
        _item(weight, scale.weight.toString(), unitweight, Colors.blue, base),
        const SizedBox(height: 10),

        _item(height, scale.height.toString(), unitheight, Colors.blue, base),
        const SizedBox(height: 10),

        _item(bmi, scale.bmi.toString(), unitbmi, Colors.blue, base),
      ],
    );
  }

  Widget _bpColumn(double base, BloodReading? bp, SettingsProvider settings) {
    return Column(
      children: [
        _item(
          sys,
          bp?.systolic.toString() ?? "-",
          unitsys,
          BloodPressureUtils.sysColor(bp?.systolic ?? 0, settings.sysMax),
          base,
          showColors: true,
        ),
        const SizedBox(height: 10),

        _item(
          dia,
          bp?.diastolic.toString() ?? "-",
          unitdia,
          BloodPressureUtils.diaColor(bp?.diastolic ?? 0),
          base,
          showColors: true,
        ),
        const SizedBox(height: 10),

        _item(
          pulse,
          bp?.pulse.toString() ?? "-",
          unitpulse,
          BloodPressureUtils.pulseColor(bp?.pulse ?? 0),
          base,
          showColors: true,
        ),
      ],
    );
  }

  Widget _item(
    String title,
    String value,
    String unit,
    Color color,
    double base, {
    bool showColors = false,
  }) {
    String display;

    final numVal = double.tryParse(value);

    if (numVal == null || numVal <= 0) {
      display = "-";
    } else if (numVal == numVal.toInt()) {
      display = numVal.toInt().toString();
    } else {
      display = numVal.toStringAsFixed(1);
    }

    return Expanded(
      child: ResultCard(
        title: title,
        value: display,
        unit: unit,
        label: "MEASURED",
        range: '',
        color: color,
        showColors: showColors,
        baseFontSize: base,
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String range;
  final String label;
  final Color color;
  final bool showColors;
  final bool isBlinking;
  final double? baseFontSize;
  final bool isVertical;

  const ResultCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.range,
    required this.label,
    required this.color,
    required this.showColors,
    this.isBlinking = false,
    this.isVertical = false,
    required this.baseFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNoValue = value == "-" || value.trim().isEmpty;

    final effectiveColor = isNoValue
        ? Colors.blue
        : isBlinking
        ? Colors.red
        : (showColors ? color : Colors.blue);

    final base = baseFontSize!;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: effectiveColor.withOpacity(isBlinking ? 1.0 : 0.3),
          width: isBlinking ? 4 : 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: base * 0.3,
              vertical: base * 0.2,
            ),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: effectiveColor,
                      ),
                    ),
                  ),
                ),

                Text(
                  range,
                  style: TextStyle(fontSize: base * 0.0, color: Colors.blue),
                ),
              ],
            ),
          ),

          /// BODY
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: base * 0.2),
              child: Row(
                children: [
                  Expanded(
                    child: Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          /// VALUE
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  color: effectiveColor,
                                  height: 1,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: base * 0.15), // ⭐ ระยะห่าง
                          /// UNIT (ต่อท้าย)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isBlinking) {
      return cardContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(duration: 500.ms, begin: 1, end: 0.4);
    }

    return cardContent;
  }
}
