import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Shared page frame. Existing business flows supply their own actions and body.
class GymScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final double maxWidth;
  const GymScaffold({super.key, this.appBar, this.body, this.drawer,
    this.floatingActionButton, this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true, this.maxWidth = 1120});

  @override
  Widget build(BuildContext context) {
    final original = appBar;
    final bar = original is AppBar ? AppBar(
      title: original.title,
      leading: original.leading,
      automaticallyImplyLeading: original.automaticallyImplyLeading,
      actions: original.actions,
      bottom: original.bottom,
      toolbarHeight: 64,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      shape: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ) : original;
    return Scaffold(
      appBar: bar, drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(top: appBar == null, child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, height: double.infinity, child: body)),
      )),
    );
  }
}

class GymDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final bool scrollable;
  final EdgeInsetsGeometry? contentPadding;
  const GymDialog({super.key, this.title, this.content, this.actions,
    this.scrollable = true, this.contentPadding});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: title, content: content == null ? null : SizedBox(width: (MediaQuery.sizeOf(context).width - 88).clamp(120.0, 472.0), child: content), actions: actions, scrollable: scrollable,
    contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(24, 12, 24, 20),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    constraints: const BoxConstraints(maxWidth: 560),
  );
}

/// Natural-height rows keep long names, amounts and actions readable.
class GymListTile extends StatelessWidget {
  final Widget? leading, title, subtitle, trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool isThreeLine;
  const GymListTile({super.key, this.leading, this.title, this.subtitle,
    this.trailing, this.onTap, this.contentPadding, this.isThreeLine = false});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Padding(padding: contentPadding ?? const EdgeInsets.all(18),
      child: LayoutBuilder(builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420 || MediaQuery.textScalerOf(context).scale(14) > 19;
        final text = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (title != null) DefaultTextStyle.merge(style: Theme.of(context).textTheme.titleSmall, child: title!),
          if (subtitle != null) ...[const SizedBox(height: 6),
            DefaultTextStyle.merge(style: Theme.of(context).textTheme.bodySmall, child: subtitle!)],
        ]);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (leading != null) ...[IconTheme.merge(data: IconThemeData(color: Theme.of(context).colorScheme.primary, size: 24), child: leading!), const SizedBox(width: 14)],
            Expanded(child: text),
            if (!stacked && trailing != null) ...[const SizedBox(width: 14), trailing!],
            if (onTap != null && trailing == null) ...[const SizedBox(width: 8), const Icon(Icons.chevron_left_rounded, size: 20)],
          ]),
          if (stacked && trailing != null) ...[const SizedBox(height: 12),
            Align(alignment: AlignmentDirectional.centerStart, child: trailing!)],
        ]);
      }),
    ),
  );
}

class GymHero extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final IconData icon;
  final Widget? child;
  const GymHero({super.key, required this.eyebrow, required this.title,
    required this.subtitle, this.icon = Icons.fitness_center_rounded, this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? GymPalette.darkSurface : const Color(0xFFEEF5E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: dark ? .3 : .18)),
      ),
      child: CustomPaint(painter: _GymHeroPattern(accent),
        child: Padding(padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 4, height: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(child: Text(eyebrow, style: theme.textTheme.labelLarge?.copyWith(
                color: accent, fontWeight: FontWeight.w800, letterSpacing: .5))),
              Icon(icon, color: accent, size: 26),
            ]),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (child != null) ...[const SizedBox(height: 18), child!],
          ]),
        ),
      ),
    );
  }
}

/// Decorative track lines keep the identity athletic without image downloads.
class _GymHeroPattern extends CustomPainter {
  final Color color;
  const _GymHeroPattern(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: .06)..strokeWidth = 12;
    for (var i = 0; i < 3; i++) {
      final x = 14.0 + i * 24;
      canvas.drawLine(Offset(x, 0), Offset(x + 52, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(_GymHeroPattern oldDelegate) => oldDelegate.color != color;
}

class GymSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const GymSection({super.key, required this.title, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium), if (action != null) action!,
      ]),
      if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)],
    ]),
  );
}

class GymGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final int maxColumns;
  const GymGrid({super.key, required this.children, this.minWidth = 155, this.maxColumns = 4});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final columns = (constraints.maxWidth / (minWidth * textScale + 12)).floor().clamp(1, maxColumns);
    final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
    return Wrap(spacing: 12, runSpacing: 12, children: [for (final child in children) SizedBox(width: width, child: child)]);
  });
}

class GymMetric extends StatelessWidget {
  final String label, value;
  final String? hint;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  const GymMetric({super.key, required this.label, required this.value,
    required this.icon, this.color, this.hint, this.onTap});
  @override
  Widget build(BuildContext context) {
    final tint = gymTone(context, color ?? Theme.of(context).colorScheme.primary);
    return Card(margin: EdgeInsets.zero, child: InkWell(onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: tint, size: 24),
          const Spacer(),
          Container(width: 32, height: 3, color: tint.withValues(alpha: .65)),
        ]), const SizedBox(height: 12),
        Text(value, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: tint)),
        const SizedBox(height: 6), Text(label, style: Theme.of(context).textTheme.titleSmall),
        if (hint != null) ...[const SizedBox(height: 4), Text(hint!, style: Theme.of(context).textTheme.bodySmall)],
      ])),
    ));
  }
}

class GymIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  const GymIcon({super.key, required this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final tint = gymTone(context, color ?? Theme.of(context).colorScheme.primary);
    return Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: tint.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: tint, size: 24));
  }
}

class GymBadge extends StatelessWidget {
  final String label;
  final Color color;
  const GymBadge({super.key, required this.label, this.color = AppColors.primary});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: gymTone(context, color).withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: gymTone(context, color), fontWeight: FontWeight.w700)),
  );
}

class GymEmptyState extends StatelessWidget {
  final String title;
  final String? message, actionLabel;
  final IconData icon;
  final VoidCallback? onAction;
  const GymEmptyState({super.key, required this.title, this.message,
    this.icon = Icons.inbox_outlined, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GymIcon(icon: icon), const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        if (message != null) ...[const SizedBox(height: 8), Text(message!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)],
        if (onAction != null) ...[const SizedBox(height: 20), FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel ?? 'إضافة'))],
      ]),
    ),
  ));
}

class GymErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;
  const GymErrorState({super.key, this.onRetry, this.message = 'تعذّر تحميل البيانات. تأكد من اتصالك وحاول مرة تانية.'});
  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const GymIcon(icon: Icons.wifi_off_rounded, color: AppColors.warning),
      const SizedBox(height: 16), Text('نحاول تاني؟', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8), Text(message, textAlign: TextAlign.center),
      if (onRetry != null) ...[const SizedBox(height: 20), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة'))],
    ]),
  ));
}

class GymLoading extends StatelessWidget {
  const GymLoading({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const LinearProgressIndicator(minHeight: 3), const SizedBox(height: 24),
        for (final width in [.9, .65, .8]) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: FractionallySizedBox(widthFactor: width, child: Container(height: 18,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)))))],
      ),
    ),
  ));
}

class GymTextField extends StatefulWidget {
  final TextEditingController? controller;
  final InputDecoration decoration;
  final String? initialValue;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final bool obscureText, enabled;
  final int? maxLength;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  const GymTextField({super.key, this.controller, this.decoration = const InputDecoration(),
    this.initialValue, this.keyboardType, this.validator, this.obscureText = false,
    this.enabled = true, this.maxLength, this.maxLines = 1, this.textInputAction,
    this.onFieldSubmitted, this.autofillHints});
  @override
  State<GymTextField> createState() => _GymTextFieldState();
}

class _GymTextFieldState extends State<GymTextField> {
  bool _revealed = false;
  @override
  Widget build(BuildContext context) {
    final numeric = widget.keyboardType == TextInputType.phone || widget.keyboardType == TextInputType.number || widget.keyboardType?.index == TextInputType.number.index;
    final ltr = numeric || widget.keyboardType == TextInputType.emailAddress || widget.obscureText;
    return TextFormField(controller: widget.controller, initialValue: widget.initialValue,
      decoration: widget.obscureText && widget.decoration.suffixIcon == null ? widget.decoration.copyWith(suffixIcon: IconButton(tooltip: _revealed ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور', icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _revealed = !_revealed))) : widget.decoration, keyboardType: widget.keyboardType,
      validator: widget.validator, obscureText: widget.obscureText && !_revealed, enabled: widget.enabled,
      maxLength: widget.maxLength, maxLines: widget.maxLines,
      textDirection: ltr ? TextDirection.ltr : null,
      textInputAction: widget.textInputAction ?? (widget.maxLines == 1 ? TextInputAction.next : TextInputAction.newline),
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: !ltr, enableSuggestions: !widget.obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}

String gymAmount(num value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

class GymFormRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  const GymFormRow({super.key, required this.children, this.mainAxisAlignment = MainAxisAlignment.start});
  @override
  Widget build(BuildContext context) => GymGrid(minWidth: 230, maxColumns: 2,
    children: [for (final child in children) if (child is! SizedBox) child is Expanded ? child.child : child]);
}

Color gymTone(BuildContext context, Color color) {
  if (Theme.of(context).brightness == Brightness.dark || color.computeLuminance() < .2) return color;
  return HSLColor.fromColor(color).withLightness(.32).toColor();
}
