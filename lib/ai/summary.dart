import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense.dart';

/// LLM contract for cleaning long/messy notes. Tests use a fake.
abstract class LlmBackend {
  Future<String> cleanup(String note);
}

/// Pass-through used when no key is configured.
class NoopLlmBackend implements LlmBackend {
  const NoopLlmBackend();

  @override
  Future<String> cleanup(String note) async => note;
}

/// Authenticated proxy backend: the Gemini key lives in the Cloud Function
/// (Functions secret), never in the client. The ID token comes from
/// [AuthService.getIdToken] via injection, so this file never imports
/// firebase_auth directly. Any failure falls back to the input note.
class ProxyLlmBackend implements LlmBackend {
  const ProxyLlmBackend({
    http.Client? client,
    required this.endpoint,
    required this.idTokenProvider,
  }) : _client = client; // ignore: prefer_initializing_formals

  final http.Client? _client;
  final Uri endpoint;
  final Future<String?> Function() idTokenProvider;

  @override
  Future<String> cleanup(String note) async {
    try {
      final token = await idTokenProvider();
      if (token == null || token.isEmpty) return note;
      final client = _client ?? http.Client();
      final res = await client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'note': note}),
      );
      if (res.statusCode != 200) return note;
      final body = jsonDecode(res.body);
      if (body is! Map) return note;
      final summary = body['summary'];
      if (summary is! String) return note;
      final cleaned = summary.trim();
      return cleaned.isEmpty ? note : cleaned;
    } catch (_) {
      return note;
    }
  }
}

/// One-line per-expense summary. Template by default (instant, free);
/// only long notes route to the LLM. Never throws.
class SummaryService {
  SummaryService({LlmBackend? llm, this.longNoteThreshold = 120})
      : _llm = llm ?? const NoopLlmBackend();

  final LlmBackend _llm;
  final int longNoteThreshold;

  Future<String> summarize({
    required Expense expense,
    required String categoryName,
  }) async {
    final note = expense.note.trim();
    if (note.length <= longNoteThreshold) {
      return expense.effectiveSummary(categoryName);
    }
    try {
      final cleaned = (await _llm.cleanup(note)).trim();
      final use = cleaned.isEmpty ? note : cleaned;
      return expense.copyWith(note: use).effectiveSummary(categoryName);
    } catch (_) {
      return expense.effectiveSummary(categoryName);
    }
  }
}
