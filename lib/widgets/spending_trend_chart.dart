import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_store.dart';
import '../theme/app_colors.dart';

/// Trend bars wired to [ExpenseStore] (Phase 4): monthly buckets
/// oldest-first via [ExpenseStore.monthlyTotals].
class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({super.key, this.months = 6, this.reference});

  final int months;
  final DateTime? reference;

  @override
  Widget build(BuildContext context) {
    final values = context.watch<ExpenseStore>().monthlyTotals(
          months: months,
          reference: reference,
        );
    final maxV = values.fold(0.0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxV <= 0 ? 1 : maxV * 1.15,
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
                  color: i == values.length - 1
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
