import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class IntroPage extends StatelessWidget {
  final AuthService _authService = Get.find<AuthService>();

  IntroPage({super.key});

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
                        Get.offNamed('/home');
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
