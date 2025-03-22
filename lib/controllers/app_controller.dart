import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_message/services/auth_service.dart';

class AppController extends GetxController with WidgetsBindingObserver {
  final AuthService _authService = Get.find<AuthService>();
  final RxBool isAuthenticated = false.obs;
  DateTime? _pauseTime;
  static const int _inactivityTimeoutSeconds = 10;
  final RxBool biometricAuthenticated = false.obs;
  final RxInt lastActiveTimeMillis = 0.obs;

  // Variável para controlar a animação de novos itens na HomePage
  final RxBool shouldAnimateNewMessages = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onPause();
        break;
      case AppLifecycleState.resumed:
        _onResume();
        break;
      default:
        break;
    }
  }

  void _onPause() {
    _pauseTime = DateTime.now();
  }

  void _onResume() {
    if (_pauseTime != null) {
      final secondsPassed = DateTime.now().difference(_pauseTime!).inSeconds;
      if (secondsPassed >= _inactivityTimeoutSeconds) {
        _logout();
      }
      _pauseTime = null;
    }
  }

  void _logout() {
    _authService.isAuthenticated.value = false;
    Get.offAllNamed('/intro');
  }

  void updateLastActiveTime() {
    _pauseTime = null;
  }

  // Método para sinalizar que há novas mensagens e que devem ser animadas
  void triggerMessageAnimation() {
    shouldAnimateNewMessages.value = true;

    // Reset após um breve período para permitir múltiplas animações
    Future.delayed(const Duration(seconds: 2), () {
      shouldAnimateNewMessages.value = false;
    });
  }
}
