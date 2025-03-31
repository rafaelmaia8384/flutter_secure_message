import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_message/services/auth_service.dart';
import 'package:flutter_secure_message/services/key_service.dart';
import 'package:flutter_secure_message/services/message_service.dart';
import 'package:flutter_secure_message/pages/intro_page.dart';
import 'package:flutter_secure_message/pages/home_page.dart';
import 'package:flutter_secure_message/pages/keys_page.dart';
import 'package:flutter_secure_message/theme/app_theme.dart';
import 'package:flutter_secure_message/translations/app_translations.dart';
import 'package:flutter_secure_message/controllers/app_controller.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar os dados de formatação de data para todos os locales
  await initializeDateFormatting();

  // Initialize GetX services
  await Get.putAsync(() => AuthService().init());
  final keyService = KeyService();
  await keyService.init();
  Get.put(keyService);
  final messageService = MessageService();
  await messageService.init();
  Get.put(messageService);
  Get.put(AppController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Secure Message',
      theme: AppTheme.darkTheme,
      translations: AppTranslations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: '/intro',
      getPages: [
        GetPage(
          name: '/intro',
          page: () => IntroPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AuthService());
          }),
        ),
        GetPage(
          name: '/home',
          page: () => HomePage(),
        ),
        GetPage(
          name: '/keys',
          page: () => KeysPage(),
        ),
      ],
    );
  }
}
