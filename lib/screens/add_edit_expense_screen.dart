import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/category_suggest.dart';
import '../ai/summary.dart';
import '../data/dummy_data.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

/// Add/Edit modal. Requires the signed-in user's [FirestoreService] and
/// persists remotely with optimistic UI + rollback.
class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _subcategory;
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
    _subcategory = TextEditingController(
      text: widget.expense?.subcategory ?? widget.expense?.note ?? '',
    );
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
    _subcategory.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<ExpenseStore>();
    final service = context.read<FirestoreService?>();
    final messenger = ScaffoldMessenger.of(context);
    if (service == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Sign in and try again.')),
      );
      return;
    }
    final categories = store.categories;
    final options = categories.isEmpty ? starterCategories : categories;
    final category = options.firstWhere(
      (item) => item.id == (_categoryId ?? options.first.id),
      orElse: () => options.first,
    );
    if (_subcategory.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a subcategory')),
      );
      return;
    }
    if (categories.isEmpty) {
      try {
        for (final starter in starterCategories) {
          store.addCategory(starter);
          await service.saveCategory(starter);
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
        return;
      }
    } else if (categories.every((item) => item.id != category.id)) {
      store.addCategory(category);
      await service.saveCategory(category);
    }
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter an amount above 0')),
      );
      return;
    }
    final expense = Expense(
      id: widget.expense?.id ?? 'e${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      categoryId: category.id,
      note: _note.text.trim(),
      subcategory: _subcategory.text.trim(),
      date: widget.expense?.date ?? DateTime.now(),
      paymentMethod: widget.expense?.paymentMethod ?? 'Cash',
    );
    setState(() => _busy = true);
    try {
      await store.persistExpense(service, expense);
      if (!mounted) return;
      // Fire-and-forget threshold check (never blocks Save).
      final cat = store.categoryFor(expense);
      context
          .read<NotificationService>()
          .budgetAlertIfNeeded(
            categoryName: cat.name,
            spent: store.totalByCategory(category.id),
            limit: cat.monthlyLimit,
          )
          .ignore();
      // Fire-and-forget AI summary patch (never blocks Save).
      _patchSummaryAsync(expense, cat.name, service);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Async summary patch: saves happen immediately with the template
  /// summary; the LLM-cleaned version patches in when ready. All errors
  /// swallowed — Save must never fail because of AI.
  void _patchSummaryAsync(
    Expense expense,
    String categoryName,
    FirestoreService service,
  ) {
    final store = context.read<ExpenseStore>();
    final summarizer = context.read<SummaryService>();
    (() async {
      try {
        final summary = await summarizer.summarize(
          expense: expense,
          categoryName: categoryName,
        );
        if (summary == expense.summary) return;
        final updated = expense.copyWith(summary: summary);
        try {
          await store.persistExpense(service, updated);
        } catch (_) {
          // Remote patch failed; the saved template summary stands.
        }
      } catch (_) {
        // Never let AI break the app.
      }
    })().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpenseStore>().categories;
    final selected = _categoryId ??= categories.isEmpty
        ? null
        : categories.first.id;
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
                    onPressed: () =>
                        setState(() => _amount.text = v.toString()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selected ?? starterCategories.first.id,
                decoration: const InputDecoration(labelText: 'Category'),
                items: (categories.isEmpty ? starterCategories : categories)
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subcategory,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Subcategory',
                  hintText: 'e.g. Rent, Jamila, Electricity',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Details for AI note (optional)',
                  hintText: 'Add context to summarize',
                ),
              ),
              Builder(
                builder: (context) {
                  final suggestedId = _suggestedId;
                  final currentId =
                      _categoryId ??
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
                },
              ),
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
