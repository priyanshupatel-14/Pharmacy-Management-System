import 'package:flutter/material.dart';

enum BadgeStatus {
  success,
  warning,
  error,
  info,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;

  const StatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case BadgeStatus.success:
        backgroundColor = const Color(0xFFDCFCE7); // Green 100
        textColor = const Color(0xFF166534); // Green 800
        break;
      case BadgeStatus.warning:
        backgroundColor = const Color(0xFFFEF9C3); // Yellow 100
        textColor = const Color(0xFF854D0E); // Yellow 800
        break;
      case BadgeStatus.error:
        backgroundColor = const Color(0xFFFEE2E2); // Red 100
        textColor = const Color(0xFF991B1B); // Red 800
        break;
      case BadgeStatus.info:
        backgroundColor = const Color(0xFFE0F2FE); // Light Blue 100
        textColor = const Color(0xFF075985); // Light Blue 800
        break;
      case BadgeStatus.neutral:
        backgroundColor = const Color(0xFFF1F5F9); // Slate 100
        textColor = const Color(0xFF334155); // Slate 700
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
