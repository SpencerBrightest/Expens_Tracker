import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../ai/insights.dart';
import '../providers/expense_store.dart';
import '../theme/app_colors.dart';
import '../widgets/spending_pie_chart.dart';
import '../widgets/spending_trend_chart.dart';

/// Analytics: insight one-liner, Spending Breakdown donut with a
/// Totals | Percentages filter (fl_chart), and the monthly trend.
/// The summary row shows the computed total (`=SUM` of expenses),
/// category count, and top-category share.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _showPercentage = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            children: [
              const Text(
                'Analytics',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.amber,
                    ),
                  ),
                  title: const Text(
                    'Insight',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Builder(
                    builder: (context) {
                      return Text(buildInsight(context.watch<ExpenseStore>()));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final store = context.watch<ExpenseStore>();
                  final totals = store.totalsByCategory();
                  String topLine = 'No spending yet';
                  if (totals.isNotEmpty) {
                    final top = totals.entries.reduce(
                      (a, b) => a.value >= b.value ? a : b,
                    );
                    final share = store.shareOfTotal(top.key);
                    topLine =
                        '${store.categoryName(top.key)} · ${(share * 100).toStringAsFixed(1)}% of spending';
                  }
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCell(
                              label: 'Total spent',
                              value: xafFormat.format(store.totalSpent),
                            ),
                          ),
                          Expanded(
                            child: _SummaryCell(
                              label: 'Categories',
                              value: '${totals.length}',
                            ),
                          ),
                          Expanded(
                            child: _SummaryCell(
                              label: 'Top category',
                              value: topLine,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spending Breakdown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Totals'),
                            icon: Icon(Icons.payments_outlined),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Percentages'),
                            icon: Icon(Icons.percent_outlined),
                          ),
                        ],
                        selected: {_showPercentage},
                        onSelectionChanged: (s) =>
                            setState(() => _showPercentage = s.first),
                      ),
                      const SizedBox(height: 12),
                      SpendingPieChart(showPercentage: _showPercentage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income vs Expenses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      SpendingTrendChart(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
