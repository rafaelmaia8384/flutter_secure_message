import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../models/encrypted_message.dart';
import '../services/key_service.dart';
import '../services/message_service.dart';
import '../widgets/action_button.dart';
import 'package:intl/intl.dart';

class MessageDetailPage extends StatelessWidget {
  final EncryptedMessage message;

  const MessageDetailPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final KeyService _keyService = Get.find<KeyService>();
    String decryptedMessage = '';
    String errorMessage = '';
    bool isOwnMessage = false;

    try {
      // Get the user's keys
      final userPrivateKey = _keyService.privateKey.value;
      final userPublicKey = _keyService.publicKey.value;

      print('Message has ${message.items.length} encrypted items');
      print('Message sender: ${message.senderPublicKey}');
      print(
          'Current user public key: ${userPublicKey.length > 20 ? userPublicKey.substring(0, 20) + "..." : userPublicKey}');
      print('Private key length: ${userPrivateKey.length}');

      // Verificar se é uma mensagem enviada pelo próprio usuário
      isOwnMessage = message.senderPublicKey == userPublicKey;
      print('Is own message: $isOwnMessage');

      // Tenta descriptografar cada item da mensagem com a chave privada do usuário
      bool decryptionSuccess = false;
      int attemptCount = 0;

      for (var item in message.items) {
        attemptCount++;
        print(
            'Attempt $attemptCount: trying to decrypt item from ${item.createdAt}');
        print('Encrypted text length: ${item.encryptedText.length}');

        try {
          final decryptedContent =
              _keyService.tryDecryptMessage(item.encryptedText, userPrivateKey);

          if (decryptedContent != null) {
            // Se a descriptografia funcionou (encontrou o identificador), use esta mensagem
            decryptedMessage = decryptedContent;
            decryptionSuccess = true;
            print('Successfully decrypted message from ${item.createdAt}');
            break;
          } else {
            print(
                'Failed to decrypt item $attemptCount - No valid identifier found');
          }
        } catch (e) {
          print('Error during decryption attempt $attemptCount: $e');
        }
      }

      if (!decryptionSuccess) {
        errorMessage = 'message_not_for_you'.tr;
        print('Failed to decrypt any items in the message');
      }
    } catch (e) {
      print('Error decrypting message: $e');
      errorMessage = 'error_decrypting'.tr;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('message_detail'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Se a rota anterior for a ImportMessagePage, navegue para HomePage
            if (Get.previousRoute.contains('ImportMessagePage')) {
              Get.offAllNamed('/home');
            } else {
              // Caso contrário, volte normalmente
              Get.back();
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'message_id'.tr + ': ${message.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'created_at'.tr + ': ${_formatDate(message.createdAt)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'authorized_third_parties'.tr +
                        ': ${message.items.length - 1}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'sender'.tr +
                        ': ' +
                        _getSenderName(
                            message.senderPublicKey, isOwnMessage, _keyService),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOwnMessage ? Colors.green : Colors.blue,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'message_content'.tr + ':',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: errorMessage.isNotEmpty
                          ? Center(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Text(decryptedMessage),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botões de ação na parte inferior
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Theme.of(context).platform == TargetPlatform.iOS
                        ? const Icon(Icons.ios_share)
                        : const Icon(Icons.share),
                    label: Text('export_message'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showExportDialog(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: Text('delete'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _deleteMessage(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(DateTime utcDate) {
    // Converter de UTC para hora local
    final DateTime localDate = utcDate.toLocal();

    // Usar o locale do dispositivo para formatar a data
    final locale = Get.locale?.toString() ?? 'en_US';
    final DateFormat dateFormat = DateFormat.yMd(locale).add_Hm();

    return dateFormat.format(localDate);
  }

  // Método para obter o nome do remetente
  String _getSenderName(
      String senderPublicKey, bool isOwnMessage, KeyService keyService) {
    if (isOwnMessage) {
      return 'me'.tr;
    } else {
      // Procurar nas chaves de terceiros pelo senderPublicKey
      int keyIndex = keyService.thirdPartyKeys
          .indexWhere((key) => key.publicKey == senderPublicKey);

      if (keyIndex >= 0) {
        // Se encontrou a chave, usar o nome do contato
        return keyService.thirdPartyKeys[keyIndex].name;
      } else {
        // Se não encontrou, usar "Contato Desconhecido"
        return 'message_from_unknown'.tr;
      }
    }
  }

  Future<void> _deleteMessage(BuildContext context) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_message_title'.tr),
        content: Text('delete_message_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final messageService = Get.find<MessageService>();
        await messageService.deleteMessage(message.id);

        // Mostra a mensagem de sucesso
        Get.snackbar(
          'success'.tr,
          'message_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Volta para a HomePage ao excluir a mensagem
        Get.offAllNamed('/home');
      } catch (e) {
        print('Error deleting message: $e');
        Get.snackbar(
          'error'.tr,
          'error_deleting_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    try {
      final messageService = Get.find<MessageService>();
      final exportString = messageService.compactMessageForSharing(message);

      // Compartilhar diretamente usando share_plus
      await Share.share(
        exportString,
        subject: 'Encrypted Message',
      );
    } catch (e) {
      // Mostrar mensagem de erro em caso de falha
      Get.snackbar(
        'error'.tr,
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
