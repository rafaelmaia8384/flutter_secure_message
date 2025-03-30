import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/key_service.dart';
import '../services/message_service.dart';
import '../models/encrypted_message.dart';
import 'dart:math' as math;

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
  late final MessageService _messageService;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateHasText);
    _messageService = Get.find<MessageService>();
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
                        : Text('save_message'.tr),
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

    // Não mostra mais o diálogo de seleção de destinatários
    // Vai direto para salvar a mensagem em texto simples
    await _encryptAndSaveMessage();
  }

  Future<void> _encryptAndSaveMessage() async {
    _isProcessing.value = true;

    final messageText = _textController.text.trim();

    try {
      // Garantir um tempo mínimo para o loading
      await Future.delayed(const Duration(milliseconds: 800));

      // Usar DateTime UTC para armazenamento global
      final DateTime currentTimeUTC = DateTime.now().toUtc();

      // Obter a chave pública do usuário para identificar o remetente
      final String userPublicKey = _keyService.publicKey.value;

      // Usar um valor padrão para o remetente caso o usuário não tenha chave
      final String senderKey = userPublicKey.isNotEmpty
          ? userPublicKey
          : "anonymous-${DateTime.now().millisecondsSinceEpoch}";

      print("Salvando mensagem em texto simples sem criptografia imediata");
      print(
          "Remetente: ${senderKey.substring(0, math.min(10, senderKey.length))}...");

      // Criar lista vazia de items - a criptografia será feita apenas no momento do compartilhamento
      final List<EncryptedMessageItem> items = [];

      // Criar e salvar a mensagem com o texto original em plainText
      final newMessage = EncryptedMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderPublicKey: senderKey,
        items: items, // Lista vazia, pois não há criptografia ainda
        createdAt: currentTimeUTC,
        isImported: false,
        plainText: messageText, // Armazenar o texto original
      );

      await _messageService.addMessage(newMessage);

      // Simplesmente voltar para a HomePage anterior
      Get.back(result: true);
    } catch (e) {
      // Mostrar mensagem de erro
      Get.snackbar(
        'error'.tr,
        'error_saving_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Error saving message: $e');
    } finally {
      _isProcessing.value = false;
    }
  }
}
