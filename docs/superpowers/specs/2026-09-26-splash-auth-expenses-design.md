# Ndoh Splash → Auth → Expenses — Design A (approved 2026-09-26)

## Decisions (user-approved)
- Homepage stays public: Splash → Homepage → Auth → Dashboard.
- Splash scope: Flutter splash only (no native launch_background change).
- Auth errors: friendly UI messages only (no codes in UI).
- Name rule: greeting is always the authenticated user's own name
  ("Hey Spencer"), never hardcoded. Derived from Firebase displayName,
  else email prefix.
- Firestore: no key needed from user (firebase_options.dart already
  configured for expense-tracker-ca5d2).
- Git: Phase 1 local commits to main; Phase 2 push only on explicit "push".

## Architecture
1. Splash: new `lib/widgets/splash_gate.dart` shows `SplashScreen` for
   2s (Timer, disposed properly), then `AuthGate`. `main.dart` home is
   `SplashGate`. `AuthGate` unchanged (authStateChanges stream).
2. Auth/name: `AuthService.displayNameFromEmail` derives
   "Spencer Bright" from "spencer.bright@x.com". `signUp` resolves blank
   names to the email-derived name before calling the backend, so
   Firebase stores it and `NdohUser.firstName` greets correctly.
   `home_tab.dart` + `settings_screen.dart` already consume `firstName`.
   Signup hints updated to Spencer examples.
3. Expenses: unchanged path `users/{uid}/expenses/{id}` via
   `FirestoreService` + `ExpenseStore.persistExpense` (optimistic +
   rollback). Phase 1 re-verifies only.
4. Errors: friendly sentences only. Tradeoff: no searchable code in UI;
   debug by reproducing message text.
5. Tests: splash gate covered by pumpAndSettle; auth signup still passes
   fakes (uid/email assertions unaffected by derived displayName).

## Self-review
- No placeholders; scope is one surgical change-set.
- Consistent with AGENTS.md (flat colors, XAF, no direct firebase
  imports in screens, authStateChanges gate, per-user scoping).
- No secrets added; .env stays gitignored.
