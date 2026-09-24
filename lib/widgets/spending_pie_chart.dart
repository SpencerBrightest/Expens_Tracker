import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../theme/app_colors.dart';

/// Static donut for Phase 1. Wired to state in Phase 4.
class SpendingPieChart extends StatelessWidget {
  const SpendingPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.expense,
      AppColors.primaryFixedDim,
      AppColors.amber,
      AppColors.coral,
    ];
    final entries = dummyBreakdown.entries.toList();
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 52,
          sectionsSpace: 2,
          sections: List.generate(entries.length, (i) {
            return PieChartSectionData(
              value: entries[i].value,
              color: colors[i % colors.length],
              radius: 36,
              showTitle: false,
            );
          }),
        ),
      ),
    );
  }
}
