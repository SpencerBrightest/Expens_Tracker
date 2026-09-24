import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../theme/app_colors.dart';

/// Add/Edit modal. Phase 1: static, Save closes. No AI chip until Phase 8.
class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({super.key});

  @override
  State<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _amount = TextEditingController(text: '5000');
  final _note = TextEditingController();
  String _category = 'Food & Dining';

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Add Expense',
                style: TextStyle(
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
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: dummyCategories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.name,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? _category),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Expense'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Center(child: Text('Cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
