import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/key_service.dart';

class IntroPage extends StatelessWidget {
  final AuthService _authService = Get.find<AuthService>();
  final KeyService _keyService = Get.find<KeyService>();

  IntroPage({super.key});

  // Method to check and generate keys if needed
  Future<void> _ensureKeysExist() async {
    // Check if keys already exist
    if (!_keyService.hasKeys.value) {
      // Keys don't exist, show loading dialog
      Get.dialog(
        AlertDialog(
          title: Text('generating_keys'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('please_wait'.tr),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      try {
        // Generate new keys
        final result = await _keyService.generateNewKeys();

        // Close the dialog
        Get.back();

        if (!result) {
          // If key generation failed, show error dialog
          Get.dialog(
            AlertDialog(
              title: Text('error'.tr),
              content: Text('key_generation_failed'.tr),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('ok'.tr),
                ),
              ],
            ),
          );
        } else {
          // Navigate to home page on success
          Get.offNamed('/home');
        }
      } catch (e) {
        // Close dialog if open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Show error dialog
        Get.dialog(
          AlertDialog(
            title: Text('error'.tr),
            content: Text('key_generation_error'.tr + ': $e'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('ok'.tr),
              ),
            ],
          ),
        );
      }
    } else {
      // Keys already exist, navigate to home page
      Get.offNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 32),
                Text(
                  'welcome'.tr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'secure_message'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Obx(() {
                  if (!_authService.hasBiometrics.value) {
                    return Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'biometric_not_available'.tr,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  if (!_authService.hasEnrolledBiometrics.value) {
                    return Column(
                      children: [
                        const Icon(
                          Icons.fingerprint,
                          color: Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'setup_biometric'.tr,
                            style: const TextStyle(color: Colors.orange),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }

                  return ElevatedButton(
                    onPressed: () async {
                      final success = await _authService.authenticate();
                      if (success) {
                        // Check and generate keys if needed before navigation
                        await _ensureKeysExist();
                      }
                    },
                    child: Text('authenticate'.tr),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
