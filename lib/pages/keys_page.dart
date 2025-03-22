import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io' show Platform;
import '../controllers/app_controller.dart';
import '../services/key_service.dart';
import '../widgets/action_button.dart';
import 'package:intl/intl.dart';

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  final AppController _appController = Get.find<AppController>();
  final KeyService _keyService = Get.find<KeyService>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late int initialTabIndex;

  @override
  void initState() {
    super.initState();
    // Get the initial tab index from arguments, default to 0 (My Key tab)
    final args = Get.arguments;
    initialTabIndex =
        args != null && args['initialTab'] != null ? args['initialTab'] : 0;
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    try {
      await _keyService.loadKeys();
      await _keyService.loadThirdPartyKeys();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_loading_keys'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text('encryption_keys'.tr),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showKeysHelpDialog,
              tooltip: 'Help',
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'my_key'.tr),
              Tab(text: 'received_keys'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyKeyTab(),
            _buildThirdPartyKeysTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyKeyTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.key,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'your_public_key'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _keyService.hasKeys.value
                          ? _keyService.publicKey.value.toUpperCase()
                          : 'public_key_placeholder'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: _keyService.hasKeys.value
                            ? Colors.white
                            : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_keyService.hasKeys.value) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: () => _copyPublicKey(),
                            tooltip: 'copy_key'.tr,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () => _sharePublicKey(),
                            tooltip: 'share_key'.tr,
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.qr_code, color: Colors.white),
                            onPressed: () => _showQRCode(),
                            tooltip: 'show_qr'.tr,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever),
                            onPressed: () => _showDeleteKeyDialog(),
                            tooltip: 'delete_key'.tr,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'public_key_info'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => !_keyService.hasKeys.value
              ? ElevatedButton.icon(
                  onPressed: () => _showGenerateKeyDialog(),
                  icon: const Icon(Icons.add),
                  label: Text('generate_first_key'.tr),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildThirdPartyKeysTab() {
    return Column(
      children: [
        Expanded(
          child: Obx(() => _keyService.thirdPartyKeys.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.key_off,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_third_party_keys'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'add_third_party_keys_message'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddKeyDialog(),
                        icon: const Icon(Icons.add),
                        label: Text('add_third_party_key'.tr),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _keyService.thirdPartyKeys.length,
                  itemBuilder: (context, index) {
                    final key = _keyService.thirdPartyKeys[index];
                    return ListTile(
                      leading: const Icon(Icons.key),
                      title: Text(key.name),
                      subtitle: Text(
                        '${_formatDate(key.addedAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever),
                        onPressed: () => _deleteThirdPartyKey(index),
                      ),
                    );
                  },
                )),
        ),
        // Only show the bottom action button when there are keys
        Obx(() => _keyService.thirdPartyKeys.isNotEmpty
            ? ActionButton(
                label: 'add_new_key'.tr,
                icon: Icons.add,
                onPressed: () => _showAddKeyDialog(),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Usar o locale do dispositivo para formatar a data
    final locale = Get.locale?.toString() ?? 'en_US';
    final DateFormat dateFormat = DateFormat.yMd(locale).add_Hm();

    return dateFormat.format(date);
  }

  Future<void> _showAddKeyDialog() async {
    final result = await Get.dialog<Map<String, String>>(
      AlertDialog(
        title: Text('add_key_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('add_key_manually'.tr),
              onTap: () => Get.back(result: {'type': 'manual'}),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text('add_key_scan'.tr),
              onTap: () => Get.back(result: {'type': 'scan'}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result['type'] == 'manual') {
        _showManualKeyInput();
      } else {
        _showQRScanner();
      }
    }
  }

  Future<void> _showManualKeyInput() async {
    final keyController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await Get.dialog<Map<String, String>>(
      AlertDialog(
        title: Text('add_key_title'.tr),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'contact_name'.tr,
                  hintText: 'enter_contact_name'.tr,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'contact_name_required'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: 'enter_key'.tr,
                  hintText: 'public_key_placeholder'.tr,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate() &&
                  keyController.text.isNotEmpty) {
                Get.back(result: {
                  'name': nameController.text.trim(),
                  'key': keyController.text,
                });
              } else if (keyController.text.isEmpty) {
                Get.snackbar(
                  'error'.tr,
                  'key_required'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );

    if (result != null && result['key']?.isNotEmpty == true) {
      _addThirdPartyKey(result['key']!, result['name']!);
    }
  }

  Future<void> _showQRScanner() async {
    final result = await Get.to<String>(
      QRScannerPage(qrKey: qrKey),
    );

    if (result != null && result.isNotEmpty) {
      // Show dialog to get contact name
      final nameController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final nameResult = await Get.dialog<String>(
        AlertDialog(
          title: Text('enter_contact_name'.tr),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'contact_name'.tr,
                hintText: 'enter_contact_name'.tr,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'contact_name_required'.tr;
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Get.back(result: nameController.text.trim());
                }
              },
              child: Text('add'.tr),
            ),
          ],
        ),
      );

      if (nameResult != null && nameResult.isNotEmpty) {
        _addThirdPartyKey(result, nameResult);
      }
    }
  }

  void _addThirdPartyKey(String publicKeyString, String name) {
    // Check if key already exists
    bool keyExists = _keyService.thirdPartyKeys.any(
        (key) => key.publicKey.toLowerCase() == publicKeyString.toLowerCase());

    if (keyExists) {
      Get.snackbar(
        'error'.tr,
        'key_already_exists'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (publicKeyString == _keyService.publicKey.value) {
      Get.snackbar(
        'error'.tr,
        'cannot_add_own_key'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_keyService.addThirdPartyKey(publicKeyString, name)) {
      Get.snackbar(
        'success'.tr,
        'key_added'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'invalid_key'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _deleteThirdPartyKey(int index) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_third_party_key_title'.tr),
        content: Text('delete_third_party_key_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        _keyService.deleteThirdPartyKey(index);
        Get.snackbar(
          'success'.tr,
          'key_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'error_deleting_key'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _copyPublicKey() async {
    if (!_keyService.hasKeys.value) return;

    await Clipboard.setData(
        ClipboardData(text: _keyService.publicKey.value.toUpperCase()));
    Get.snackbar(
      'success'.tr,
      'key_copied'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _sharePublicKey() async {
    if (!_keyService.hasKeys.value) return;

    await Share.share(
      '${'my_public_key'.tr}:\n${_keyService.publicKey.value.toUpperCase()}',
      subject: 'public_key_share'.tr,
    );
  }

  Future<void> _showQRCode() async {
    if (!_keyService.hasKeys.value) return;

    await Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'scan_qr_code'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: _keyService.publicKey.value.toUpperCase(),
                version: QrVersions.auto,
                size: 280.0,
                backgroundColor: Colors.white,
                // foregroundColor: Colors.black,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('close'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteKeyDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_key_title'.tr),
        content: Text('delete_key_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      _appController.updateLastActiveTime();
      await _deleteKeys();
    }
  }

  Future<void> _showGenerateKeyDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('generate_key_title'.tr),
        content: Text('generate_key_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('generate'.tr),
          ),
        ],
      ),
    );

    if (result == true) {
      _appController.updateLastActiveTime();
      await _generateNewKeys();
    }
  }

  Future<void> _generateNewKeys() async {
    final success = await _keyService.generateNewKeys();
    if (success) {
      Get.snackbar(
        'success'.tr,
        'keys_generated'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'error_generating_keys'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteKeys() async {
    final success = await _keyService.deleteKeys();
    if (success) {
      Get.snackbar(
        'success'.tr,
        'keys_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'error_deleting_keys'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showKeysHelpDialog() async {
    await Get.dialog(
      Dialog(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.key, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Encryption Keys Guide',
                      style: TextStyle(
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
                        _buildHelpTopic(
                          'What are encryption keys?',
                          'Encryption keys are digital codes used to encrypt and decrypt messages. They ensure that only the intended recipient can read the messages you send.',
                        ),
                        _buildHelpTopic(
                          'Public vs Private Keys',
                          'This app uses asymmetric encryption with key pairs:\n'
                              '• Private Key: Kept secret on your device. Never share it.\n'
                              '• Public Key: Can be shared with others who want to send you encrypted messages.',
                        ),
                        _buildHelpTopic(
                          'How encryption works',
                          'When you send a message:\n'
                              '1. Your message is encrypted using the recipient\'s public key\n'
                              '2. Only the recipient\'s private key can decrypt it\n'
                              '3. Not even you can decrypt the message once sent',
                        ),
                        _buildHelpTopic(
                          'Sharing your public key',
                          'Share your public key with others so they can send you encrypted messages. You can share it via:\n'
                              '• QR Code\n'
                              '• Copy & Paste\n'
                              '• Share button\n\n'
                              'Your public key is safe to share - it cannot be used to decrypt messages.',
                        ),
                        _buildHelpTopic(
                          'Managing others\' keys',
                          'Add public keys from your contacts to send them encrypted messages. You can:\n'
                              '• Scan their QR code\n'
                              '• Enter their key manually\n'
                              '• Give them a recognizable name',
                        ),
                        _buildHelpTopic(
                          'Security best practices',
                          '• Generate a new key pair if you suspect your device is compromised\n'
                              '• Never share your private key with anyone\n'
                              '• Verify the identity of people whose public keys you add\n'
                              '• Always use secure channels when sharing public keys',
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
                    child: const Text('Got it'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
}

class QRScannerPage extends StatefulWidget {
  final GlobalKey qrKey;

  const QRScannerPage({super.key, required this.qrKey});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  QRViewController? controller;
  bool isScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('scan_qr'.tr),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: widget.qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'scan_instructions'.tr,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanned && scanData.code != null) {
        isScanned = true;
        Get.back(result: scanData.code);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
