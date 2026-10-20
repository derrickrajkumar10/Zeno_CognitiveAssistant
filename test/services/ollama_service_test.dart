import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/services/ollama_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  OllamaService service(MockClientHandler handler) => OllamaService(
        baseUrl: 'http://192.168.1.5:11434',
        client: MockClient(handler),
      );

  test('ping is LIVE when the host lists its models', () async {
    Uri? asked;
    final live = await service((request) async {
      asked = request.url;
      return http.Response('{"models": []}', 200);
    }).ping();
    expect(live, isTrue);
    expect(asked.toString(), 'http://192.168.1.5:11434/api/tags');
  });

  test('ping is MOCK on a server error or no connection', () async {
    expect(await service((_) async => http.Response('', 500)).ping(), isFalse);
    expect(
      await service((_) async => throw http.ClientException('refused')).ping(),
      isFalse,
    );
  });

  test('dialogue comes from the configured host when it answers', () async {
    bool? live;
    Uri? asked;
    final line = await service((request) async {
      asked = request.url;
      return http.Response(jsonEncode({'response': ' Hi from Mochi. '}), 200);
    }).getMochiDialogue(
      cogniPulseScore: 70,
      moodState: MochiMoodState.balanced,
      setOllamaStatus: (value) => live = value,
    );
    expect(line, 'Hi from Mochi.');
    expect(live, isTrue);
    expect(asked.toString(), 'http://192.168.1.5:11434/api/generate');
  });

  test('dialogue falls back to built-in lines when the host is unreachable',
      () async {
    bool? live;
    final line = await service((_) async => throw http.ClientException('refused'))
        .getMochiDialogue(
      cogniPulseScore: 70,
      moodState: MochiMoodState.balanced,
      setOllamaStatus: (value) => live = value,
    );
    expect(MockData.balancedDialogue, contains(line));
    expect(live, isFalse);
  });
}
