import 'package:flutter/material.dart';

class AuroraPalette {
  static const Color canvasDark = Color(0xFF0B0D1F);
  static const Color canvasLight = Color(0xFFF1F2FD);

  // Brand accents - identical in both themes.
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color pink = Color(0xFFF472B6);
  static const Color emerald = Color(0xFF34D399);
  static const Color amber = Color(0xFFFBBF24);
  static const Color rose = Color(0xFFFB7185);

  static const List<Color> auroraGradient = [violet, cyan];

  /// Midnight banner for course cards / pdf tiles (same in both themes).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, cyan],
  );
  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6FB5), Color(0xFFFFC46B)],
  );
}

/// Chrome colors resolved per brightness - use `context.tone.*` everywhere in
/// widgets so components adapt automatically.
class Tone {
  const Tone({
    required this.canvas,
    required this.text,
    required this.textDim,
    required this.textGradient,
    required this.panel,
    required this.panelBorder,
    required this.tile,
    required this.tileBorder,
    required this.chipBase,
    required this.chipBorder,
    required this.fieldFill,
    required this.fieldBorder,
    required this.fieldFocusBorder,
    required this.navFill,
    required this.navBorder,
    required this.gaugeTrack,
    required this.emptyDay,
    required this.menuColor,
    required this.snackColor,
    required this.shadowColor,
    required this.blobAlpha,
    this.snackText,
    this.isDark = false,
  });

  final Color canvas;
  final Color text;
  final Color textDim;
  final Gradient textGradient;
  final Color panel;
  final Color panelBorder;
  final Color tile;
  final Color tileBorder;
  final Color chipBase;
  final Color chipBorder;
  final Color fieldFill;
  final Color fieldBorder;
  final Color fieldFocusBorder;
  final Color navFill;
  final Color navBorder;
  final Color gaugeTrack;
  final Color emptyDay;
  final Color menuColor;
  final Color snackColor;
  final Color? snackText;
  final Color shadowColor;
  final double blobAlpha;
  final bool isDark;

  static const Tone _dark = Tone(
    canvas: AuroraPalette.canvasDark,
    text: Color(0xFFECEBFF),
    textDim: Color(0xFF9BA3CE),
    textGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
    ),
    panel: Color(0x0DFFFFFF), // white ~5%
    panelBorder: Color(0x1AFFFFFF), // white ~10%
    tile: Color(0x0AFFFFFF), // white ~4%
    tileBorder: Color(0x14FFFFFF), // white ~8%
    chipBase: Color(0xFFFFFFFF),
    chipBorder: Color(0x26FFFFFF),
    fieldFill: Color(0x0DFFFFFF),
    fieldBorder: Color(0x1AFFFFFF),
    fieldFocusBorder: AuroraPalette.violet,
    navFill: Color(0xDE151735), // #151735 ~87%
    navBorder: Color(0x17FFFFFF),
    gaugeTrack: Color(0x14FFFFFF),
    emptyDay: Color(0xFF2A2D55),
    menuColor: Color(0xFF1B1E44),
    snackColor: Color(0xFF1B1E44),
    shadowColor: Color(0x73000000), // black ~45%
    blobAlpha: 1.0,
    isDark: true,
  );

  static const Tone _light = Tone(
    canvas: AuroraPalette.canvasLight,
    text: Color(0xFF191C3E),
    textDim: Color(0xFF545B7F),
    textGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7C3AED), Color(0xFF0891B2)],
    ),
    panel: Color(0xB8FFFFFF), // white ~72%
    panelBorder: Color(0x1A191C3E), // ink ~10%
    tile: Color(0x14191C3E), // ink ~8%
    tileBorder: Color(0x1F191C3E), // ink ~12%
    chipBase: Color(0xFF191C3E),
    chipBorder: Color(0x1F191C3E),
    fieldFill: Color(0xFFFFFFFF),
    fieldBorder: Color(0x29191C3E),
    fieldFocusBorder: Color(0xFF7C3AED),
    navFill: Color(0xE0FFFFFF),
    navBorder: Color(0x1F191C3E),
    gaugeTrack: Color(0x1F191C3E),
    emptyDay: Color(0xFFE4E6F7),
    menuColor: Color(0xFFFFFFFF),
    snackColor: Color(0xFFFFFFFF),
    snackText: Color(0xFF191C3E),
    shadowColor: Color(0x20191C3E), // ink ~12%
    blobAlpha: 0.45,
  );

  static Tone of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

extension ToneContext on BuildContext {
  Tone get tone => Tone.of(this);
}

Color gradeColor(String grade, BuildContext context) {
  final dark = Tone.of(context).isDark;
  switch (RegExp(r'[A-F]').firstMatch(grade)?.group(0) ?? grade) {
    case 'A':
      return dark ? AuroraPalette.emerald : const Color(0xFF059669);
    case 'B':
      return dark ? AuroraPalette.cyan : const Color(0xFF0891B2);
    case 'C':
      return dark ? AuroraPalette.amber : const Color(0xFFD97706);
    case 'D':
      return dark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
    case 'F':
      return dark ? AuroraPalette.rose : const Color(0xFFE11D48);
    default:
      return dark ? AuroraPalette.violet : const Color(0xFF7C3AED);
  }
}

class AuroraTheme {
  /// Builds the midnight-aurora (dark) or soft-aurora (light) theme.
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const violet = AuroraPalette.violet;
    final text = dark ? const Color(0xFFECEBFF) : const Color(0xFF191C3E);
    final textDim = dark ? const Color(0xFF9BA3CE) : const Color(0xFF545B7F);
    final canvas =
        dark ? AuroraPalette.canvasDark : AuroraPalette.canvasLight;
    final surface = dark ? const Color(0xFF121432) : const Color(0xFFFFFFFF);

    final scheme = ColorScheme.fromSeed(
      seedColor: violet,
      brightness: brightness,
    ).copyWith(
      surface: surface,
      primary: dark ? violet : const Color(0xFF7C3AED),
      secondary: dark ? AuroraPalette.cyan : const Color(0xFF0891B2),
      tertiary: AuroraPalette.pink,
    );

    TextStyle ft(Color color, double size, FontWeight weight,
            {double ls = 0, double lh = 1.35}) =>
        TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: ls,
          height: lh,
        );

    return baseTheme(brightness).copyWith(
      scaffoldBackgroundColor: canvas,
      colorScheme: scheme,
      canvasColor: canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: ft(text, 20, FontWeight.w700, ls: -0.2),
        iconTheme: IconThemeData(color: textDim),
      ),
      textTheme: TextTheme(
        displaySmall: ft(text, 32, FontWeight.w800, ls: -1.2, lh: 1.05),
        headlineSmall: ft(text, 24, FontWeight.w800, ls: -0.8),
        titleLarge: ft(text, 18, FontWeight.w700, ls: -0.3),
        titleMedium: ft(text, 16, FontWeight.w700, ls: -0.2),
        titleSmall: ft(text, 14, FontWeight.w700),
        bodyLarge:
            dark ? ft(text, 15, FontWeight.w400) : ft(text, 15, FontWeight.w500),
        bodyMedium: ft(textDim, 14, FontWeight.w400, lh: 1.35),
        bodySmall: ft(textDim, 12.5, FontWeight.w400, lh: 1.3),
        labelLarge: ft(text, 13, FontWeight.w700),
        labelMedium: ft(textDim, 12, FontWeight.w600),
        labelSmall: ft(textDim, 11, FontWeight.w600, ls: 0.2),
      ),
      dividerColor:
          dark ? Colors.white12 : const Color(0xFF191C3E).withValues(alpha: 0.12),
      iconTheme: IconThemeData(color: text),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF1B1E44) : Colors.white,
        contentTextStyle: ft(
          dark ? const Color(0xFFECEBFF) : const Color(0xFF191C3E),
          14,
          FontWeight.w500,
        ),
        actionTextColor: dark ? AuroraPalette.cyan : const Color(0xFF0891B2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFF191C3E).withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  static ThemeData baseTheme(Brightness brightness) =>
      brightness == Brightness.dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true);
}

String formatDate(DateTime? date) {
  if (date == null) return '—';
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// Glowing grade badge; works on both themes.
class GradeBadge extends StatelessWidget {
  const GradeBadge({super.key, required this.grade, this.size = 56});

  final String grade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final color = gradeColor(grade, context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: tone.isDark ? 0.30 : 0.18),
            color.withValues(alpha: tone.isDark ? 0.08 : 0.06),
          ],
        ),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: tone.isDark ? 0.35 : 0.28),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        grade.isEmpty ? '—' : grade,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Gradient progress bar used in score details.
class ProgressHint extends StatelessWidget {
  const ProgressHint({super.key, required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final clamped = rate.clamp(0, 100) / 100;
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: tone.gaugeTrack,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: tone.textGradient,
              boxShadow: [
                BoxShadow(
                  color: AuroraPalette.violet.withValues(
                      alpha: tone.isDark ? 0.45 : 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                context.tone.textGradient.createShader(bounds),
            child: Icon(icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
