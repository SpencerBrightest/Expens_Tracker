import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ai/summary.dart';
import 'firebase_options.dart';
import 'providers/expense_store.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';
import 'widgets/splash_gate.dart';

/// Fresh users start with no expenses; the store seeds five categories on
/// first sign-in and loads the user's Firestore data.
ExpenseStore seedStore() => ExpenseStore();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notifications = NotificationService();
  await notifications.init();
  await notifications.setDailyReminder(true);
  final authService = AuthService();
  runApp(
    NdohApp(
      store: seedStore(),
      authService: authService,
      notificationService: notifications,
      summaryService: SummaryService(
        llm: ProxyLlmBackend(
          endpoint: Uri.parse(
            'https://us-central1-expense-tracker-ca5d2.cloudfunctions.net/getGeminiSummary',
          ),
          idTokenProvider: authService.getIdToken,
        ),
      ),
    ),
  );
}

/// Ndoh root. Cold start shows [SplashGate] (custom splash ~2s), which then
/// hands off to [AuthGate] listening to [AuthService.authStateChanges] —
/// never a one-time check.
/// [FirestoreService] is exposed per signed-in user (null when signed out).
class NdohApp extends StatelessWidget {
  const NdohApp({
    super.key,
    this.store,
    this.authService,
    this.notificationService,
    this.summaryService,
  });

  final ExpenseStore? store;
  final AuthService? authService;
  final NotificationService? notificationService;
  final SummaryService? summaryService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseStore>.value(value: store ?? seedStore()),
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
            return user == null ? null : FirestoreService(uid: user.uid);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Ndoh',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashGate(),
        routes: {
          '/auth': (_) => const AuthGate(),
          '/dashboard': (_) => const AuthGate(),
        },
      ),
    );
  }
}
