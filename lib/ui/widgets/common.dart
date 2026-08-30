import 'package:flutter/material.dart';

import '../../models/pillar.dart';
import '../../theme/tokens.dart';

/// Flat card: one hairline border, no shadow, no gradient.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.x14),
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(Rad.card),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.card),
        child: body,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.top = Sp.x24});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: Sp.x10),
      child: Text(
        text.toUpperCase(),
        style: AppType.sectionLabel.copyWith(color: context.t.faint),
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.eyebrow, this.subtitle});

  final String title;
  final String? eyebrow;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(),
              style: AppType.sectionLabel.copyWith(color: t.faint)),
          const SizedBox(height: Sp.x4),
        ],
        Text(title, style: AppType.screenTitle.copyWith(color: t.ink)),
        if (subtitle != null) ...[
          const SizedBox(height: Sp.x8),
          Text(subtitle!, style: AppType.body.copyWith(color: t.muted)),
        ],
      ],
    );
  }
}

/// Thin progress bar. 3px inside a card, 5px where progress is the
/// primary content of the row.
class ThinBar extends StatelessWidget {
  const ThinBar({
    super.key,
    required this.value,
    this.color,
    this.height = 3,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Rad.bar),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: t.track,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? t.ink),
        ),
      ),
    );
  }
}

IconData pillarIcon(Pillar p) => switch (p) {
      Pillar.work => Icons.work_outline_rounded,
      Pillar.training => Icons.fitness_center_rounded,
      Pillar.faith => Icons.mosque_outlined,
      Pillar.family => Icons.people_outline_rounded,
      Pillar.learning => Icons.menu_book_outlined,
      Pillar.personal => Icons.person_outline_rounded,
      Pillar.content => Icons.play_circle_outline_rounded,
      Pillar.rest => Icons.local_cafe_outlined,
    };

class PillarBadge extends StatelessWidget {
  const PillarBadge(this.pillar, {super.key, this.size = 30});

  final Pillar pillar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.pillarTint(pillar),
        borderRadius: BorderRadius.circular(Rad.badge),
      ),
      child: Icon(pillarIcon(pillar),
          size: size * 0.57, color: t.pillar(pillar)),
    );
  }
}

class PillarDot extends StatelessWidget {
  const PillarDot(this.pillar, {super.key, this.size = 7});

  final Pillar pillar;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.t.pillar(pillar),
          shape: BoxShape.circle,
        ),
      );
}

/// Tinted label used for status and RPE. Grey when there is no accent —
/// dormant things should not wear colour.
class TintPill extends StatelessWidget {
  const TintPill(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x8, vertical: 3),
      decoration: BoxDecoration(
        color: c == null ? t.track : c.withValues(alpha: t.tint),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: manrope(size: 11, weight: 700, color: c ?? t.muted),
      ),
    );
  }
}

/// The one primary action, always in the dock at the bottom of the screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final enabled = onPressed != null;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Material(
        color: enabled ? t.btn : t.btnOff,
        borderRadius: BorderRadius.circular(Rad.button),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(Rad.button),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 18, color: enabled ? t.btnInk : t.btnOffInk),
                  const SizedBox(width: Sp.x8),
                ],
                Text(
                  label,
                  style: AppType.button
                      .copyWith(color: enabled ? t.btnInk : t.btnOffInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.bordered = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.button),
          side: bordered ? BorderSide(color: t.line) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(Rad.button),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: t.muted),
                  const SizedBox(width: Sp.x8),
                ],
                Text(label,
                    style: manrope(size: 14, weight: 700, color: t.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sits above the tab bar. Every screen's primary action lives here, in
/// the same place, within thumb reach.
class Dock extends StatelessWidget {
  const Dock({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x14, Sp.x20, Sp.x10),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.height = 150,
  });

  final String title;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Sp.x24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.card),
        border: Border.all(color: t.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: manrope(size: 14.5, weight: 700, color: t.ink)),
          const SizedBox(height: Sp.x6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppType.meta.copyWith(color: t.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Capture has to cost nothing, so this is always visible and always in
/// the same place.
class QuickAddField extends StatefulWidget {
  const QuickAddField({
    super.key,
    required this.hint,
    required this.onSubmit,
  });

  final String hint;
  final ValueChanged<String> onSubmit;

  @override
  State<QuickAddField> createState() => _QuickAddFieldState();
}

class _QuickAddFieldState extends State<QuickAddField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: Sp.x14, right: Sp.x6),
      decoration: BoxDecoration(
        color: t.field,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(Rad.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: AppType.body.copyWith(color: t.ink),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppType.body.copyWith(color: t.faint),
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: Sp.x8),
          Material(
            color: t.btn,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.add_rounded, size: 20, color: t.btnInk),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded square checkbox that fills with the pillar colour.
class TaskCheck extends StatelessWidget {
  const TaskCheck({
    super.key,
    required this.done,
    required this.color,
    this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: done ? color : t.field,
          border: Border.all(color: done ? color : t.line, width: 1.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
            : null,
      ),
    );
  }
}

class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 38,
          height: 4,
          margin: const EdgeInsets.only(bottom: Sp.x14),
          decoration: BoxDecoration(
            color: context.t.line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

extension WidgetBackground on Widget {
  Widget withBackground(Color color) => ColoredBox(color: color, child: this);
}
