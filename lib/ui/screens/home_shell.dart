import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../repository/data_repository.dart';
import '../../services/hive_store.dart';
import '../theme.dart';
import '../widgets/fx.dart';
import 'pdfs_screen.dart';
import 'scores_screen.dart';
import 'courses_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.repository,
    required this.lightMode,
    required this.onToggleTheme,
  });

  final DataRepository repository;
  final bool lightMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _syncing = false;

  static const _specs = [
    _Destination('Scores', 'Your academic pulse', Icons.insights_rounded),
    _Destination('Courses', 'What is launching soon',
        Icons.auto_stories_rounded),
    _Destination('Documents', 'Everything shared with you',
        Icons.picture_as_pdf_rounded),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() => _syncing = true);
    final result = await widget.repository.refreshAll();
    if (!mounted) return;
    setState(() => _syncing = false);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final text = switch (result.source) {
      DataSource.api =>
        'Synced from API · cached in Hive (${result.itemsCount} records)',
      DataSource.cache => 'Sync failed: ${result.error ?? 'unknown error'}',
    };
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Retry', onPressed: _refresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveStore();
    final screens = [
      ScoresScreen(key: const ValueKey('scores')),
      CoursesScreen(key: const ValueKey('courses')),
      PdfsScreen(key: const ValueKey('pdfs')),
    ];
    final counts = [hive.scores.length, hive.courses.length, hive.pdfs.length];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: _specs[_index].label,
                  subtitle: _specs[_index].subtitle,
                  syncing: _syncing,
                  onRefresh: _refresh,
                  lightMode: widget.lightMode,
                  onToggleTheme: widget.onToggleTheme,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _AuroraNav(
        index: _index,
        counts: counts,
        icons: [for (final s in _specs) s.icon],
        labels: [for (final s in _specs) s.label],
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.syncing,
    required this.onRefresh,
    required this.lightMode,
    required this.onToggleTheme,
  });

  final String title;
  final String subtitle;
  final bool syncing;
  final VoidCallback onRefresh;
  final bool lightMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(
                  title,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _GlassIconButton(
            onTap: onToggleTheme,
            child: Icon(
              lightMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: context.tone.text,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          _GlassIconButton(
            onTap: syncing ? () {} : onRefresh,
            child: syncing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AuroraPalette.cyan,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    color: context.tone.text,
                    size: 22,
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.tone.panel,
          shape: BoxShape.circle,
          border: Border.all(color: context.tone.panelBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _AuroraNav extends StatelessWidget {
  const _AuroraNav({
    required this.index,
    required this.counts,
    required this.icons,
    required this.labels,
    required this.onSelected,
  });

  final int index;
  final List<int> counts;
  final List<IconData> icons;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: context.tone.navFill,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: context.tone.navBorder),
              boxShadow: [
                BoxShadow(
                  color: context.tone.shadowColor.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < icons.length; i++)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => onSelected(i),
                        child: Center(
                          child: _NavItem(
                            selected: index == i,
                            icon: icons[i],
                            label: labels[i],
                            count: counts[i],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.count,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1.0 : 0.0, begin: selected ? 0.0 : 1.0),
      curve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 380),
      builder: (context, t, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8 + 10 * t, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: t <= 0.01
                ? null
                : LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Color.lerp(
                          AuroraPalette.violet.withValues(alpha: 0.0),
                          AuroraPalette.violet,
                          t)!,
                      Color.lerp(
                          AuroraPalette.cyan.withValues(alpha: 0.0),
                          AuroraPalette.cyan,
                          t)!,
                    ],
                  ),
            boxShadow: t <= 0.02
                ? const []
                : [
                    BoxShadow(
                      color: AuroraPalette.violet.withValues(alpha: 0.35 * t),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: count > 0,
                label: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  icon,
                  size: 23 + 2 * t,
                  color: t > 0.5 ? Colors.white : context.tone.textDim,
                ),
              ),
              SizedBox(
                width: label.length * 8.4 * t,
                child: Opacity(
                  opacity: ((t - 0.45) / 0.55).clamp(0.0, 1.0),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
}
