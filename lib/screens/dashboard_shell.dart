import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_preferences.dart';
import '../providers/expense_store.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'add_edit_expense_screen.dart';
import 'analytics_screen.dart';
import 'categories_screen.dart';
import 'home_tab.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

/// Dashboard shell: authenticated bottom-nav with 5 tabs + FAB modal.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Pull the user's cloud data once per shell mount (signed-in only).
    Future.microtask(() {
      if (!mounted) return;
      final svc = context.read<FirestoreService?>();
      final user = context.read<AuthService>().currentUser;
      if (svc == null || user == null) return;
      _loadAccountData(
        svc,
        user,
        context.read<ExpenseStore>(),
        context.read<NotificationService>(),
      ).ignore();
    });
  }

  Future<void> _loadAccountData(
    FirestoreService service,
    NdohUser user,
    ExpenseStore store,
    NotificationService notifications,
  ) async {
    final storeLoad = store.loadFromRemote(service);
    try {
      await service.saveUserProfile(
        email: user.email,
        displayName: user.displayName,
      );
    } catch (_) {}
    UserPreferences? preferences;
    try {
      preferences = await service.loadUserPreferences();
    } catch (_) {}
    if (preferences == null) {
      try {
        await service.saveUserPreferences(
          UserPreferences(
            dailyReminder: notifications.dailyReminder,
            budgetAlerts: notifications.budgetAlerts,
          ),
        );
      } catch (_) {}
    } else {
      try {
        await notifications.setDailyReminder(preferences.dailyReminder);
      } catch (_) {}
      notifications.setBudgetAlerts(preferences.budgetAlerts);
    }
    await storeLoad;
  }

  static const _tabs = [
    HomeTab(),
    TransactionsScreen(),
    CategoriesScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  void _openAdd() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddEditExpenseScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.donut_large_outlined),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
