import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_store.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editProfile(BuildContext context, String currentName) async {
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _EditProfileDialog(initialName: currentName),
      );
      if (name == null || !context.mounted) return;
      await context.read<AuthService>().updateDisplayName(name);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationService>();
    NdohUser? user;
    try {
      user = context.watch<AuthService>().currentUser;
    } catch (_) {
      user = null;
    }
    final displayName = user?.displayName?.trim().isEmpty ?? true
        ? user?.firstName ?? 'Friend'
        : user!.displayName!.trim();
    final email = (user?.email ?? '').isEmpty ? 'Signed in' : user!.email;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            children: [
              Card(
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(displayName),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editProfile(context, displayName),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.public_outlined),
                      title: const Text('Primary Currency'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'XAF',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                      title: const Text('Daily Reminder'),
                      subtitle: const Text('Log expenses at 8:00 PM'),
                      value: notifications.dailyReminder,
                      onChanged: (v) => notifications.setDailyReminder(v),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.warning_amber_outlined),
                      title: const Text('Budget Alerts'),
                      subtitle: const Text('Alert at 80% & 100% cap'),
                      value: notifications.budgetAlerts,
                      onChanged: (v) => notifications.setBudgetAlerts(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                // The AuthGate listens to authStateChanges and redirects
                // to Homepage automatically — no explicit nav needed.
                // Local data is wiped first so the next account starts clean.
                onPressed: () {
                  context.read<ExpenseStore>().clear();
                  context.read<AuthService>().signOut();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.expense.withValues(alpha: 0.12),
                  foregroundColor: AppColors.expenseDeep,
                ),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Display name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
