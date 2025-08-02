import 'package:flutter/material.dart';

/// Utility class para gerenciar uso seguro de BuildContext
class ContextUtils {
  /// Executa uma função apenas se o context ainda estiver montado
  static void safeContextCall(BuildContext context, VoidCallback callback) {
    if (context.mounted) {
      callback();
    }
  }
  
  /// Mostra SnackBar de forma segura
  static void showSafeSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  
  /// Navega de forma segura
  static void safePop(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
  
  /// Mostra dialog de forma segura
  static Future<T?> showSafeDialog<T>(
    BuildContext context,
    Widget Function(BuildContext) builder,
  ) async {
    if (context.mounted) {
      return await showDialog<T>(
        context: context,
        builder: builder,
      );
    }
    return null;
  }
}