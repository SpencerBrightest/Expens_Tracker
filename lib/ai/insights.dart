import '../providers/expense_store.dart';

/// One-line analytics insight for the card above the charts.
/// Priority: over-budget category > dominant share (>=50%) > spread.
/// Pure template logic — no network.
String buildInsight(ExpenseStore store) {
  if (store.expenses.isEmpty) {
    return 'Log your first expense to see insights.';
  }
  for (final c in store.categories) {
    final spent = store.totalByCategory(c.id);
    if (c.monthlyLimit > 0 && spent > c.monthlyLimit) {
      final over = (spent - c.monthlyLimit).toInt();
      return '${c.name} is over budget by $over XAF.';
    }
  }
  final total = store.totalSpent;
  if (total > 0) {
    String? topId;
    var top = 0.0;
    for (final e in store.totalsByCategory().entries) {
      if (e.value > top) {
        top = e.value;
        topId = e.key;
      }
    }
    if (topId != null) {
      final share = (top / total * 100).round();
      if (share >= 50) {
        final name = store.categoryFor(
          store.expenses.firstWhere((e) => e.categoryId == topId),
        ).name;
        return '$name is $share% of your spending.';
      }
    }
  }
  final used = store
      .categories
      .where((c) => store.totalByCategory(c.id) > 0)
      .length;
  return 'Your spending is spread across $used categories.';
}
