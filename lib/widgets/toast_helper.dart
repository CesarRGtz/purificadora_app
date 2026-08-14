import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

/// Helper para mostrar notificaciones SnackBar tipo toast
class ToastHelper {
  static void show(BuildContext context, String message, {ToastType type = ToastType.info}) {
    final colors = {
      ToastType.success: const Color(0xFF10B981),
      ToastType.error: const Color(0xFFEF4444),
      ToastType.warning: const Color(0xFFF59E0B),
      ToastType.info: const Color(0xFF3B82F6),
    };

    final icons = {
      ToastType.success: Icons.check_circle,
      ToastType.error: Icons.error,
      ToastType.warning: Icons.warning,
      ToastType.info: Icons.info,
    };

    final color = colors[type]!;
    final icon = icons[type]!;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
