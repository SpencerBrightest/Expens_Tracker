import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/expense_store.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/category_icons.dart';
import '../widgets/expense_tile.dart';

/// Home tab: greeting, hero balance (XAF), top categories, recent list.
/// All figures come from [ExpenseStore].
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ExpenseStore>();
    // AuthService is present in production (DashboardShell) but may be
    // absent in isolated widget tests — fall back to "Friend" then.
    NdohUser? user;
    try {
      user = context.watch<AuthService>().currentUser;
    } catch (_) {
      user = null;
    }
    final firstName = user?.firstName ?? 'Friend';
    final initial =
        firstName.isEmpty ? 'N' : firstName[0].toUpperCase();
    final monthLabel = DateFormat('MMMM y').format(DateTime.now());
    final total = store.totalSpent;
    final cap = store.categories.fold(0.0, (s, c) => s + c.monthlyLimit);
    final remaining = cap - total;
    final progress = cap > 0 ? (total / cap).clamp(0.0, 1.0) : 0.0;
    final topCats = store.categories.take(3).toList();
    final recent = store.expenses.take(3).toList();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey $firstName 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent this month',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      xafFormat.format(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.successContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remaining: ${xafFormat.format(remaining)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Top Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: topCats.length,
                itemBuilder: (_, i) {
                  final c = topCats[i];
                  final color = Color(c.colorValue);
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            categoryIcon(c.iconCodePoint),
                            color: color,
                          ),
                          const Spacer(),
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            xafFormat.format(
                              store.totalByCategory(c.id),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                const Text(
                  'No expenses yet — tap + to add your first one.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ...recent.map(
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
