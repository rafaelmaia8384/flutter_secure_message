import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/encrypted_message.dart';
import '../services/key_service.dart';

class MessageBubble extends StatefulWidget {
  final EncryptedMessage message;
  final KeyService keyService;
  final Function(EncryptedMessage) onShare;
  final Function(EncryptedMessage) onDelete;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.keyService,
    required this.onShare,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String _displayedText = '';
  String _errorMessage = '';
  String _senderName = '';
  bool _isFromMe = false;
  String _formattedDate = '';
  String _thirdPartyCountText = '0';

  @override
  void initState() {
    super.initState();
    _decryptMessage();
  }

  // Formata a data da mensagem (converte de UTC para local e usa o locale do dispositivo)
  String _formatDate(DateTime utcDate) {
    // Converter de UTC para hora local
    final DateTime localDate = utcDate.toLocal();

    // Usar o locale do dispositivo para formatar a data
    final locale = Get.locale?.toString() ?? 'en_US';
    final DateFormat dateFormat = DateFormat.yMd(locale).add_Hm();

    return dateFormat.format(localDate);
  }

  Future<void> _decryptMessage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Formata a data de criação da mensagem
      _formattedDate = _formatDate(widget.message.createdAt);

      // Obtém o nome do remetente da mensagem
      _isFromMe =
          widget.message.senderPublicKey == widget.keyService.publicKey.value;

      if (_isFromMe) {
        _senderName = 'me'.tr;
      } else {
        // Procurar nas chaves de terceiros pelo senderPublicKey
        int keyIndex = widget.keyService.thirdPartyKeys.indexWhere(
            (key) => key.publicKey == widget.message.senderPublicKey);

        if (keyIndex >= 0) {
          // Se encontrou a chave, usar o nome do contato
          _senderName = widget.keyService.thirdPartyKeys[keyIndex].name;
        } else {
          // Se não encontrou, usar "Contato Desconhecido"
          _senderName = 'message_from_unknown'.tr;
        }
      }

      // Calcula o número de terceiros autorizados
      final thirdPartyCount = widget.message.items.length - (_isFromMe ? 1 : 0);
      _thirdPartyCountText =
          thirdPartyCount < 0 ? "0" : thirdPartyCount.toString();

      // Se a mensagem tem texto em plainText, mostrar diretamente
      if (widget.message.plainText.isNotEmpty) {
        _displayedText = widget.message.plainText;
        _errorMessage = '';
      }
      // Senão, tentar descriptografar se tiver items
      else if (widget.message.items.isNotEmpty) {
        try {
          final userPrivateKey = widget.keyService.privateKey.value;

          // Tenta descriptografar cada item da mensagem
          bool decryptionSuccess = false;

          for (var item in widget.message.items) {
            try {
              final decryptedContent = await widget.keyService
                  .tryDecryptMessage(item.encryptedText, userPrivateKey);

              if (decryptedContent != null) {
                _displayedText = decryptedContent;
                _errorMessage = '';
                decryptionSuccess = true;
                break;
              }
            } catch (e) {
              print('Error decrypting item: $e');
            }
          }

          if (!decryptionSuccess) {
            _errorMessage = 'message_not_for_you'.tr;
            _displayedText = '';
          }
        } catch (e) {
          _errorMessage = 'error_decrypting'.tr;
          _displayedText = '';
        }
      } else {
        // Caso especial: mensagem sem texto e sem items
        _errorMessage = 'empty_message'.tr;
        _displayedText = '';
      }
    } catch (e) {
      _errorMessage = 'error_decrypting'.tr;
      _displayedText = '';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Conteúdo do bubble sempre à esquerda
          Expanded(
            child: Column(
              crossAxisAlignment:
                  _isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isFromMe
                        ? Colors.blue[700]
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Remetente
                      Text(
                        _senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isFromMe
                              ? Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Mensagem descriptografada ou erro
                      _errorMessage.isNotEmpty
                          ? Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Text(
                              _displayedText,
                              style: TextStyle(
                                color: _isFromMe
                                    ? Colors.white
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),

                      // Informações adicionais
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Data de criação
                          Text(
                            _formattedDate,
                            style: TextStyle(
                              fontSize: 10,
                              color: _isFromMe
                                  ? Colors.white70
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Número de terceiros autorizados
                          Icon(
                            Icons.people,
                            size: 12,
                            color: _isFromMe
                                ? Colors.white70
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _thirdPartyCountText,
                            style: TextStyle(
                              fontSize: 10,
                              color: _isFromMe
                                  ? Colors.white70
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botões de ação verticais
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão de compartilhar
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                onPressed: () => widget.onShare(widget.message),
                padding: const EdgeInsets.all(8),
              ),

              // Botão de excluir
              IconButton(
                icon: const Icon(Icons.delete_forever, size: 20),
                onPressed: () => widget.onDelete(widget.message),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
