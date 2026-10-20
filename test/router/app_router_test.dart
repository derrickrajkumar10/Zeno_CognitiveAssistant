import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completing onboarding keeps the same router instance', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final before = container.read(routerProvider);
    container.read(appStateProvider.notifier).completeOnboarding();
    final after = container.read(routerProvider);

    // A new GoRouter would restart navigation at /splash and replay it.
    expect(identical(before, after), isTrue);
  });
}
