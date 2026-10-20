import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/design.dart';
import '../threed/renderer.dart';
import '../threed/scene_view.dart';
import '../threed/scenes/farm_scene.dart';
import '../widgets/glass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error =
        await AppScope.read(context).signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TfColors.ink,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return Stack(
            fit: StackFit.expand,
            children: [
              CinematicScene(
                builder: buildFarmScene,
                telemetry: const SceneTelemetry(
                  soil: 46,
                  battSoc: 78,
                  genW: 74,
                  loadW: 19,
                  trustLevel: 'Green',
                  trustScore: 94,
                  energyMode: 'CHARGING',
                ),
                interactive: true,
                autoRotate: true,
                reducedMotion:
                    MediaQuery.maybeOf(context)?.disableAnimations ?? false,
                highQuality: true,
                showLabels: false,
                initialYaw: wide ? 0.42 : 0.1,
                initialPitch: 0.3,
                initialDistance: wide ? 18 : 20,
                semanticLabel:
                    '3D farm digital twin on the TrustFarm sign in screen',
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: wide
                        ? [
                            TfColors.ink.withValues(alpha: 0.72),
                            TfColors.ink.withValues(alpha: 0.35),
                            TfColors.ink.withValues(alpha: 0.86),
                          ]
                        : [
                            TfColors.ink.withValues(alpha: 0.28),
                            TfColors.ink.withValues(alpha: 0.7),
                            TfColors.ink.withValues(alpha: 0.94),
                          ],
                    stops: wide ? const [0, 0.52, 1] : const [0, 0.45, 0.85],
                  ),
                ),
              ),
              SafeArea(
                child: wide ? _buildWide(context) : _buildNarrow(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 36),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: _BrandColumn(
                    onServerCheck: () => AppScope.read(context).api.health()),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 4,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: SingleChildScrollView(
                      child: _LoginCard(
                        email: _email,
                        password: _password,
                        passwordFocus: _passwordFocus,
                        obscure: _obscure,
                        submitting: _submitting,
                        error: _error,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmit: _submit,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandMark(),
            const SizedBox(height: 26),
            Text(
              'The field,\nintelligently\nunderstood.',
              style: TfType.display(34).copyWith(height: 1.02),
            ),
            const SizedBox(height: 12),
            Text(
              'Live trust, irrigation intelligence and farm energy — in one place.',
              style: TfType.body(13, color: TfColors.textDim),
            ),
            const SizedBox(height: 30),
            _LoginCard(
              email: _email,
              password: _password,
              passwordFocus: _passwordFocus,
              obscure: _obscure,
              submitting: _submitting,
              error: _error,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
              compact: true,
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                'ICBT INNOVA 2026 · TRUST BEFORE ADVICE',
                style: TfType.label(size: 8, color: TfColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({required this.onServerCheck});

  final Future<bool> Function() onServerCheck;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const SizedBox(height: 26),
          const Kicker('Sense · Verify · Predict · Advise'),
          const SizedBox(height: 18),
          SizedBox(
            width: 560,
            child: Text(
              'Trusted water.\nPowered by the farm.',
              style: TfType.display(58)
                  .copyWith(height: 0.98, letterSpacing: -2.2),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 470,
            child: Text(
              'TrustFarm verifies every sensor reading before the AI recommends irrigation, '
              'then powers the decision with on-farm waste-to-energy.',
              style: TfType.body(15, color: TfColors.textDim)
                  .copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 34),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureChip(
                  icon: Icons.shield_outlined, label: 'Trust-gated advice'),
              _FeatureChip(
                  icon: Icons.water_drop_outlined,
                  label: 'Irrigation forecast'),
              _FeatureChip(icon: Icons.bolt_rounded, label: 'Farm energy'),
              _FeatureChip(
                  icon: Icons.cloud_off_outlined, label: 'Offline state'),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 34,
            runSpacing: 18,
            children: const [
              _MiniMetric(value: '2', label: 'soil probes / zone'),
              _MiniMetric(value: '24h', label: 'sensor history'),
              _MiniMetric(value: 'G·A·R', label: 'trust levels'),
            ],
          ),
          const SizedBox(height: 28),
          _ServerStatus(check: onServerCheck),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF60F0B2), Color(0xFF1AAE77)],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                  color: TfColors.mint.withValues(alpha: 0.3), blurRadius: 22)
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: TfColors.ink, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TrustFarm',
                style: TfType.title(20).copyWith(letterSpacing: -0.5)),
            Text('SMARTCROP AI',
                style: TfType.label(size: 7.5, color: TfColors.mint)),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(color: TfColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TfColors.mint),
          const SizedBox(width: 7),
          Text(label, style: TfType.body(11.5, color: TfColors.textDim)),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TfType.mono(22, color: TfColors.text)),
        const SizedBox(height: 3),
        Text(label, style: TfType.body(10, color: TfColors.textMuted)),
      ],
    );
  }
}

class _ServerStatus extends StatelessWidget {
  const _ServerStatus({required this.check});

  final Future<bool> Function() check;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: check(),
      builder: (context, snapshot) {
        final checking = snapshot.connectionState == ConnectionState.waiting;
        final online = snapshot.data == true;
        final color = checking
            ? TfColors.textMuted
            : online
                ? TfColors.green
                : TfColors.amber;
        final label = checking
            ? 'Checking farm server'
            : online
                ? 'Farm server connected'
                : 'Farm server unreachable';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: TfType.body(10.5, color: TfColors.textMuted)),
          ],
        );
      },
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.email,
    required this.password,
    required this.passwordFocus,
    required this.obscure,
    required this.submitting,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
    this.compact = false,
  });

  final TextEditingController email;
  final TextEditingController password;
  final FocusNode passwordFocus;
  final bool obscure;
  final bool submitting;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(compact ? TfRadius.lg : TfRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xF20B1918),
            const Color(0xE6081312),
          ],
        ),
        border: Border.all(color: TfColors.lineStrong),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 60, offset: Offset(0, 28)),
          BoxShadow(
              color: Color(0x1441DF93), blurRadius: 1, offset: Offset(0, -1)),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(compact ? TfRadius.lg : TfRadius.xl),
        child: Padding(
          padding: EdgeInsets.all(compact ? 22 : 32),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: TfColors.mint.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: TfColors.mint.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          size: 15, color: TfColors.mint),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(TfRadius.pill),
                        border: Border.all(color: TfColors.line),
                      ),
                      child: Text('SECURE SESSION',
                          style: TfType.label(size: 7.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Welcome back', style: TfType.headline(compact ? 26 : 29)),
                const SizedBox(height: 7),
                Text(
                  'Sign in to check today’s field trust and irrigation advice.',
                  style: TfType.body(12.5, color: TfColors.textMuted)
                      .copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                if (error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(
                      color: TfColors.red.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(TfRadius.sm),
                      border: Border.all(
                          color: TfColors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: TfColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(error!,
                              style: TfType.body(11.5, color: TfColors.red)
                                  .copyWith(height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _FieldLabel('EMAIL'),
                const SizedBox(height: 7),
                TextField(
                  controller: email,
                  enabled: !submitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email
                  ],
                  autocorrect: false,
                  onSubmitted: (_) => passwordFocus.requestFocus(),
                  style: TfType.body(14, color: TfColors.text),
                  decoration: const InputDecoration(
                    hintText: 'you@farm.lk',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel('PASSWORD'),
                const SizedBox(height: 7),
                TextField(
                  controller: password,
                  focusNode: passwordFocus,
                  enabled: !submitting,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => onSubmit(),
                  style: TfType.body(14, color: TfColors.text),
                  decoration: InputDecoration(
                    hintText: 'Your password',
                    prefixIcon: const Icon(Icons.key_outlined, size: 18),
                    suffixIcon: IconButton(
                      tooltip: obscure ? 'Show password' : 'Hide password',
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: TfColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TfButton(
                  label: 'Enter the farm',
                  icon: submitting ? null : Icons.arrow_forward_rounded,
                  busy: submitting,
                  expand: true,
                  onPressed: submitting ? null : onSubmit,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.security_rounded,
                        size: 12, color: TfColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Encrypted token · last-known state available offline',
                        style: TfType.body(9.5, color: TfColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Need access? Ask your farm administrator to create an account.',
                  style: TfType.body(10,
                      color: TfColors.textMuted.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TfType.label(size: 8.5, color: TfColors.textMuted));
  }
}
