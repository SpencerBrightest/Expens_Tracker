import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../theme/app_colors.dart';
import '../widgets/expense_tile.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

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
                'History',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Search merchants, categories...',
                  prefixIcon: Icon(Icons.search_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.insights_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(xafFormat.format(dummyMonthTotal)),
                  subtitle: const Text('spent • 42 transactions'),
                ),
              ),
              const SizedBox(height: 12),
              ...dummyExpenses.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExpenseTile(
                    title: e.title,
                    subtitle: '${e.category} • ${e.dateLabel}',
                    amountLabel:
                        '${e.isIncome ? '+' : '-'}${xafFormat.format(e.amount)}',
                    isIncome: e.isIncome,
                    icon: e.icon,
                    color: e.color,
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
