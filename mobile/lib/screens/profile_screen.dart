import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../core/app_state.dart';
import '../core/design.dart';
import '../core/formatters.dart';
import '../widgets/glass.dart';
import '../widgets/layout.dart';
import '../widgets/sheets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<int>? _cacheFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cacheFuture ??= AppScope.read(context).api.cachedResponseCount();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.user;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 980;

    final account = _AccountCard(controller: controller);
    final preferences = _PreferencesCard(controller: controller);
    final data = _DataCard(
      controller: controller,
      cacheFuture: _cacheFuture!,
      onCleared: () =>
          setState(() => _cacheFuture = controller.api.cachedResponseCount()),
    );
    final session = _SessionCard(controller: controller);
    final about = _AboutCard(controller: controller);

    return PagePadding(
      maxWidth: 1240,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: pageBottomInset(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Profile & settings',
              subtitle:
                  '${user?.role ?? 'farmer'} · ${user?.email ?? 'session'}',
              showTrust: false,
            ),
            const SizedBox(height: 16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        account,
                        const SizedBox(height: 14),
                        data,
                        const SizedBox(height: 14),
                        about,
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        preferences,
                        const SizedBox(height: 14),
                        session,
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              account,
              const SizedBox(height: 14),
              preferences,
              const SizedBox(height: 14),
              data,
              const SizedBox(height: 14),
              session,
              const SizedBox(height: 14),
              about,
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final role = user?.role ?? 'farmer';
    final roleColor = switch (role.toLowerCase()) {
      'admin' => TfColors.gold,
      'officer' => TfColors.cyan,
      _ => TfColors.mint,
    };
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143229), Color(0xFF0A1717)],
        ),
        borderRadius: BorderRadius.circular(TfRadius.xl),
        border: Border.all(color: TfColors.lineStrong),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 36, offset: Offset(0, 18))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D5B49), Color(0xFF17342B)],
                  ),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: TfColors.mint.withValues(alpha: 0.32)),
                  boxShadow: [
                    BoxShadow(
                        color: TfColors.mint.withValues(alpha: 0.15),
                        blurRadius: 24)
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.initials ?? 'TF',
                    style: TfType.display(21, color: TfColors.mint),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'TrustFarm user',
                      style: TfType.headline(23),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? 'No active email',
                      style: TfType.body(11.5, color: TfColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                  label: role.toUpperCase(),
                  color: roleColor,
                  icon: Icons.badge_outlined),
              _Tag(
                label: user?.farmId == null
                    ? 'FARM VIEW'
                    : 'FARM #${user!.farmId}',
                color: TfColors.cyan,
                icon: Icons.landscape_outlined,
              ),
              _Tag(
                  label: 'SECURE SESSION',
                  color: TfColors.mint,
                  icon: Icons.lock_outline_rounded),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: TfColors.line),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(
                controller.offline
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_outlined,
                size: 14,
                color: controller.offline ? TfColors.amber : TfColors.green,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  controller.offline
                      ? 'Offline · last known state from ${timeAgo(controller.cachedAt)}'
                      : 'Connected · live data from the farm server',
                  style: TfType.body(10.5, color: TfColors.textMuted),
                ),
              ),
              Text(
                formatClock(controller.lastUpdated),
                style: TfType.mono(10.5, color: TfColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(label, style: TfType.label(size: 7.2, color: color)),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      kicker: 'EXPERIENCE',
      title: 'Preferences',
      subtitle: 'Tune motion, rendering and polling',
      children: [
        _ToggleRow(
          icon: Icons.motion_photos_on_outlined,
          title: 'Auto-rotate the twin',
          body: 'Slow cinematic orbit when the scene is idle.',
          value: controller.autoRotate,
          onChanged: controller.setAutoRotate,
        ),
        _ToggleRow(
          icon: Icons.accessibility_new_rounded,
          title: 'Reduce motion',
          body: 'Pauses camera motion and trims transitions.',
          value: controller.reducedMotion,
          onChanged: controller.setReducedMotion,
        ),
        _ToggleRow(
          icon: Icons.hd_outlined,
          title: 'High-quality 3D',
          body: 'More geometry and particles. Disable on older devices.',
          value: controller.highQuality,
          onChanged: controller.setHighQuality,
        ),
        _ValueRow(
          icon: Icons.sync_rounded,
          title: 'Auto refresh',
          body: 'How often live farm data is pulled.',
          trailing: PopupMenuButton<int>(
            tooltip: 'Choose refresh interval',
            initialValue: controller.refreshSeconds,
            onSelected: controller.setRefreshSeconds,
            color: TfColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TfRadius.md),
              side: const BorderSide(color: TfColors.lineStrong),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 10, child: Text('Every 10 seconds')),
              PopupMenuItem(value: 20, child: Text('Every 20 seconds')),
              PopupMenuItem(value: 60, child: Text('Every 60 seconds')),
              PopupMenuItem(value: 0, child: Text('Manual only')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(TfRadius.pill),
                border: Border.all(color: TfColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.refreshSeconds <= 0
                        ? 'Manual'
                        : '${controller.refreshSeconds}s',
                    style: TfType.mono(10.5, color: TfColors.mint),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: TfColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.controller,
    required this.cacheFuture,
    required this.onCleared,
  });

  final AppController controller;
  final Future<int> cacheFuture;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      kicker: 'DATA',
      title: 'Offline cache & server',
      subtitle: 'Last-known state is stored on this device',
      children: [
        _ValueRow(
          icon: Icons.dns_outlined,
          title: 'Farm API',
          body: controller.api.baseUrl,
          trailing: IconButton(
            tooltip: 'Copy server URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: controller.api.baseUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Server URL copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded,
                size: 15, color: TfColors.textMuted),
          ),
        ),
        _ValueRow(
          icon: Icons.inventory_2_outlined,
          title: 'Cached responses',
          body: 'Readings, zones, trust history and alerts for offline use.',
          trailing: FutureBuilder<int>(
            future: cacheFuture,
            builder: (context, snapshot) => Text(
              snapshot.hasData ? '${snapshot.data}' : '—',
              style: TfType.mono(12, color: TfColors.cyan),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Clearing removes offline access until the next successful refresh. '
                  'It never deletes farm data on the server.',
                  style: TfType.body(10, color: TfColors.textMuted)
                      .copyWith(height: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final confirmed = await _confirm(
                    context,
                    title: 'Clear offline cache?',
                    message:
                        'You will need a connection to load fresh farm data afterwards.',
                    confirmLabel: 'Clear cache',
                  );
                  if (!confirmed) return;
                  await controller.clearCache();
                  if (!context.mounted) return;
                  onCleared();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offline cache cleared')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: TfColors.amber,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      kicker: 'SECURITY',
      title: 'Session',
      subtitle: 'Credentials and sign out',
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: TfColors.mint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TfColors.mint.withValues(alpha: 0.2)),
              ),
              child:
                  const Icon(Icons.key_rounded, size: 15, color: TfColors.mint),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'A bearer token is kept in secure storage on this device and attached to every '
                'Farm API request. Signing out clears the token, identity and cached responses.',
                style: TfType.body(10.5, color: TfColors.textMuted)
                    .copyWith(height: 1.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _DangerButton(
            label: 'Sign out of TrustFarm',
            icon: Icons.logout_rounded,
            onPressed: () async {
              final confirmed = await _confirm(
                context,
                title: 'Sign out?',
                message:
                    'Your secure session and offline cache will be removed from this device.',
                confirmLabel: 'Sign out',
              );
              if (!confirmed) return;
              await controller.signOut();
            },
          ),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      kicker: 'PROJECT',
      title: 'About TrustFarm',
      subtitle: 'ICBT INNOVA 2026 · Silent Force',
      children: [
        Text(
          'Trusted AI irrigation and farm energy for smallholder farms. Trust-gated advice, '
          'a living 3D twin and an offline-first mobile experience.',
          style:
              TfType.body(11, color: TfColors.textMuted).copyWith(height: 1.55),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: const [
            _Tag(
                label: 'SDG 2',
                color: TfColors.green,
                icon: Icons.agriculture_outlined),
            _Tag(
                label: 'SDG 6',
                color: TfColors.cyan,
                icon: Icons.water_drop_outlined),
            _Tag(
                label: 'SDG 13',
                color: TfColors.gold,
                icon: Icons.public_rounded),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text('Version 1.0.0 · Flutter',
                  style: TfType.body(10, color: TfColors.textMuted)),
            ),
            TextButton(
              onPressed: () => showAboutSheet(context),
              style: TextButton.styleFrom(
                foregroundColor: TfColors.mint,
                minimumSize: const Size(0, 32),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Project & limits',
                  style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(kicker: kicker, title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: TfColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TfType.body(12.5,
                        color: TfColors.text, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body,
                    style: TfType.body(10, color: TfColors.textMuted)
                        .copyWith(height: 1.45)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: TfColors.ink,
            activeTrackColor: TfColors.mint,
            inactiveThumbColor: TfColors.textMuted,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TfType.body(12.5,
                        color: TfColors.text, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TfType.body(10, color: TfColors.textMuted)
                      .copyWith(height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: TfColors.line),
      ),
      child: Icon(icon, size: 15, color: TfColors.textDim),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton(
      {required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(TfRadius.pill),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: TfColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(TfRadius.pill),
          border: Border.all(color: TfColors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: TfColors.red),
            const SizedBox(width: 8),
            Text(
              label,
              style: TfType.body(12.5,
                  color: TfColors.red, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF10201E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TfRadius.lg),
        side: const BorderSide(color: TfColors.lineStrong),
      ),
      title: Text(title, style: TfType.headline(20)),
      content: Text(message,
          style: TfType.body(12.5, color: TfColors.textMuted)
              .copyWith(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: TfColors.textMuted),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: TfColors.red),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
