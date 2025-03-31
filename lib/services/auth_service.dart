import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final RxBool isAuthenticated = false.obs;
  final RxBool hasBiometrics = false.obs;
  final RxBool hasEnrolledBiometrics = false.obs;

  Future<AuthService> init() async {
    hasBiometrics.value = await _localAuth.canCheckBiometrics;
    if (hasBiometrics.value) {
      hasEnrolledBiometrics.value = await _localAuth.isDeviceSupported();
    }
    return this;
  }

  Future<bool> authenticate() async {
    try {
      if (!hasBiometrics.value) {
        Get.snackbar(
          'Error',
          'This device does not support biometric authentication',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      if (!hasEnrolledBiometrics.value) {
        Get.snackbar(
          'Error',
          'Please set up biometric authentication in your device settings',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access Secure Message',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      isAuthenticated.value = didAuthenticate;
      return didAuthenticate;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Authentication failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
