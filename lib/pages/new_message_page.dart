import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../services/key_service.dart';
import '../models/encrypted_message.dart';
import 'dart:convert';

class RecipientSelectionController extends GetxController {
  final KeyService _keyService = Get.find<KeyService>();
  final RxList<bool> selectedRecipients = <bool>[].obs;
  final RxBool includeSelf = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSelectedRecipients();
  }

  void _initializeSelectedRecipients() {
    selectedRecipients.value = List.generate(
      _keyService.thirdPartyKeys.length,
      (_) => false,
    );

    includeSelf.value = false;
  }

  void toggleRecipient(int index, bool? value) {
    // Create a new list with the updated value to trigger reactivity
    final newList = selectedRecipients.toList();
    newList[index] = value ?? false;
    selectedRecipients.value = newList;
  }

  void toggleSelf(bool? value) {
    includeSelf.value = value ?? false;
  }

  List<int> getSelectedIndexes() {
    final List<int> selectedIndexes = [];
    for (var i = 0; i < selectedRecipients.length; i++) {
      if (selectedRecipients[i]) {
        selectedIndexes.add(i);
      }
    }
    return selectedIndexes;
  }

  bool hasAtLeastOneRecipient() {
    return includeSelf.value || selectedRecipients.contains(true);
  }
}

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final KeyService _keyService = Get.find<KeyService>();
  final TextEditingController _textController = TextEditingController();
  final RxBool _hasText = false.obs;
  final RxBool _isProcessing = false.obs;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateHasText);
  }

  void _updateHasText() {
    _hasText.value = _textController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _textController.removeListener(_updateHasText);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('new_message'.tr),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() => TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      enabled: !_isProcessing.value,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'enter_message'.tr,
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                      onPressed: _hasText.value && !_isProcessing.value
                          ? _showRecipientSelection
                          : null,
                      child: _isProcessing.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Encrypt and Share'),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecipientSelection() async {
    // Fechar o teclado e remover o foco
    FocusManager.instance.primaryFocus?.unfocus();

    // Check if user has a key before proceeding
    if (!_keyService.hasKeys.value) {
      Get.dialog(
        AlertDialog(
          title: Text('no_public_key_title'.tr),
          content: Text('need_public_key_for_encrypt'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('close'.tr),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/keys');
              },
              child: Text('generate_key'.tr),
            ),
          ],
        ),
      );
      return;
    }

    // Get list of available keys
    final keyList = List.from(_keyService.thirdPartyKeys);
    keyList.insert(
      0,
      ThirdPartyKey(
        name: 'me'.tr,
        publicKey: _keyService.publicKey.value,
        addedAt: DateTime.now(),
      ),
    );

    List<String> selectedKeys = [];

    // Show dialog to select recipients
    await Get.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('select_recipients'.tr),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: keyList.length,
                itemBuilder: (context, index) {
                  final key = keyList[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CheckboxListTile(
                        title: Text(key.name),
                        value: selectedKeys.contains(key.publicKey),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedKeys.add(key.publicKey);
                            } else {
                              selectedKeys.remove(key.publicKey);
                            }
                          });
                        },
                      ),
                      if (index == 0 && keyList.length > 1) Divider(),
                    ],
                  );
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
                  if (selectedKeys.isEmpty) {
                    Get.snackbar(
                      'error'.tr,
                      'select_at_least_one_recipient'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  Get.back(result: selectedKeys);
                },
                child: Text('confirm'.tr),
              ),
            ],
          );
        },
      ),
    ).then((value) async {
      if (value == null || (value is List && value.isEmpty)) {
        // User cancelled the selection
        return;
      }

      _isProcessing.value = true;

      try {
        final messageText = _textController.text.trim();
        final String userPublicKey = _keyService.publicKey.value;
        final String senderKey = userPublicKey;

        // Encrypt for each selected recipient
        final List<EncryptedMessageItem> encryptedItems = [];

        // Encrypt for each selected recipient
        for (final publicKey in value) {
          final encryptedText = await _keyService.encryptMessage(
            messageText,
            publicKey,
          );

          encryptedItems.add(EncryptedMessageItem(
            encryptedText: encryptedText,
          ));
        }

        // Create temporary message (will not be stored)
        final tempMessage = EncryptedMessage(
          senderPublicKey: senderKey,
          items: encryptedItems,
          isImported: false,
        );

        // Compact a message for sharing
        final shareable = _compactMessageForSharing(tempMessage);

        // Compartilhar
        await Share.share(shareable);

        // Return to HomePage after sharing
        Get.back();
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'error_encrypting'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        print('Erro ao criptografar: $e');
      } finally {
        _isProcessing.value = false;
      }
    });
  }

  // Method to compact a message for sharing
  String _compactMessageForSharing(EncryptedMessage message) {
    try {
      // Check if there are items to share
      if (message.items.isEmpty) {
        print('Aviso: Mensagem sem itens criptografados para compartilhar');

        // If there are no items to share, nothing to do
        throw Exception('message_empty_for_sharing'.tr);
      }

      // 1. Create compact JSON with minimized keys
      final Map<String, dynamic> compactJson = {
        // Include only the list of encrypted items
        't': message.items
            .map((item) => {
                  'e': item.encryptedText,
                })
            .toList(),
      };

      // 2. Convert to JSON string without extra spaces
      final String jsonString = jsonEncode(compactJson);

      // 3. Encode to base64
      final String base64String = base64Encode(utf8.encode(jsonString));

      // 4. Add a prefix to identify the format
      return "sec-msg:$base64String";
    } catch (e) {
      print('Erro ao compactar mensagem: $e');
      throw Exception('Erro ao compactar mensagem: $e');
    }
  }
}
