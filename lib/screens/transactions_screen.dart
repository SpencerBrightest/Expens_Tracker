import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/expense_store.dart';
import '../theme/app_colors.dart';
import '../widgets/expense_tile.dart';

/// History list, newest-first from [ExpenseStore].
/// (Service-level `limit()/startAfter()` pagination exists in
/// FirestoreService; infinite-scroll UI is a fast follow.)
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ExpenseStore>();
    final expenses = store.expenses;
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
                  title: Text(xafFormat.format(store.totalSpent)),
                  subtitle: Text(
                    'spent • ${expenses.length} transactions',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...expenses.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExpenseTile.forExpense(context, e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
