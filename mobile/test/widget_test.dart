import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustfarm_mobile/core/api.dart';
import 'package:trustfarm_mobile/core/app_state.dart';
import 'package:trustfarm_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('app opens on the animated splash and reaches sign in',
      (tester) async {
    await tester.pumpWidget(const TrustFarmApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TrustFarm'), findsWidgets);
    expect(find.text('Trust before advice.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Enter the farm'), findsOneWidget);
  });

  test('sign in validation runs before any network call', () async {
    final controller =
        AppController(api: TrustFarmApi(baseUrl: 'http://127.0.0.1:1'));
    expect(await controller.signIn('', ''), 'Enter your email address.');
    expect(await controller.signIn('not-an-email', 'secret'),
        'Enter a valid email address.');
    expect(
        await controller.signIn('farmer@farm.lk', ''), 'Enter your password.');
    controller.dispose();
  });
}
