import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/models.dart';
import '../../services/hive_store.dart';
import '../theme.dart';
import '../widgets/attendance_heatmap.dart';
import '../widgets/fx.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = HiveStore();

    return ValueListenableBuilder<Box<Score>>(
      valueListenable: store.scores.listenable(),
      builder: (context, box, _) {
        final all = box.values.toList()
          ..sort((a, b) => a.subject.compareTo(b.subject));
        final query = _query.trim().toLowerCase();
        final items = query.isEmpty
            ? all
            : all
                .where((s) =>
                    s.subject.toLowerCase().contains(query) ||
                    s.category.toLowerCase().contains(query))
                .toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      'Academic\nPerformance',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        height: 1.02,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${all.length} subjects · live from /scores · cached in Hive',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _AuroraSearchField(
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  icon: Icons.query_stats_rounded,
                  title: 'No scores match',
                  subtitle: 'Try another subject, or refresh to re-sync '
                      'the API cache.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => Entrance(
                    order: index,
                    child: _ScoreCard(score: items[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AuroraSearchField extends StatelessWidget {
  const _AuroraSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  static OutlineInputBorder _searchOutline(Color color, {bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: focused ? 1.4 : 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      cursorColor: AuroraPalette.cyan,
      decoration: InputDecoration(
        hintText: 'Search subjects or categories…',
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: context.tone.textDim,
        ),
        filled: true,
        fillColor: context.tone.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: _searchOutline(context.tone.fieldBorder),
        enabledBorder: _searchOutline(context.tone.fieldBorder),
        focusedBorder: _searchOutline(context.tone.fieldFocusBorder, focused: true),
      ),
    );
  }
}

class _ScoreCard extends StatefulWidget {
  const _ScoreCard({required this.score});

  final Score score;

  @override
  State<_ScoreCard> createState() => _ScoreCardState();
}

class _ScoreCardState extends State<_ScoreCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    final grade = gradeColor(score.subjectGrade, context);

    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 26,
      borderColor: _expanded
          ? grade.withValues(alpha: 0.45)
          : context.tone.panelBorder,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: grade.withValues(alpha: 0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    GradientGauge(
                      value: score.subjectAverage / 100,
                      size: 64,
                      stroke: 6.5,
                      child: Text(
                        score.subjectGrade.isEmpty
                            ? '—'
                            : score.subjectGrade,
                        style: TextStyle(
                          color: grade,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            score.subject,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: context.tone.text,
                                  fontSize: 17.5,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _miniChip(
                                  score.category, Icons.category_rounded),
                              _miniChip(
                                'GPA ${_fmt(score.subjectGpa)}',
                                Icons.workspace_premium_rounded,
                                accent: grade,
                              ),
                              if (score.homeworkCount > 0)
                                _miniChip(
                                  '${score.homeworkCompletedCount}/'
                                  '${score.homeworkCount} HW',
                                  Icons.assignment_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.tone.textDim,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: _buildDetail(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final score = widget.score;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (score.homeworkCount > 0) ...[
          ProgressHint(rate: score.homeworkCompletionRate),
          const SizedBox(height: 16),
        ],
        if (score.semesters.isNotEmpty) ..._semesterSection(context),
        if (score.attendance.isNotEmpty) _attendanceSection(context),
        if (score.homework.isNotEmpty) _homeworkSection(context),
        if (score.semesters.isEmpty &&
            score.attendance.isEmpty &&
            score.homework.isEmpty)
          const Text('No detailed records for this subject yet.'),
      ],
    );
  }

  List<Widget> _semesterSection(BuildContext context) {
    final score = widget.score;
    return [
      for (final semester in score.semesters) ...[
        _DetailPanel(
          title: semester['semester_name'] ?? 'Semester',
          icon: Icons.workspace_premium_rounded,
          trailing: GradeBadge(
            grade: semester['semester_grade'] ?? '—',
            size: 34,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Average: ${semester['semester_avg'] ?? '—'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              for (final row in asMapList(semester['scores']))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_drop_down_rounded,
                          size: 22, color: AuroraPalette.cyan),
                      Expanded(
                        child: Text(
                          '${row['chance'] ?? 'Chance'} · score ${row['score'] ?? '—'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        row['teacher'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _attendanceSection(BuildContext context) {
    final score = widget.score;
    return _DetailPanel(
      title: 'Attendance calendar',
      icon: Icons.event_available_rounded,
      child: AttendanceHeatmap(records: score.attendance),
    );
  }

  Widget _homeworkSection(BuildContext context) {
    final score = widget.score;
    final text = Theme.of(context).textTheme;
    final total = score.homeworkCount;
    final completed = score.homeworkCompletedCount;
    final remaining = total - completed;

    return _DetailPanel(
      title: 'Homework',
      icon: Icons.checklist_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientGauge(
                value: total == 0 ? 0 : completed / total,
                size: 46,
                stroke: 4.5,
                child: Text(
                  '${score.homeworkCompletionRate.toStringAsFixed(0)}%',
                  style: text.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed of $total completed',
                      style:
                          text.titleSmall?.copyWith(color: context.tone.text),
                    ),
                    Text(
                      remaining == 0
                          ? 'All caught up — great job!'
                          : '$remaining task${remaining == 1 ? '' : 's'} left · tap one to toggle',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final hw in score.homework)
            _HomeworkTile(
              id: (hw['id'] ?? -1) as int,
              note: (hw['note'] ?? '').toString(),
              completed: (hw['is_completed'] ?? false) == true,
              createdAt: (hw['created_at'] ?? '').toString(),
              scoreKey: score.key,
            ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, IconData icon, {Color? accent}) {
    final color = accent ?? context.tone.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (accent ?? Colors.white).withValues(
          alpha: accent == null ? 0.06 : 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: accent == null ? 0.15 : 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent == null
                      ? context.tone.textDim
                      : context.tone.text,
                ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) => value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.tile,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AuroraPalette.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  const _HomeworkTile({
    required this.id,
    required this.note,
    required this.completed,
    required this.createdAt,
    required this.scoreKey,
  });

  final int id;
  final String note;
  final bool completed;
  final String createdAt;
  final String scoreKey;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = context.tone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: completed
            ? AuroraPalette.emerald.withValues(alpha: 0.1)
            : tone.tile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? AuroraPalette.emerald.withValues(alpha: 0.45)
              : tone.tileBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          final store = HiveStore();
          unawaited(store.setHomeworkCompleted(scoreKey, id, !completed));
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: completed
                    ? AuroraPalette.emerald
                    : context.tone.textDim,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                note.isEmpty ? '(no note)' : note,
                style: text.bodyMedium?.copyWith(
                  color: completed
                      ? AuroraPalette.emerald.withValues(alpha: 0.85)
                      : context.tone.text,
                  fontWeight: FontWeight.w600,
                  decoration: completed ? TextDecoration.lineThrough : null,
                  decorationColor: AuroraPalette.emerald.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              createdAt,
              style: text.labelSmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
