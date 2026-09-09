import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;

    final s = status.toLowerCase().replaceAll(' ', '_');

    switch (s) {
      case 'pending':
        bg = const Color(0xFFFF9800); // Orange
        break;
      case 'in_progress':
        bg = const Color(0xFF2196F3); // Blue
        break;
      case 'resolved':
      case 'approved':
      case 'present':
        bg = const Color(0xFF4CAF50); // Green
        break;
      case 'rejected':
      case 'absent':
        bg = const Color(0xFFF44336); // Red
        break;
      case 'leave':
        bg = const Color(0xFFFF9800); // Orange
        break;
      default:
        bg = const Color(0xFF9E9E9E); // Grey
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
