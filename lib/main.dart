import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ai/summary.dart';
import 'firebase_options.dart';
import 'providers/expense_store.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_shell.dart';
import 'screens/homepage_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

/// Fresh users start with a clean slate: no categories, no expenses.
/// Categories are created inline from Add/Edit Expense; cloud data loads
/// via [ExpenseStore.loadFromRemote] on sign-in.
ExpenseStore seedStore() => ExpenseStore();

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
