import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';

class OllamaService {
  static const String _baseUrl = 'http://localhost:11434';
  static const String _model = 'llama3.2';
  static const Duration _timeout = Duration(seconds: 3);

  /// Returns a Mochi dialogue line. Falls back to mock on any error.
  Future<String> getMochiDialogue({
    required int cogniPulseScore,
    required MochiMoodState moodState,
    required void Function(bool) setOllamaStatus,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'prompt': 'Say one short thing to the user right now.',
              'system': MockData.mochiSystemPrompt(cogniPulseScore, moodState.label),
              'stream': false,
              'options': {'num_predict': 60, 'temperature': 0.9},
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['response'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          setOllamaStatus(true);
          return text;
        }
      }
    } catch (_) {
      // Silent fallback — intentional
    }
    setOllamaStatus(false);
    return _getFallbackDialogue(moodState);
  }

  String _getFallbackDialogue(MochiMoodState moodState) {
    final lines = switch (moodState) {
      MochiMoodState.thriving   => MockData.thrivingDialogue,
      MochiMoodState.balanced   => MockData.balancedDialogue,
      MochiMoodState.drifting   => MockData.driftingDialogue,
      MochiMoodState.struggling => MockData.strugglingDialogue,
    };
    final index = DateTime.now().millisecondsSinceEpoch % lines.length;
    return lines[index];
  }
}

final ollamaServiceProvider = Provider<OllamaService>((ref) => OllamaService());

// Current dialogue line state
final mochiDialogueProvider = StateProvider<String>((ref) {
  final mood = ref.watch(mochiMoodProvider);
  return _getInitialDialogue(mood);
});

String _getInitialDialogue(MochiMoodState mood) {
  final lines = switch (mood) {
    MochiMoodState.thriving   => MockData.thrivingDialogue,
    MochiMoodState.balanced   => MockData.balancedDialogue,
    MochiMoodState.drifting   => MockData.driftingDialogue,
    MochiMoodState.struggling => MockData.strugglingDialogue,
  };
  return lines[0];
}

// Loading state for Ollama fetch
final mochiLoadingProvider = StateProvider<bool>((ref) => false);
