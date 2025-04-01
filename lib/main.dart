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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting data for all locales
  await initializeDateFormatting();

  // Initialize GetX services
  // 1. Put FlutterSecureStorage first, as KeyService depends on it
  Get.put(const FlutterSecureStorage());

  // 2. Initialize and put AuthService
  await Get.putAsync(() => AuthService().init());

  // 3. Initialize and put KeyService (now it can find FlutterSecureStorage)
  // You can use putAsync here too if init is complex, or keep it separate
  // Using putAsync for consistency:
  await Get.putAsync(() => KeyService().init());

  // 4. Initialize and put MessageService
  // Assuming MessageService might depend on KeyService, put it after
  await Get.putAsync(() => MessageService().init());

  // 5. Put AppController
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
