import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../services/key_service.dart';
import '../services/message_service.dart';
import '../models/encrypted_message.dart';
import 'dart:math' as math;

class RecipientSelectionController extends GetxController {
  final KeyService _keyService = Get.find<KeyService>();
  final RxList<bool> selectedRecipients = <bool>[].obs;

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
  }

  void toggleRecipient(int index, bool? value) {
    // Create a new list with the updated value to trigger reactivity
    final newList = selectedRecipients.toList();
    newList[index] = value ?? false;
    selectedRecipients.value = newList;
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
}

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final AppController _appController = Get.find<AppController>();
  final KeyService _keyService = Get.find<KeyService>();
  final TextEditingController _textController = TextEditingController();
  final RxBool _hasText = false.obs;
  final RxBool _isProcessing = false.obs;
  late final RecipientSelectionController _recipientController;
  late final MessageService _messageService;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateHasText);
    _recipientController = Get.put(RecipientSelectionController());
    _messageService = Get.find<MessageService>();

    // Verificar se o usuário tem chave ao iniciar a página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserHasKey();
    });
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
                        : Text('continue'.tr),
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

    final result = await Get.dialog<List<bool>>(
      AlertDialog(
        title: Text('authorized_third_parties'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _keyService.thirdPartyKeys.length,
            itemBuilder: (context, index) {
              final key = _keyService.thirdPartyKeys[index];
              return Obx(() => CheckboxListTile(
                    title: Text(key.name),
                    value: _recipientController.selectedRecipients[index],
                    onChanged: (bool? value) {
                      _recipientController.toggleRecipient(index, value);
                    },
                  ));
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _recipientController._initializeSelectedRecipients();
              Get.back();
            },
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              if (_recipientController.selectedRecipients
                  .any((selected) => selected)) {
                Get.back();
                await _encryptAndSaveMessage();
              } else {
                Get.snackbar(
                  'error'.tr,
                  'select_at_least_one_recipient'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text('continue'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _encryptAndSaveMessage() async {
    _isProcessing.value = true;

    final messageText = _textController.text.trim();
    final selectedIndexes = _recipientController.getSelectedIndexes();

    if (selectedIndexes.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'select_recipients_warning'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _isProcessing.value = false;
      return;
    }

    try {
      // Garantir um tempo mínimo para o loading
      await Future.delayed(const Duration(milliseconds: 800));

      // Usar DateTime UTC para armazenamento global
      final DateTime currentTimeUTC = DateTime.now().toUtc();

      // Criar a lista de itens criptografados
      final List<EncryptedMessageItem> items = [];

      // Obter a chave pública do usuário para identificar o remetente
      final String userPublicKey = _keyService.publicKey.value;

      // Usar um valor padrão para o remetente caso o usuário não tenha chave
      final String senderKey = userPublicKey.isNotEmpty
          ? userPublicKey
          : "anonymous-${DateTime.now().millisecondsSinceEpoch}";

      print(
          "Chave do remetente: ${senderKey.substring(0, math.min(10, senderKey.length))}...");

      // Para cada chave selecionada, criptografar a mensagem e adicionar à lista
      for (final index in selectedIndexes) {
        final key = _keyService.thirdPartyKeys[index];

        // Verificar se a chave pública do destinatário está vazia
        if (key.publicKey.isEmpty) {
          throw Exception('Recipient public key is empty for ${key.name}');
        }

        print(
            'Criptografando mensagem para ${key.name} com chave: ${key.publicKey.substring(0, math.min(10, key.publicKey.length))}...');

        final encryptedText =
            _keyService.encryptMessage(messageText, key.publicKey);

        items.add(
          EncryptedMessageItem(
            encryptedText: encryptedText,
            createdAt: currentTimeUTC,
          ),
        );
      }

      // Adicionar uma versão criptografada para o próprio usuário, apenas se tiver uma chave pública
      if (userPublicKey.isNotEmpty) {
        print(
            'Criptografando mensagem para o próprio usuário com chave: ${userPublicKey.substring(0, math.min(10, userPublicKey.length))}...');

        // Também usando a chave pública, assim qualquer um com a chave privada correspondente pode descriptografar
        final selfEncryptedText = _keyService.encryptMessage(
          messageText,
          userPublicKey, // Usar a chave pública do usuário para criptografar para si mesmo
        );

        items.add(
          EncryptedMessageItem(
            encryptedText: selfEncryptedText,
            createdAt: currentTimeUTC,
          ),
        );
      } else {
        print(
            'Usuário não possui chave própria, pulando criptografia para si mesmo');
      }

      // Criar e salvar a mensagem criptografada
      final newMessage = EncryptedMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderPublicKey: senderKey,
        items: items,
        createdAt: currentTimeUTC,
        isImported: false,
      );

      await _messageService.addMessage(newMessage);

      // Simplesmente voltar para a HomePage anterior
      Get.back();
    } catch (e) {
      // Mostrar mensagem de erro
      Get.snackbar(
        'error'.tr,
        'error_encrypting_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Error encrypting message: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Método para verificar se o usuário tem chave válida
  void _checkUserHasKey() {
    // Verificar se tem destinatários disponíveis (chaves de terceiros)
    if (_keyService.thirdPartyKeys.isEmpty) {
      print(
          "Não há destinatários disponíveis. Redirecionando para a página de chaves.");
      Get.dialog(
        AlertDialog(
          title: Text('no_recipients_title'.tr),
          content: Text('no_recipients_message'.tr),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.back(); // Volta para a página anterior
              },
              child: Text('close'.tr),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.back(); // Volta para a página anterior
                Get.toNamed('/keys', arguments: {
                  'initialTab': 1
                }); // Navega para a aba de chaves de terceiros
              },
              child: Text('add_recipients'.tr),
            ),
          ],
        ),
        barrierDismissible: false, // Impede fechar clicando fora do diálogo
      );
      return;
    }

    // Apenas verificar se o usuário tem chave própria, mas não bloquear o uso
    if (!_keyService.hasKeys.value || _keyService.publicKey.value.isEmpty) {
      print("Aviso: Usuário não possui chave própria. Exibindo alerta.");
      Get.snackbar(
        'warning'.tr,
        'no_personal_key_warning'.tr,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.amber,
        colorText: Colors.black,
      );
    }
  }
}
