import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/key_service.dart';
import '../services/message_service.dart';
import '../models/encrypted_message.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'message_detail_page.dart';

class ImportMessagePage extends StatefulWidget {
  const ImportMessagePage({super.key});

  @override
  State<ImportMessagePage> createState() => _ImportMessagePageState();
}

class _ImportMessagePageState extends State<ImportMessagePage> {
  final TextEditingController _textController = TextEditingController();
  final RxBool _hasText = false.obs;
  final RxBool _isProcessing = false.obs;
  final KeyService _keyService = Get.find<KeyService>();
  final MessageService _messageService = Get.find<MessageService>();
  final RxString _errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateHasText);

    // Verificar se o usuário tem chave ao iniciar a página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserHasKey();
    });
  }

  // Método para verificar se o usuário tem chave
  void _checkUserHasKey() {
    if (!_keyService.hasKeys.value) {
      Get.dialog(
        AlertDialog(
          title: Text('no_public_key_title'.tr),
          content: Text('need_public_key_for_import'.tr),
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
                Get.toNamed('/keys'); // Navega para a página de chaves
              },
              child: Text('generate_key'.tr),
            ),
          ],
        ),
        barrierDismissible: false, // Impede fechar clicando fora do diálogo
      );
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_updateHasText);
    _textController.dispose();
    super.dispose();
  }

  void _updateHasText() {
    _hasText.value = _textController.text.trim().isNotEmpty;
  }

  Future<void> _importMessage() async {
    // Fechar o teclado e remover o foco
    FocusManager.instance.primaryFocus?.unfocus();

    _isProcessing.value = true;
    _errorMessage.value = '';

    try {
      // Garantir um tempo mínimo para o loading
      await Future.delayed(const Duration(milliseconds: 800));

      String inputText = _textController.text.trim();

      print('Iniciando importação de mensagem...');
      print('Tamanho do texto: ${inputText.length} caracteres');

      // Usar o método centralizado para extrair a mensagem
      final message = _messageService.extractMessageFromSharedString(inputText);

      if (message == null) {
        _errorMessage.value = 'invalid_message_format'.tr;
        _isProcessing.value = false;
        print('Mensagem inválida: não foi possível extrair');
        return;
      }

      print('Mensagem extraída com sucesso!');
      print('ID da mensagem: ${message.id}');
      print('Remetente: ${message.senderPublicKey}');
      print('Total de itens: ${message.items.length}');

      final userPublicKey = _keyService.publicKey.value;
      print(
          'Chave pública do usuário: ${userPublicKey.substring(0, math.min(10, userPublicKey.length))}...');
      print('Tamanho da chave privada: ${_keyService.privateKey.value.length}');
      print('Mensagem própria? ${message.senderPublicKey == userPublicKey}');

      // Tentar descriptografar pelo menos um item para verificar se é válido
      bool canDecrypt = false;
      final userPrivateKey = _keyService.privateKey.value;
      int attemptCount = 0;

      print('Iniciando tentativas de descriptografia...');

      for (var item in message.items) {
        attemptCount++;
        print('Tentativa $attemptCount: item de ${item.createdAt}');
        print('Tamanho do texto criptografado: ${item.encryptedText.length}');

        try {
          final decryptedContent =
              _keyService.tryDecryptMessage(item.encryptedText, userPrivateKey);

          if (decryptedContent != null) {
            print(
                'Descriptografia bem-sucedida! Conteúdo: ${decryptedContent.substring(0, math.min(20, decryptedContent.length))}...');
            canDecrypt = true;
            break;
          } else {
            print('Falha na descriptografia do item $attemptCount');
          }
        } catch (e) {
          print('Erro na tentativa $attemptCount: $e');
        }
      }

      if (!canDecrypt) {
        _errorMessage.value = 'message_not_for_you'.tr;
        print(
            'Falha em todas as tentativas de descriptografia. Esta mensagem não foi criptografada para você.');
        _isProcessing.value = false;
        return;
      }

      print('Mensagem pode ser descriptografada. Adicionando à lista...');
      // Adicionar a mensagem à lista
      await _messageService.addMessage(message);

      _isProcessing.value = false;
      print('Mensagem importada com sucesso!');

      // Navegar para a página de detalhes e, quando ela for fechada, voltar para HomePage
      Get.off(() => MessageDetailPage(message: message),
          popGesture: true, transition: Transition.rightToLeft);
    } catch (e) {
      if (e.toString().contains('Invalid message structure')) {
        _errorMessage.value = 'invalid_message_structure'.tr;
      } else if (e.toString().contains('FormatException')) {
        _errorMessage.value = 'invalid_message_format'.tr;
      } else {
        _errorMessage.value = 'error_importing_message'.tr;
      }
      print('Erro ao importar mensagem: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('import_message'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(() => TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    enabled: !_isProcessing.value,
                    decoration: InputDecoration(
                      hintText: 'enter_encrypted_message'.tr,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )),
            ),
            Obx(() => _errorMessage.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(() => ElevatedButton(
                    onPressed: _hasText.value && !_isProcessing.value
                        ? _importMessage
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
                        : Text('import'.tr),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
