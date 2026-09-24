import 'dart:convert';

import 'package:flutter/foundation.dart';
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

/// Gemini cleanup for notes too long/messy for the plain template.
/// Key comes from `--dart-define=GEMINI_API_KEY=...` (never committed);
/// empty key means template-only. Any failure falls back to the input.
class GeminiLlmBackend implements LlmBackend {
  const GeminiLlmBackend({http.Client? client, String? apiKey})
      : _apiKey =
            apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        // ignore: prefer_initializing_formals
        _client = client;

  final http.Client? _client;
  final String _apiKey;

  @visibleForTesting
  static Uri requestUri(String key) => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-2.0-flash:generateContent?key=$key',
      );

  @override
  Future<String> cleanup(String note) async {
    if (_apiKey.isEmpty) return note;
    try {
      final client = _client ?? http.Client();
      final res = await client.post(
        requestUri(_apiKey),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Rewrite this expense note as a 6-word-max, lowercase, '
                      'plain expense label. Reply with ONLY the label, no quotes: $note',
                },
              ],
            },
          ],
        }),
      );
      if (res.statusCode != 200) return note;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = body['candidates'];
      if (candidates is! List || candidates.isEmpty) return note;
      final first = candidates.first;
      if (first is! Map) return note;
      final content = first['content'];
      if (content is! Map) return note;
      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) return note;
      final part = parts.first;
      if (part is! Map) return note;
      final text = part['text'];
      if (text is! String) return note;
      final cleaned = text.trim();
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
