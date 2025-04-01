import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'new_message_page.dart';
import 'decrypt_message_page.dart';
import '../widgets/action_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Helper function to build help topics, similar to KeysPage
  Widget _buildHelpTopic(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _showHowItWorksDialog(BuildContext context) async {
    await Get.dialog(
      Dialog(
        child: Container(
          width: double.infinity,
          constraints:
              const BoxConstraints(maxHeight: 500), // Adjust height as needed
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'how_to_get_started_title'.tr, // New translation key
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add tutorial steps using _buildHelpTopic and new translation keys
                        _buildHelpTopic(
                          'how_to_get_started_step1_title'.tr,
                          'how_to_get_started_step1_desc'.tr,
                        ),
                        _buildHelpTopic(
                          'how_to_get_started_step2_title'.tr,
                          'how_to_get_started_step2_desc'.tr,
                        ),
                        _buildHelpTopic(
                          'how_to_get_started_step3_title'.tr,
                          'how_to_get_started_step3_desc'.tr,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: Text('got_it'.tr), // Reuse existing key
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                label: 'encrypt_new_message'.tr,
                icon: Icons.lock,
                onPressed: () => Get.to(() => const NewMessagePage()),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ActionButton(
                label: 'decrypt_message'.tr,
                icon: Icons.lock_open,
                onPressed: () => Get.to(() => const DecryptMessagePage()),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ActionButton(
                label: 'how_it_works'.tr,
                backgroundColor: Colors.grey[900],
                icon: Icons.help_outline,
                onPressed: () => _showHowItWorksDialog(context),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ActionButton(
                label: 'buy_me_a_coffee'.tr,
                backgroundColor: Colors.grey[900],
                icon: Icons.favorite_outline,
                onPressed: () => Get.to(() => const DecryptMessagePage()),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'internet_connection_info'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
