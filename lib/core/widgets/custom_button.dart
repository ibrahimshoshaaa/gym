import 'package:flutter/material.dart';
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading, outlined;
  final IconData? icon;
  const CustomButton({super.key, required this.label, required this.onPressed, this.isLoading = false, this.icon, this.outlined = false});
  @override
  Widget build(BuildContext context) {
    final child = isLoading ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2,
      color: outlined ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary))
      : Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)], Flexible(child: Text(label, textAlign: TextAlign.center))]);
    return outlined ? OutlinedButton(onPressed: isLoading ? null : onPressed, child: child)
      : FilledButton(onPressed: isLoading ? null : onPressed, child: child);
  }
}
