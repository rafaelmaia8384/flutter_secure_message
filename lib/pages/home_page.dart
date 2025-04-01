import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'new_message_page.dart';
import 'decrypt_message_page.dart';
import '../widgets/action_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('welcome'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: () => Get.toNamed('/keys'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ActionButton(
                label: 'Encrypt new Message',
                icon: Icons.lock,
                onPressed: () => Get.to(() => const NewMessagePage()),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ActionButton(
                label: 'Decrypt Message',
                icon: Icons.lock_open,
                onPressed: () => Get.to(() => const DecryptMessagePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
