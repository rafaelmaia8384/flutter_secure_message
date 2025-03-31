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
      body: Column(
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
              height: 48,
              child: Obx(() => ElevatedButton(
                    onPressed: _hasText.value && !_isProcessing.value
                        ? _showRecipientSelection
                        : null,
                    child: _isProcessing.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
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
    );
  }

  Future<void> _showRecipientSelection() async {
    // Fechar o teclado e remover o foco
    FocusManager.instance.primaryFocus?.unfocus();

    // Verificar se o usuário possui chave antes de prosseguir
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

    // Buscar a lista de chaves disponíveis
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

    // Mostrar diálogo para selecionar destinatários
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
                  return CheckboxListTile(
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
                      'select_at_least_one'.tr,
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
        // Usuário cancelou a seleção
        return;
      }

      _isProcessing.value = true;

      try {
        final messageText = _textController.text.trim();
        final DateTime currentTimeUTC = DateTime.now().toUtc();
        final String userPublicKey = _keyService.publicKey.value;
        final String senderKey = userPublicKey.isNotEmpty
            ? userPublicKey
            : "anonymous-${DateTime.now().millisecondsSinceEpoch}";

        // Criar lista de itens criptografados
        final List<EncryptedMessageItem> encryptedItems = [];

        // Criptografar para cada destinatário selecionado
        for (final publicKey in value) {
          final encryptedText = await _keyService.encryptMessage(
            messageText,
            publicKey,
          );

          encryptedItems.add(EncryptedMessageItem(
            encryptedText: encryptedText,
            createdAt: DateTime.now().toUtc(),
          ));
        }

        // Criar mensagem temporária (não será armazenada)
        final tempMessage = EncryptedMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderPublicKey: senderKey,
          items: encryptedItems,
          createdAt: currentTimeUTC,
          isImported: false,
          plainText: messageText,
        );

        // Compactar para compartilhamento
        final shareable = _compactMessageForSharing(tempMessage);

        // Compartilhar
        await Share.share(shareable);

        // Voltar para a HomePage após compartilhar
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

  // Método para compactar uma mensagem para compartilhamento
  String _compactMessageForSharing(EncryptedMessage message) {
    try {
      // Verificar se a mensagem tem items criptografados para compartilhar
      if (message.items.isEmpty) {
        print('Aviso: Mensagem sem itens criptografados para compartilhar');

        // Se a mensagem não tem itens criptografados, mas tem texto puro,
        // retorna um formato simplificado para compartilhar apenas o texto
        if (message.plainText.isNotEmpty) {
          print('Compartilhando apenas o texto puro da mensagem');

          // Criar JSON simplificado com apenas o texto puro
          // Não precisamos de id, sender ou createdAt para texto puro
          final Map<String, dynamic> simpleJson = {
            'p': message.plainText, // Incluir apenas o texto puro
          };

          // Converter para string JSON
          final String jsonString = jsonEncode(simpleJson);

          // Codificar em base64
          final String base64String = base64Encode(utf8.encode(jsonString));

          // Retornar com um prefixo diferente para identificar que é texto puro
          return "sec-txt-$base64String";
        }

        // Se não tiver nem texto puro, então realmente não há o que compartilhar
        throw Exception('message_empty_for_sharing'.tr);
      }

      // 1. Criar JSON compacto com chaves minimizadas
      final Map<String, dynamic> compactJson = {
        // Incluir apenas a lista de itens criptografados
        't': message.items
            .map((item) => {
                  'e': item.encryptedText,
                  'd': item.createdAt.toIso8601String(),
                })
            .toList(),
      };

      // 2. Converter para string JSON sem espaços extras
      final String jsonString = jsonEncode(compactJson);

      // 3. Codificar em base64
      final String base64String = base64Encode(utf8.encode(jsonString));

      // 4. Adicionar um prefixo para identificar o formato
      return "sec-$base64String";
    } catch (e) {
      print('Erro ao compactar mensagem: $e');
      throw Exception('Erro ao compactar mensagem: $e');
    }
  }
}
