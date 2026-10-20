import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trustfarm_mobile/main.dart' as app;

/// End-to-end smoke test against the live local stack:
///   docker compose up -d   (db, mqtt, ai_service, backend, web)
/// Run with the backend API reachable from the device:
///   flutter test integration_test/app_test.dart -d <device> \
///     --dart-define=API_URL=http://localhost:8000   # iOS/web
///     --dart-define=API_URL=http://10.0.2.2:8000    # Android emulator
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signs in against the live backend and reaches the dashboard',
      (tester) async {
    const email = String.fromEnvironment('E2E_EMAIL',
        defaultValue: 'ridmakithara19@gmail.com');
    const password =
        String.fromEnvironment('E2E_PASSWORD', defaultValue: 'admin123');

    app.main();

    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 800));

    if (find.text('Enter the farm').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.pump();
      await tester.tap(find.text('Enter the farm'));
    }

    var reachedShell = false;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('Overview').evaluate().isNotEmpty) {
        reachedShell = true;
        break;
      }
      if (find.textContaining('Could not').evaluate().isNotEmpty ||
          find.textContaining('check your credentials').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(reachedShell, isTrue,
        reason: 'Expected the dashboard after signing in with $email. '
            'Is the backend running on the API_URL passed to this test?');
  });
}
