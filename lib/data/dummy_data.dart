import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

/// Phase 1 static dummy data. Converted from Stitch USD mock values to XAF.
/// Replaced by Provider state (Phase 3) and Firestore (Phase 6).
final xafFormat = NumberFormat.currency(
  locale: 'fr_CM',
  name: 'XAF',
  symbol: 'XAF ',
  decimalDigits: 0,
);

class DummyCategory {
  const DummyCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.spent,
    required this.limit,
  });
  final String name;
  final IconData icon;
  final Color color;
  final double spent;
  final double limit;
}

class DummyExpense {
  const DummyExpense({
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.amount,
    required this.isIncome,
    required this.icon,
    required this.color,
  });
  final String title;
  final String category;
  final String dateLabel;
  final double amount;
  final bool isIncome;
  final IconData icon;
  final Color color;
}

const dummyCategories = <DummyCategory>[
  DummyCategory(
    name: 'Housing',
    icon: Icons.home_outlined,
    color: AppColors.primary,
    spent: 1200,
    limit: 1500,
  ),
  DummyCategory(
    name: 'Food & Dining',
    icon: Icons.restaurant_outlined,
    color: AppColors.expense,
    spent: 820,
    limit: 1000,
  ),
  DummyCategory(
    name: 'Transport',
    icon: Icons.directions_car_outlined,
    color: AppColors.sky,
    spent: 340,
    limit: 500,
  ),
  DummyCategory(
    name: 'Entertainment',
    icon: Icons.movie_outlined,
    color: AppColors.coral,
    spent: 180,
    limit: 300,
  ),
  DummyCategory(
    name: 'Health',
    icon: Icons.favorite_outline,
    color: AppColors.success,
    spent: 110,
    limit: 250,
  ),
  DummyCategory(
    name: 'Shopping',
    icon: Icons.shopping_bag_outlined,
    color: AppColors.amber,
    spent: 490,
    limit: 600,
  ),
];

const dummyExpenses = <DummyExpense>[
  DummyExpense(
    title: 'Grocery Store',
    category: 'Food & Groceries',
    dateLabel: 'Today, 2:15 PM',
    amount: 64.20,
    isIncome: false,
    icon: Icons.shopping_cart_outlined,
    color: AppColors.expense,
  ),
  DummyExpense(
    title: 'Moto to school',
    category: 'Transport',
    dateLabel: 'Yesterday',
    amount: 45.00,
    isIncome: false,
    icon: Icons.two_wheeler_outlined,
    color: AppColors.sky,
  ),
  DummyExpense(
    title: 'Netflix Subscription',
    category: 'Entertainment',
    dateLabel: 'Nov 18',
    amount: 15.99,
    isIncome: false,
    icon: Icons.movie_outlined,
    color: AppColors.purple,
  ),
  DummyExpense(
    title: 'Freelance Payout',
    category: 'Income',
    dateLabel: 'Nov 17',
    amount: 850.00,
    isIncome: true,
    icon: Icons.add_task_outlined,
    color: AppColors.success,
  ),
];

const dummyMonthTotal = 3450.0;
const dummyMonthCap = 5000.0;

/// Donut segments mirror analytics_insights Stitch values.
const dummyBreakdown = <String, double>{
  'Housing': 1200,
  'Food': 820,
  'Shopping': 560,
  'Health': 400,
  'Transport': 340,
  'Other': 130,
};
