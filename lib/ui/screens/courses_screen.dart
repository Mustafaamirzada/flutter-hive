import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/models.dart';
import '../../services/hive_store.dart';
import '../theme.dart';
import '../widgets/fx.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HiveStore();
    final text = Theme.of(context).textTheme;

    return ValueListenableBuilder<Box<NewCourse>>(
      valueListenable: store.courses.listenable(),
      builder: (context, box, _) {
        final courses = box.values.toList()
          ..sort((a, b) =>
              (a.startAt ?? DateTime(9999)).compareTo(b.startAt ?? DateTime(9999)));

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      'New\nCourses',
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
                      '${courses.length} upcoming · sorted by start date ·'
                      ' cached in Hive',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            if (courses.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  icon: Icons.auto_stories_rounded,
                  title: 'No courses yet',
                  subtitle: 'Refresh to pull data from /new_courses.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                sliver: SliverList.separated(
                  itemCount: courses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => Entrance(
                    order: index,
                    child: _CourseCard(
                      course: courses[index],
                      gradient:
                          index.isEven || courses.length < 2
                              ? AuroraPalette.heroGradient
                              : AuroraPalette.blushGradient,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.gradient});

  final NewCourse course;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final upcoming = course.startAt?.isAfter(DateTime.now()) ?? false;

    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(26)),
            child: Stack(
              children: [
                Container(
                  height: 128,
                  decoration: BoxDecoration(gradient: gradient),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 54,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      course.category,
                      style: text.labelSmall
                          ?.copyWith(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
                if (upcoming)
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0D1F).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: text.titleLarge
                      ?.copyWith(color: context.tone.text, fontSize: 19),
                ),
                const SizedBox(height: 6),
                Text(
                  course.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _pill(
                      context,
                      icon: Icons.event_available_rounded,
                      label: 'Starts ${formatDate(course.startAt)}',
                    ),
                    const Spacer(),
                    Text(
                      'No. ${course.id}',
                      style: text.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context,
      {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AuroraPalette.violet.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: AuroraPalette.violet.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AuroraPalette.cyan),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.tone.text,
                ),
          ),
        ],
      ),
    );
  }
}
