import 'package:flutter/material.dart';

const stitchCanvas = Color(0xFF131316);
const stitchSidebar = Color(0xFF0E0E11);
const stitchSurface = Color(0xFF1B1B1E);
const stitchSurfaceLow = Color(0xFF1F1F22);
const stitchSurfaceHigh = Color(0xFF2A2A2D);
const stitchSurfaceHighest = Color(0xFF353438);
const stitchText = Color(0xFFE4E1E6);
const stitchMuted = Color(0xFFE2BFB2);
const stitchPrimary = Color(0xFFFFB599);
const stitchOnPrimary = Color(0xFF5A1C00);
const stitchOnPrimaryContainer = Color(0xFF4F1700);
const stitchBlue = Color(0xFF4D8EFF);
const stitchOutline = Color(0xFF5A4138);
const stitchOrange = Color(0xFFF66018);
const stitchPeach = Color(0xFFFFB599);
const stitchGreen = Color(0xFF4AE176);

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gradient;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: stitchSurface,
      gradient: gradient
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [stitchSurfaceHigh, stitchSurface],
            )
          : null,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .045)),
    ),
    child: child,
  );
}

class StitchKicker extends StatelessWidget {
  const StitchKicker(this.label, {super.key, this.color = stitchPeach});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: .8,
    ),
  );
}

class StitchPageHeading extends StatelessWidget {
  const StitchPageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 480;
      return StitchCard(
        gradient: true,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 22,
          vertical: compact ? 16 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StitchKicker(eyebrow, color: stitchOrange),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                color: stitchText,
                fontSize: compact ? 20 : 22,
                height: 1.12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: stitchMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class StitchMetric extends StatelessWidget {
  const StitchMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint = stitchOrange,
    this.detail,
    this.maxValueLines = 1,
    this.valueFontSize = 21,
  });

  final String label, value;
  final IconData icon;
  final Color tint;
  final String? detail;
  final int maxValueLines;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 260;
      final int? lines = compact ? null : maxValueLines;
      final fontSize = compact && valueFontSize > 18 ? 18.0 : valueFontSize;
      return StitchCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: StitchKicker(label)),
                Icon(icon, color: tint, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: lines,
              overflow: compact ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                color: stitchText,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                height: 1.15,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                maxLines: compact ? null : 1,
                overflow: compact
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(color: stitchMuted, fontSize: 9),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class StitchSection extends StatelessWidget {
  const StitchSection({
    super.key,
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
  Widget build(BuildContext context) => StitchCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: stitchOrange, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: stitchText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white.withValues(alpha: .08)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class StitchTag extends StatelessWidget {
  const StitchTag(this.label, {super.key, this.color = stitchOrange});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: .4,
      ),
    ),
  );
}
