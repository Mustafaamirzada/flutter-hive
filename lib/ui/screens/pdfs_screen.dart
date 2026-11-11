import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/models.dart';
import '../../services/hive_store.dart';
import '../theme.dart';
import '../widgets/fx.dart';

class PdfsScreen extends StatelessWidget {
  const PdfsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HiveStore();
    final text = Theme.of(context).textTheme;

    return ValueListenableBuilder<Box<CoursePdf>>(
      valueListenable: store.pdfs.listenable(),
      builder: (context, box, _) {
        final pdfs = box.values.toList()
          ..sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      'Shared\nDocuments',
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
                      '${pdfs.length} PDF files · cached from /pdfs',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            if (pdfs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  icon: Icons.folder_off_rounded,
                  title: 'No PDFs yet',
                  subtitle: 'Refresh to pull documents from the API.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                sliver: SliverList.separated(
                  itemCount: pdfs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => Entrance(
                    order: index,
                    child: _PdfTile(pdf: pdfs[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PdfTile extends StatelessWidget {
  const _PdfTile({required this.pdf});

  final CoursePdf pdf;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AuroraPalette.blushGradient,
                boxShadow: [
                  BoxShadow(
                    color: AuroraPalette.pink.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      color: context.tone.text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.book_outlined,
                          size: 14, color: AuroraPalette.cyan),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          pdf.course,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: AuroraPalette.cyan),
                      const SizedBox(width: 4),
                      Text(
                        pdf.teacher,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _chip(context, pdf.category, Icons.category_rounded),
                      _chip(context, pdf.time, Icons.schedule_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              color: context.tone.menuColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: context.tone.panelBorder,
                ),
              ),
              onSelected: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${pdf.filePath} ($value)…')),
                );
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'view',
                  child: _MenuItem(icon: Icons.visibility_rounded, label: 'View'),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: _MenuItem(icon: Icons.share_rounded, label: 'Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon) {
    final tone = context.tone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.chipBase.withValues(alpha: tone.isDark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AuroraPalette.pink),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: context.tone.textDim),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AuroraPalette.cyan),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.tone.text),
        ),
      ],
    );
  }
}
