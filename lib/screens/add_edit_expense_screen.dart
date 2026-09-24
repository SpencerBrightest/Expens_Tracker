import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
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
  String? _categoryId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.expense?.amount.toInt().toString() ?? '5000',
    );
    _note = TextEditingController(text: widget.expense?.note ?? '');
    _categoryId = widget.expense?.categoryId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<ExpenseStore>();
    final service = context.read<FirestoreService?>();
    final categories = store.categories;
    if (categories.isEmpty) return;
    final categoryId = _categoryId ?? categories.first.id;
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
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
