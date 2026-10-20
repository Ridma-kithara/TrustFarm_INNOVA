import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api.dart';
import 'core/app_scope.dart';
import 'core/app_state.dart';
import 'core/design.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: TfColors.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TrustFarmApp());
}

class TrustFarmApp extends StatefulWidget {
  const TrustFarmApp({super.key});

  @override
  State<TrustFarmApp> createState() => _TrustFarmAppState();
}

class _TrustFarmAppState extends State<TrustFarmApp> {
  late final TrustFarmApi _api = TrustFarmApi();
  late final AppController _controller = AppController(api: _api);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'TrustFarm',
        debugShowCheckedModeBanner: false,
        theme: buildTrustFarmTheme(),
        scrollBehavior: const _AppScrollBehavior(),
        home: _RootGate(controller: _controller),
      ),
    );
  }
}

/// Keeps the splash on screen long enough to feel intentional, even when the
/// session restore and first refresh finish instantly.
class _RootGate extends StatefulWidget {
  const _RootGate({required this.controller});

  final AppController controller;

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _splashDone = false;
  bool _bootStarted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _boot();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  Future<void> _boot() async {
    if (_bootStarted) return;
    _bootStarted = true;
    await Future.wait<void>([
      widget.controller.boot(),
      Future<void>.delayed(const Duration(milliseconds: 2600)),
    ]);
    if (!mounted) return;
    setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.controller.phase;
    final showSplash = !_splashDone || phase == SessionPhase.booting;
    final Widget screen;
    if (showSplash) {
      screen = const SplashScreen(key: ValueKey('splash'));
    } else if (phase == SessionPhase.signedIn) {
      screen = const ShellScreen(key: ValueKey('shell'));
    } else {
      screen = const LoginScreen(key: ValueKey('login'));
    }

    return AnimatedSwitcher(
      duration: motionDuration(context, const Duration(milliseconds: 700)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: screen,
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
