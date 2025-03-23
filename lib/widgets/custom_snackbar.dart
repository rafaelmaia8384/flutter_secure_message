import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Um serviço de Snackbar personalizado que não interfere nas interações com diálogos
class CustomSnackbar {
  /// Mostra um snackbar que não interfere nos diálogos abertos
  static void show({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Color? backgroundColor,
    Color? colorText,
    Duration duration = const Duration(milliseconds: 1500),
    Widget? icon,
    double borderRadius = 8.0,
  }) {
    // Sempre fechar qualquer snackbar existente antes de mostrar um novo
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration,
      icon: icon,
      borderRadius: borderRadius,
      overlayBlur: 0, // Remove o blur do overlay
      overlayColor:
          Colors.transparent, // Torna o overlay transparente para cliques
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCirc,
      margin: const EdgeInsets.all(8),
    );
  }

  /// Fechar todos os snackbars abertos
  static void closeAll() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
  }

  /// Mostra um diálogo de confirmação após fechar todos os snackbars
  static Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDangerousAction = false,
  }) async {
    // Sempre fechar snackbars antes de mostrar um diálogo
    closeAll();

    return await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDangerousAction ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
