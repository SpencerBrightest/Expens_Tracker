Do a security review of this Flutter/Firebase codebase (Ndoh). Go
through each category below, check the actual code and config, and
report specific findings with file/line references — not generic
advice.

1. Firestore Security Rules
   - Confirm every read/write rule requires request.auth != null and
     scopes data to request.auth.uid — no collection should be
     readable/writable by any authenticated user regardless of uid
   - Flag any rule that reads "allow read, write: if true" or is
     otherwise unscoped

2. Firebase Authentication
   - Confirm password fields enforce a minimum length/complexity
     before hitting Firebase Auth
   - Confirm auth error messages don't leak whether an email exists
     in the system (should be a generic failure message either way)
   - Confirm no hardcoded test account or auth bypass was left in

3. Secrets & API Keys
   - Confirm no Firebase service-account JSON or private key is
     bundled into the app or committed to the repo — only the public
     client config belongs there
   - If any AI feature (summary, insight card) calls an external LLM
     API directly from the Flutter client, flag it as high-severity —
     that call must go through a server-side function, never directly
     from the client with an embedded key
   - Confirm .env or any secrets file is in .gitignore and was never
     committed to git history

4. Local/Secure Storage
   - Confirm auth tokens or sensitive data use flutter_secure_storage,
     not plain SharedPreferences

5. Input Handling
   - Confirm amount fields reject non-numeric/negative values before
     reaching Firestore
   - Confirm note/text fields have a reasonable length cap

6. Dependencies
   - Check pubspec.yaml for any package with a known CVE or that's
     significantly out of date

7. Notifications
   - Confirm sensitive expense details don't appear in a way that
     shows on a locked device's notification banner

Report each finding as: [severity] file/location — issue — fix.