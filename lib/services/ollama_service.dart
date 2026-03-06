import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/face_scan_context_builder.dart';
import 'package:zeno/services/game_context_builder.dart';

class OllamaService {
  static const String _baseUrl = 'http://localhost:11434';
  static const String _model = 'llama3.2';
  static const Duration _timeout = Duration(seconds: 3);

  final GameContextBuilder _gameContextBuilder;
  final FaceScanContextBuilder _faceScanContextBuilder;

  OllamaService({
    GameContextBuilder? gameContextBuilder,
    FaceScanContextBuilder? faceScanContextBuilder,
  })  : _gameContextBuilder = gameContextBuilder ?? GameContextBuilder(),
        _faceScanContextBuilder = faceScanContextBuilder ??
            const FaceScanContextBuilder(latestFaceScan: null);

  Future<String> getMochiDialogue({
    required int cogniPulseScore,
    required MochiMoodState moodState,
    required void Function(bool) setOllamaStatus,
    String userId = 'alex',
  }) async {
    try {
      final gameContext = await _gameContextBuilder.buildGameContext(userId: userId);
      final faceScanContext = _faceScanContextBuilder.buildFaceScanContext();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _model,
              'prompt': 'Say one short thing to the user right now.',
              'system':
                  '${MockData.mochiSystemPrompt(cogniPulseScore, moodState.label)}$gameContext$faceScanContext',
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
      // Silent fallback is intentional.
    }
    setOllamaStatus(false);
    return _fallbackDialogue(moodState);
  }

  String _fallbackDialogue(MochiMoodState moodState) {
    final lines = switch (moodState) {
      MochiMoodState.thriving => MockData.thrivingDialogue,
      MochiMoodState.balanced => MockData.balancedDialogue,
      MochiMoodState.drifting => MockData.driftingDialogue,
      MochiMoodState.struggling => MockData.strugglingDialogue,
    };
    final index = DateTime.now().millisecondsSinceEpoch % lines.length;
    return lines[index];
  }
}

final ollamaServiceProvider = Provider<OllamaService>((ref) {
  final latestFaceScan =
      ref.watch(appStateProvider.select((state) => state.latestFaceScan));
  return OllamaService(
    faceScanContextBuilder: FaceScanContextBuilder(
      latestFaceScan: latestFaceScan,
    ),
  );
});

final mochiDialogueProvider = StateProvider<String>((ref) {
  final mood = ref.watch(mochiMoodProvider);
  final lines = switch (mood) {
    MochiMoodState.thriving => MockData.thrivingDialogue,
    MochiMoodState.balanced => MockData.balancedDialogue,
    MochiMoodState.drifting => MockData.driftingDialogue,
    MochiMoodState.struggling => MockData.strugglingDialogue,
  };
  return lines.first;
});

final mochiLoadingProvider = StateProvider<bool>((ref) => false);
