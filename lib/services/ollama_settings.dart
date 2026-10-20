import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';

/// Where Mochi looks for a local Ollama server. The Android emulator reaches
/// the host computer at 10.0.2.2; a real phone needs the computer's LAN
/// address, set from the developer panel.
String defaultOllamaHost({required bool isAndroid}) =>
    isAndroid ? 'http://10.0.2.2:11434' : 'http://localhost:11434';

/// Accepts what people type ("192.168.1.5:11434", "http://host/") and
/// returns a base URL without a trailing slash.
String normalizeOllamaHost(String input) {
  var host = input.trim();
  if (host.isEmpty) {
    throw const FormatException('Enter a host such as 192.168.1.5:11434');
  }
  if (!host.contains('://')) {
    host = 'http://$host';
  }
  while (host.endsWith('/')) {
    host = host.substring(0, host.length - 1);
  }
  return host;
}

class OllamaHostNotifier extends StateNotifier<String> {
  static const prefsKey = 'zeno.ollama_host';

  final SharedPreferences _prefs;
  final bool _isAndroid;

  OllamaHostNotifier(this._prefs, {required bool isAndroid})
      : _isAndroid = isAndroid,
        super(_prefs.getString(prefsKey) ?? defaultOllamaHost(isAndroid: isAndroid));

  /// Throws [FormatException] for a blank host.
  Future<void> set(String input) async {
    final host = normalizeOllamaHost(input);
    state = host;
    await _prefs.setString(prefsKey, host);
  }

  Future<void> reset() async {
    state = defaultOllamaHost(isAndroid: _isAndroid);
    await _prefs.remove(prefsKey);
  }
}

final ollamaHostProvider =
    StateNotifierProvider<OllamaHostNotifier, String>((ref) {
  return OllamaHostNotifier(
    ref.watch(sharedPreferencesProvider),
    isAndroid: defaultTargetPlatform == TargetPlatform.android,
  );
});
