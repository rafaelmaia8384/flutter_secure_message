import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/key_service.dart';
import '../models/encrypted_message.dart';
import 'dart:convert';

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

  Future<void> _decryptMessage() async {
    // Fechar o teclado e remover o foco
    FocusManager.instance.primaryFocus?.unfocus();

    _isProcessing.value = true;
    _errorMessage.value = '';

    try {
      // Garantir um tempo mínimo para o loading
      await Future.delayed(const Duration(milliseconds: 800));

      String inputText = _textController.text.trim();

      print('Iniciando descriptografia de mensagem...');
      print('Tamanho do texto: ${inputText.length} caracteres');

      // Extrair a mensagem do texto compartilhado
      final message = _extractMessageFromSharedString(inputText);

      if (message == null) {
        _errorMessage.value = 'invalid_message_format'.tr;
        _isProcessing.value = false;
        print('Mensagem inválida: não foi possível extrair');
        return;
      }

      print('Mensagem extraída com sucesso!');
      print('Remetente: ${message.senderPublicKey}');
      print('Total de itens: ${message.items.length}');

      final userPrivateKey = _keyService.privateKey.value;

      // Tentar descriptografar cada item até encontrar um que funcione
      String? decryptedContent;

      for (var item in message.items) {
        try {
          final attemptDecrypted = await _keyService.tryDecryptMessage(
              item.encryptedText, userPrivateKey);

          if (attemptDecrypted != null) {
            decryptedContent = attemptDecrypted;
            break;
          }
        } catch (e) {
          print('Erro ao tentar descriptografar item: $e');
        }
      }

      if (decryptedContent == null) {
        _errorMessage.value = 'message_not_for_you'.tr;
        print(
            'Falha em todas as tentativas de descriptografia. Esta mensagem não foi criptografada para você.');
        return;
      }

      // Mostrar conteúdo descriptografado em um diálogo
      _showDecryptedMessage(decryptedContent);
    } catch (e) {
      if (e.toString().contains('Invalid message structure')) {
        _errorMessage.value = 'invalid_message_structure'.tr;
      } else if (e.toString().contains('FormatException')) {
        _errorMessage.value = 'invalid_message_format'.tr;
      } else {
        _errorMessage.value = 'error_decrypting_message'.tr;
      }
      print('Erro ao descriptografar mensagem: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  void _showDecryptedMessage(String content) {
    Get.dialog(
      AlertDialog(
        scrollable: true,
        title: Text('decrypted_message'.tr),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 18,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  // Método para extrair uma mensagem de uma string compartilhada
  EncryptedMessage? _extractMessageFromSharedString(String sharedString) {
    try {
      // Limpar a string, removendo espaços, quebras de linha e outros caracteres não visíveis
      String cleanedString = sharedString.trim();

      // Logs para ajudar na depuração
      print('Tentando extrair mensagem de string compartilhada...');
      print('Comprimento original: ${sharedString.length}');
      print('Comprimento após limpeza: ${cleanedString.length}');

      String jsonString;
      Map<String, dynamic> messageJson;

      if (cleanedString.startsWith("sec-msg:")) {
        // Formato otimizado
        String base64String = cleanedString.substring("sec-msg:".length);

        try {
          // Decodificar o base64
          List<int> decodedBytes = base64Decode(base64String);
          jsonString = utf8.decode(decodedBytes);

          // Analisar o JSON compacto
          final Map<String, dynamic> compactJson = json.decode(jsonString);
          print(
              'JSON compacto decodificado com sucesso. Chaves: ${compactJson.keys.join(", ")}');

          // Converter para o formato padrão
          messageJson = {
            'senderPublicKey':
                compactJson.containsKey('s') ? compactJson['s'] : 'anonymous',
            'items': (compactJson['t'] as List)
                .map((item) => {
                      'encryptedText': item['e'],
                    })
                .toList(),
          };
        } catch (e) {
          print('Erro na decodificação: $e');
          throw FormatException('Erro na decodificação: $e');
        }
      } else {
        return null;
      }

      // Verificar estrutura básica do JSON antes de tentar criar o objeto
      if (!messageJson.containsKey('senderPublicKey')) {
        print(
            'Estrutura de JSON inválida. Chaves presentes: ${messageJson.keys.join(", ")}');
        return null;
      }

      try {
        // Criar objeto EncryptedMessage a partir do JSON
        final message = EncryptedMessage.fromJson(messageJson);
        print('Objeto EncryptedMessage criado com sucesso.');
        if (message.items.isNotEmpty) {
          print('A mensagem tem ${message.items.length} itens');
        }
        return message;
      } catch (e) {
        print('Erro ao criar objeto EncryptedMessage: $e');
        return null;
      }
    } catch (e) {
      print('Erro geral ao extrair mensagem: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('import_message'.tr),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
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
                child: Obx(() => ElevatedButton(
                      onPressed: _hasText.value && !_isProcessing.value
                          ? _decryptMessage
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
                          : Text('Decrypt Message'),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
