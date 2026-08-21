import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
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
  final bool showCard;

  const ResultSection({
    super.key,
    required this.mode,
    this.isError = false,
    required this.isScaleDone,
    required this.image,
    this.showCard = true,

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

        return showCard
            ? Container(
                height: double.infinity,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
                child: _landscapeLayout(base, settings),
              )
            : SizedBox(
                height: double.infinity,
                child: _landscapeLayout(base, settings, blackTitle: true),
              );
      },
    );
  }

  Widget _landscapeLayout(double base, SettingsProvider settings, {bool blackTitle = false}) {
    final bp = blood;

    switch (mode) {
      case WorkingMode.scaleOnly:
        return _scaleColumn(base, blackTitle: blackTitle);

      case WorkingMode.bloodPressureOnly:
        return _bpColumn(base, bp, settings, blackTitle: blackTitle);

      case WorkingMode.combined:
        return Row(
          children: [
            Expanded(child: _scaleColumn(base, blackTitle: blackTitle)),
            const SizedBox(width: 8),
            Expanded(child: _bpColumn(base, bp, settings, blackTitle: blackTitle)),
          ],
        );
    }
  }

  Widget _scaleColumn(double base, {bool blackTitle = false}) {
    return Column(
      children: [
        _item(weight, scale.weight.toString(), unitweight, AppColors.primaryGreen, base,
            icon: Icons.monitor_weight_outlined, imageAsset: 'assets/images/kg.png', blackTitle: blackTitle),
        const SizedBox(height: 10),
        _item(height, scale.height.toString(), unitheight, AppColors.primaryGreen, base,
            icon: Icons.height, imageAsset: 'assets/images/cm.png', blackTitle: blackTitle),
        const SizedBox(height: 10),
        _item(bmi, scale.bmi.toString(), unitbmi, AppColors.primaryGreen, base,
            icon: Icons.calculate_outlined, imageAsset: 'assets/images/bmi.png', blackTitle: blackTitle),
      ],
    );
  }

  Widget _bpColumn(double base, BloodReading? bp, SettingsProvider settings, {bool blackTitle = false}) {
    return Column(
      children: [
        _item(sys, bp?.systolic.toString() ?? "-", unitsys,
          BloodPressureUtils.sysColor(bp?.systolic ?? 0, settings.sysMax), base,
          showColors: true, icon: Icons.favorite_outline, blackTitle: blackTitle),
        const SizedBox(height: 10),
        _item(dia, bp?.diastolic.toString() ?? "-", unitdia,
          BloodPressureUtils.diaColor(bp?.diastolic ?? 0), base,
          showColors: true, icon: Icons.favorite_border, blackTitle: blackTitle),
        const SizedBox(height: 10),
        _item(pulse, bp?.pulse.toString() ?? "-", unitpulse,
          BloodPressureUtils.pulseColor(bp?.pulse ?? 0), base,
          showColors: true, icon: Icons.monitor_heart_outlined, blackTitle: blackTitle),
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
    IconData? icon,
    String? imageAsset,
    bool blackTitle = false,
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
        cardIcon: icon,
        cardImageAsset: imageAsset,
        titleColor: blackTitle ? Colors.black87 : null,
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
  final IconData? cardIcon;
  final String? cardImageAsset;
  final Color? titleColor;

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
    this.cardIcon,
    this.cardImageAsset,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNoValue = value == "-" || value.trim().isEmpty;

    final effectiveColor = isNoValue
        ? AppColors.primaryGreen
        : isBlinking
        ? Colors.red
        : (showColors ? color : AppColors.primaryGreen);

    final base = baseFontSize!;
    final resolvedTitleColor = titleColor ?? effectiveColor;

    Widget cardContent = Container(
      decoration: AppCardDecoration.standard.copyWith(
        border: Border.all(
          color: effectiveColor.withOpacity(isBlinking ? 1.0 : 0.12),
          width: isBlinking ? 4 : 1.5,
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
              color: effectiveColor.withOpacity(0.05),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: resolvedTitleColor,
                      ),
                    ),
                  ),
                ),

                Text(
                  range,
                  style: TextStyle(fontSize: base * 0.0, color: effectiveColor),
                ),
              ],
            ),
          ),

          /// BODY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// ICON ชิดซ้าย ใหญ่
                  if (cardImageAsset != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: effectiveColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        cardImageAsset!,
                        width: base * 1.4,
                        height: base * 1.4,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else if (cardIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: effectiveColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        cardIcon!,
                        size: base * 1.4,
                        color: effectiveColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  /// VALUE + UNIT ชิดขวา
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 92,
                                fontWeight: FontWeight.bold,
                                color: Color.lerp(effectiveColor, Colors.black, 0.25),
                                height: 1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: base * 0.5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            unit,
                            style: TextStyle(
                              fontSize: 40,
                              color: Color.lerp(effectiveColor, Colors.black, 0.25),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: base * 0.5),
                      ],
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
