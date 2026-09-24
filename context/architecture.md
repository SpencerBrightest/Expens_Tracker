# Architecture — Ndoh
- `lib/services/auth_service.dart` / `firestore_service.dart` are the ONLY
  Firebase touchpoints. Screens/widgets never import firebase packages.
- Auth gate listens to `authStateChanges()`.
- Firestore: `users/{uid}/expenses/{id}`, `users/{uid}/categories/{id}`.
- Provider caches categories, paginates with `limit()/startAfter()`,
  optimistic save with rollback, debounce typing work.
