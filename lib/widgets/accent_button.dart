import 'package:flutter/material.dart';

class AccentButton extends StatelessWidget {
  const AccentButton({
    super.key,
    required this.label,
    required this.flag,
    required this.onPressed,
  });

  final String label;
  final String flag;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: const Icon(Icons.volume_up_rounded),
        label: Text('$flag  $label'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
