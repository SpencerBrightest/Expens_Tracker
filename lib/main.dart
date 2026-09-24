import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ai/summary.dart';
import 'data/dummy_data.dart';
import 'firebase_options.dart';
import 'models/category.dart';
import 'models/expense.dart';
import 'providers/expense_store.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_shell.dart';
import 'screens/homepage_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

/// Seed Category models from Stitch dummy data (cached in Provider per
/// AGENTS perf rule — never refetched per screen).
List<Category> seedCategories() => [
      for (var i = 0; i < dummyCategories.length; i++)
        Category(
          id: 'c${i + 1}',
          name: dummyCategories[i].name,
          monthlyLimit: dummyCategories[i].limit,
          colorValue: dummyCategories[i].color.toARGB32(),
          iconCodePoint: dummyCategories[i].icon.codePoint,
        ),
    ];

/// Local demo expenses mirroring the Stitch mock feed. Replaced by
/// [ExpenseStore.loadFromRemote] on sign-in.
List<Expense> seedExpenses(List<Category> categories) {
  String catFor(String hint) {
    for (final c in categories) {
      if (hint.toLowerCase().contains(c.name.split(' ').first.toLowerCase()) ||
          c.name.toLowerCase().contains(hint.split(' ').first.toLowerCase())) {
        return c.id;
      }
    }
    return categories.first.id;
  }

  final seeds = [
    (dummyExpenses[0].title, dummyExpenses[0].amount,
        dummyExpenses[0].category, DateTime(2024, 11, 20, 14, 15)),
    (dummyExpenses[1].title, dummyExpenses[1].amount,
        dummyExpenses[1].category, DateTime(2024, 11, 19, 8, 30)),
    (dummyExpenses[2].title, dummyExpenses[2].amount,
        dummyExpenses[2].category, DateTime(2024, 11, 18, 20, 0)),
    (dummyExpenses[3].title, dummyExpenses[3].amount,
        dummyExpenses[3].category, DateTime(2024, 11, 17, 9, 0)),
  ];
  return [
    for (var i = 0; i < seeds.length; i++)
      Expense(
        id: 'e${i + 1}',
        amount: seeds[i].$2,
        categoryId: catFor(seeds[i].$3),
        note: seeds[i].$1,
        date: seeds[i].$4,
        paymentMethod: 'Cash',
      ),
  ];
}

ExpenseStore seedStore() {
  final categories = seedCategories();
  return ExpenseStore(
    categories: categories,
    expenses: seedExpenses(categories),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final notifications = NotificationService();
  await notifications.init();
  await notifications.setDailyReminder(true);
  runApp(
    NdohApp(
      store: seedStore(),
      authService: AuthService(),
      notificationService: notifications,
      // Real Gemini path (template-only until --dart-define=GEMINI_API_KEY).
      summaryService: SummaryService(llm: const GeminiLlmBackend()),
    ),
  );
}

/// Ndoh root. Navigation is auth-gated via [AuthGate], which listens to
/// [AuthService.authStateChanges] — never a one-time check.
/// [FirestoreService] is exposed per signed-in user (null when signed out).
class NdohApp extends StatelessWidget {
  const NdohApp(
      {super.key, this.store, this.authService, this.notificationService, this.summaryService});

  final ExpenseStore? store;
  final AuthService? authService;
  final NotificationService? notificationService;
  final SummaryService? summaryService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseStore>.value(
          value: store ?? seedStore(),
        ),
        ChangeNotifierProvider<AuthService>.value(
          value: authService ?? AuthService(),
        ),
        ChangeNotifierProvider<NotificationService>.value(
          value: notificationService ?? NotificationService(),
        ),
        Provider<SummaryService>.value(
          value: summaryService ?? SummaryService(),
        ),
        ProxyProvider<AuthService, FirestoreService?>(
          update: (_, auth, _) {
            final user = auth.currentUser;
            return user == null
                ? null
                : FirestoreService(uid: user.uid);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Ndoh',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
        routes: {
          '/home': (_) => const HomepageScreen(),
          '/auth': (_) => const AuthScreen(),
          '/dashboard': (_) => const DashboardShell(),
        },
      ),
    );
  }
}
