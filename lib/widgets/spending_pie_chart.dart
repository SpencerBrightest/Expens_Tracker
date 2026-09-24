import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/expense_store.dart';
import '../theme/app_colors.dart';

/// Donut wired to [ExpenseStore] (Phase 4). Falls back to the Stitch dummy
/// breakdown when the store is empty so the screen never renders blank.
class SpendingPieChart extends StatelessWidget {
  const SpendingPieChart({super.key});

  static const _colors = [
    AppColors.primary,
    AppColors.success,
    AppColors.expense,
    AppColors.primaryFixedDim,
    AppColors.amber,
    AppColors.coral,
  ];

  @override
  Widget build(BuildContext context) {
    final totals = context.watch<ExpenseStore>().totalsByCategory();
    final entries = (totals.isEmpty ? dummyBreakdown : totals).entries
        .toList();
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 52,
          sectionsSpace: 2,
          sections: List.generate(entries.length, (i) {
            return PieChartSectionData(
              value: entries[i].value,
              color: _colors[i % _colors.length],
              radius: 36,
              showTitle: false,
            );
          }),
        ),
      ),
    );
  }
}
