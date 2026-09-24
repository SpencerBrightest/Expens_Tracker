import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/category_suggest.dart';
import '../ai/summary.dart';
import '../data/dummy_data.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

/// Add/Edit modal. Saves to [ExpenseStore] locally and — when signed in
/// ([FirestoreService] available) — persists remotely with optimistic
/// UI + rollback. Never blocks on the network.
class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _newCategory;
  String? _categoryId;
  String? _suggestedId;
  Timer? _debounce;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.expense?.amount.toInt().toString() ?? '5000',
    );
    _note = TextEditingController(text: widget.expense?.note ?? '');
    _newCategory = TextEditingController();
    _categoryId = widget.expense?.categoryId;
    _note.addListener(_onNoteChanged);
  }

  /// Debounced (300ms) keyword suggestion — cheap, never a network call.
  void _onNoteChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final id = suggestCategoryId(
        _note.text,
        context.read<ExpenseStore>().categories,
      );
      setState(() => _suggestedId = id);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _note.removeListener(_onNoteChanged);
    _amount.dispose();
    _note.dispose();
    _newCategory.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<ExpenseStore>();
    final service = context.read<FirestoreService?>();
    final messenger = ScaffoldMessenger.of(context);
    final categories = store.categories;
    // No silent dead-end: with no categories yet, create one inline from
    // the "New category" field.
    String categoryId;
    if (categories.isEmpty) {
      final name = _newCategory.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name a category first')),
        );
        return;
      }
      final created = Category(
        id: 'c${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        monthlyLimit: 0,
        colorValue: 0xFF2D68FE,
        iconCodePoint: 0xe318,
      );
      try {
        store.addCategory(created);
        if (service != null) await service.saveCategory(created);
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
        return;
      }
      categoryId = created.id;
    } else {
      categoryId = _categoryId ?? categories.first.id;
    }
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter an amount above 0')),
      );
      return;
    }
    final expense = Expense(
      id: widget.expense?.id ??
          'e${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      categoryId: categoryId,
      note: _note.text.trim(),
      date: widget.expense?.date ?? DateTime.now(),
      paymentMethod: widget.expense?.paymentMethod ?? 'Cash',
    );
    setState(() => _busy = true);
    try {
      if (service == null) {
        if (widget.expense == null) {
          store.addExpense(expense);
        } else {
          store.updateExpense(expense);
        }
      } else {
        await store.persistExpense(service, expense);
      }
      if (!mounted) return;
      // Fire-and-forget threshold check (never blocks Save).
      final cat = store.categoryFor(expense);
      context.read<NotificationService>().budgetAlertIfNeeded(
            categoryName: cat.name,
            spent: store.totalByCategory(categoryId),
            limit: cat.monthlyLimit,
          ).ignore();
      // Fire-and-forget AI summary patch (never blocks Save).
      _patchSummaryAsync(expense, cat.name);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Async summary patch: saves happen immediately with the template
  /// summary; the LLM-cleaned version patches in when ready. All errors
  /// swallowed — Save must never fail because of AI.
  void _patchSummaryAsync(Expense expense, String categoryName) {
    final store = context.read<ExpenseStore>();
    final service = context.read<FirestoreService?>();
    final summarizer = context.read<SummaryService>();
    Future(() async {
      try {
        final summary = await summarizer.summarize(
          expense: expense,
          categoryName: categoryName,
        );
        if (summary == expense.summary) return;
        final updated = expense.copyWith(summary: summary);
        if (service == null) {
          try {
            store.updateExpense(updated);
          } catch (_) {
            // Expense may be gone (deleted/rolled back); ignore.
          }
        } else {
          try {
            await store.persistExpense(service, updated);
          } catch (_) {
            // Remote patch failed; local template summary stands.
          }
        }
      } catch (_) {
        // Never let AI break the app.
      }
    }).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpenseStore>().categories;
    final selected = _categoryId ??=
        categories.isEmpty ? null : categories.first.id;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.expense == null ? 'Add Expense' : 'Edit Expense',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (XAF)',
                  hintText: '5000',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [1000, 5000, 10000, 25000].map((v) {
                  return ActionChip(
                    label: Text('+${xafFormat.format(v)}'),
                    onPressed: () => setState(
                      () => _amount.text = v.toString(),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                TextField(
                  controller: _newCategory,
                  decoration: const InputDecoration(
                    labelText: 'New category',
                    hintText: 'e.g. Transport',
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note / Merchant',
                  hintText: 'e.g. moto to school',
                ),
              ),
              Builder(builder: (context) {
                final suggestedId = _suggestedId;
                final currentId = _categoryId ??
                    (categories.isEmpty ? null : categories.first.id);
                if (suggestedId == null || suggestedId == currentId) {
                  return const SizedBox.shrink();
                }
                String? name;
                for (final c in categories) {
                  if (c.id == suggestedId) {
                    name = c.name;
                    break;
                  }
                }
                if (name == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text('Try $name'),
                    onPressed: () => setState(() {
                      _categoryId = suggestedId;
                      _suggestedId = null;
                    }),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Expense'),
              ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Center(child: Text('Cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
