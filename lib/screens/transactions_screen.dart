import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/expense_tile.dart';

/// History list, newest-first.
/// Signed in → pages remote results with `limit()/startAfter()` (20 per
/// page, Load-more button). Signed out → local store list.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _pageSize = 20;

  List<Expense>? _remote;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadFirst);
  }

  Future<void> _loadFirst() async {
    final svc = mounted ? context.read<FirestoreService?>() : null;
    if (svc == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final page = await svc.fetchExpensesPage(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _remote = page.expenses;
        _cursor = page.lastDoc;
        _done = page.expenses.length < _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final svc = context.read<FirestoreService?>();
    if (svc == null || _loadingMore || _done) return;
    setState(() => _loadingMore = true);
    try {
      final page = await svc.fetchExpensesPage(
        limit: _pageSize,
        startAfter: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _remote = [...?_remote, ...page.expenses];
        _cursor = page.lastDoc;
        _done = page.expenses.length < _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ExpenseStore>();
    final svc = context.watch<FirestoreService?>();
    // Remote mode only when signed in; otherwise the local store list.
    final expenses = svc == null ? store.expenses : (_remote ?? const []);
    final showPager = svc != null;
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
              if (_loading && showPager)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ...expenses.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ExpenseTile.forExpense(context, e),
                  ),
                ),
              if (showPager && !_loading && !_done)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _loadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton(
                          onPressed: _loadMore,
                          child: const Text('Load more'),
                        ),
                ),
              if (!showPager || _done)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'End of recent history',
                      style: TextStyle(color: AppColors.textSecondary),
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
