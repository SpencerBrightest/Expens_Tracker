import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Static trend bars for Phase 1. Wired to state in Phase 4.
class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    const values = [3.0, 4.2, 3.6, 5.0, 4.4, 5.6];
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          barGroups: List.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  color: i == 3
                      ? AppColors.primary
                      : AppColors.surfaceHigh,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
