import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/ollama_settings.dart';

void main() {
  group('normalizeOllamaHost', () {
    test('adds http:// when the scheme is missing', () {
      expect(normalizeOllamaHost('192.168.1.5:11434'), 'http://192.168.1.5:11434');
    });

    test('trims spaces and a trailing slash', () {
      expect(normalizeOllamaHost('  http://10.0.2.2:11434/ '), 'http://10.0.2.2:11434');
    });

    test('keeps https', () {
      expect(normalizeOllamaHost('https://mochi.local'), 'https://mochi.local');
    });

    test('rejects a blank host', () {
      expect(() => normalizeOllamaHost('   '), throwsFormatException);
    });
  });

  test('the Android emulator reaches the computer at 10.0.2.2', () {
    expect(defaultOllamaHost(isAndroid: true), 'http://10.0.2.2:11434');
    expect(defaultOllamaHost(isAndroid: false), 'http://localhost:11434');
  });

  test('a saved host survives a restart and reset returns to the default',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = OllamaHostNotifier(prefs, isAndroid: true);
    expect(first.state, 'http://10.0.2.2:11434');

    await first.set('192.168.1.5:11434');
    expect(OllamaHostNotifier(prefs, isAndroid: true).state, 'http://192.168.1.5:11434');

    await first.reset();
    expect(first.state, 'http://10.0.2.2:11434');
    expect(prefs.getString(OllamaHostNotifier.prefsKey), isNull);
  });

  test('Reset all data keeps the host setting', () {
    expect(AppStateNotifier.preservedOnReset, contains(OllamaHostNotifier.prefsKey));
  });
}
