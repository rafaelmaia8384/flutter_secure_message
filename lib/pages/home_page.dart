import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/app_controller.dart';
import '../services/key_service.dart';
import '../services/message_service.dart';
import 'new_message_page.dart';
import 'import_message_page.dart';
import '../models/encrypted_message.dart';
import '../widgets/action_button.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final RxInt _previousMessageCount = 0.obs;
  final MessageService _messageService = Get.put(MessageService());
  final AppController _appController = Get.find<AppController>();
  final KeyService _keyService = Get.find<KeyService>();
  final RxBool _isLoading = false.obs;
  final RxInt _selectedTabIndex = 0.obs; // Track the selected tab index

  @override
  void initState() {
    super.initState();

    // Initialize tab controller with the same ticker provider
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );

    // Set up tab change listener
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        _selectedTabIndex.value = _tabController.index;
      }
    });

    // Inicializar o contador de mensagens
    _previousMessageCount.value = _messageService.messages.length;

    // Carregar mensagens quando a página é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMessagesWithDelay();
      }
    });
  }

  // Método para carregar mensagens com um delay mínimo
  Future<void> _loadMessagesWithDelay() async {
    // Verificar se há mensagens para carregar
    if (_messageService.messages.isNotEmpty) {
      _isLoading.value = true;

      // Executar o carregamento de mensagens e registrar o tempo de início
      final startTime = DateTime.now();
      await _messageService.loadMessages();

      // Calcular quanto tempo passou desde o início do carregamento
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;

      // Se o carregamento foi mais rápido que 1 segundo (1000ms), aguardar o tempo restante
      if (elapsedTime < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - elapsedTime));
      }

      _isLoading.value = false;
      _previousMessageCount.value = _messageService.messages.length;
    } else {
      // Se não houver mensagens, apenas carregar sem mostrar indicador
      await _messageService.loadMessages();
      _previousMessageCount.value = _messageService.messages.length;
    }
  }

  @override
  void dispose() {
    // Dispose tab controller
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'created_messages'.tr, icon: Icon(Icons.create)),
            Tab(text: 'imported_messages'.tr, icon: Icon(Icons.download)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Created Messages Tab with its own action button
          _buildTabWithActionButton(
            isImported: false,
            actionButton: ActionButton(
              label: 'new_message'.tr,
              icon: Icons.create,
              onPressed: () => _createNewMessage(),
            ),
          ),
          // Imported Messages Tab with its own action button
          _buildTabWithActionButton(
            isImported: true,
            actionButton: ActionButton(
              label: 'import_message'.tr,
              icon: Icons.download,
              onPressed: () => _handleImportMessage(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a tab with its own action button
  Widget _buildTabWithActionButton({
    required bool isImported,
    required Widget actionButton,
  }) {
    return Column(
      children: [
        Expanded(child: _buildMessagesTab(isImported)),
        actionButton,
      ],
    );
  }

  // Helper method to create new message
  void _createNewMessage() {
    Get.to(() => const NewMessagePage())?.then((result) async {
      // Only reload if a new message was created (result is true)
      if (result == true) {
        await _messageService.loadMessages();
      }
    });
  }

  // Widget to build the content of each tab
  Widget _buildMessagesTab(bool isImported) {
    return Obx(() {
      // Se estiver carregando, mostrar o indicador de progresso
      if (_isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'loading_messages'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      // Filter messages based on tab
      final filteredMessages = _messageService.messages
          .where((msg) => msg.isImported == isImported)
          .toList();

      if (filteredMessages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isImported ? Icons.download_outlined : Icons.create_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isImported
                    ? 'no_imported_messages'.tr
                    : 'no_created_messages'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isImported
                      ? 'no_imported_messages_description'.tr
                      : 'no_created_messages_description'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Sort by creation date (newest first)
      filteredMessages.sort((a, b) {
        // Primary sorting by creation date (newest first)
        int dateComparison = b.createdAt.compareTo(a.createdAt);

        // If dates are the same, use message ID to ensure consistent ordering
        return dateComparison != 0 ? dateComparison : b.id.compareTo(a.id);
      });

      return ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final message = filteredMessages[index];
          // Using FutureBuilder to handle the async decryption
          return FutureBuilder<Widget>(
            future: _buildChatBubbleAsync(message),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a placeholder or loading indicator while decrypting
                return Container();
              } else if (snapshot.hasError) {
                // Show error state if decryption fails
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('error_decrypting'.tr),
                  ),
                );
              } else {
                // Return the built bubble widget
                return snapshot.data ?? Container();
              }
            },
          );
        },
      );
    });
  }

  // Async version of chat bubble builder
  Future<Widget> _buildChatBubbleAsync(EncryptedMessage message) async {
    // Formata a data de criação da mensagem
    final dateFormat = _formatDate(message.createdAt);

    // Obtém o nome do remetente da mensagem
    bool isOwnMessage = message.senderPublicKey == _keyService.publicKey.value;

    String senderName;
    if (isOwnMessage) {
      senderName = 'me'.tr;
    } else {
      // Procurar nas chaves de terceiros pelo senderPublicKey (case insensitive)
      int keyIndex = _keyService.thirdPartyKeys
          .indexWhere((key) => key.publicKey == message.senderPublicKey);

      if (keyIndex >= 0) {
        // Se encontrou a chave, usar o nome do contato
        senderName = _keyService.thirdPartyKeys[keyIndex].name;
      } else {
        // Se não encontrou, usar "Contato Desconhecido"
        senderName = 'message_from_unknown'.tr;
      }
    }

    // Lógica para mostrar o conteúdo da mensagem
    String displayedText = '';
    String errorMessage = '';

    // Se a mensagem tem texto em plainText, mostrar diretamente
    if (message.plainText.isNotEmpty) {
      displayedText = message.plainText;
    }
    // Senão, tentar descriptografar se tiver items
    else if (message.items.isNotEmpty) {
      try {
        final userPrivateKey = _keyService.privateKey.value;

        // Tenta descriptografar cada item da mensagem
        bool decryptionSuccess = false;

        for (var item in message.items) {
          try {
            final decryptedContentFuture = _keyService.tryDecryptMessage(
                item.encryptedText, userPrivateKey);

            // Await the Future to get the actual string value
            final decryptedContent = await decryptedContentFuture;

            if (decryptedContent != null) {
              displayedText = decryptedContent;
              decryptionSuccess = true;
              break;
            }
          } catch (e) {
            print('Error decrypting item: $e');
          }
        }

        if (!decryptionSuccess) {
          errorMessage = 'message_not_for_you'.tr;
        }
      } catch (e) {
        errorMessage = 'error_decrypting'.tr;
      }
    } else {
      // Caso especial: mensagem sem texto e sem items
      errorMessage = 'empty_message'.tr;
    }

    // Calcula o número de terceiros autorizados - pode ser 0
    final thirdPartyCount = message.items.length - (isOwnMessage ? 1 : 0);
    final thirdPartyCountText =
        thirdPartyCount < 0 ? "0" : thirdPartyCount.toString();

    // Determina a posição do bubble com base no remetente
    final isFromMe = isOwnMessage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Conteúdo do bubble sempre à esquerda
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFromMe
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
                        senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isFromMe
                              ? Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Mensagem descriptografada ou erro
                      errorMessage.isNotEmpty
                          ? Text(
                              errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Text(
                              displayedText,
                              style: TextStyle(
                                color: isFromMe
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
                            dateFormat,
                            style: TextStyle(
                              fontSize: 10,
                              color: isFromMe
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
                            color: isFromMe
                                ? Colors.white70
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            thirdPartyCountText,
                            style: TextStyle(
                              fontSize: 10,
                              color: isFromMe
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
                onPressed: () => _shareMessage(message),
                padding: const EdgeInsets.all(8),
              ),

              // Botão de excluir
              IconButton(
                icon: const Icon(Icons.delete_forever, size: 20),
                onPressed: () => _deleteMessage(message),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Original synchronous method is kept for compatibility but won't be used
  Widget _buildChatBubble(EncryptedMessage message) {
    // This is just a wrapper that returns a placeholder -
    // the actual implementation is in _buildChatBubbleAsync
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text('Synchronous version deprecated'),
    );
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

  // Compartilhar uma mensagem
  void _shareMessage(EncryptedMessage message) async {
    // Se a mensagem não tem texto original, mostra erro
    if (message.plainText.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'no_message_content'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Log para debug - verificar estado atual da mensagem
    print("\n======== COMPARTILHANDO MENSAGEM ========");
    print("ID: ${message.id}");
    print(
        "Texto original: ${message.plainText.substring(0, math.min(20, message.plainText.length))}...");
    print("Importada: ${message.isImported}");
    print("Número de itens criptografados: ${message.items.length}");
    if (message.items.isNotEmpty) {
      print("Itens existentes serão substituídos por novos");
    }
    print("=========================================\n");

    // Inicializar lista de seleção de destinatários
    List<String> selectedKeys = [];

    // Se a mensagem for importada, compartilha diretamente
    if (message.isImported) {
      final shareable = await _messageService.compactMessageForSharing(message);
      await Share.share(shareable);
      return;
    }

    // Para mensagens não importadas, SEMPRE mostra diálogo de seleção
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

      // Criar lista vazia para os novos itens criptografados
      // (substitui os itens antigos, em vez de adicionar aos existentes)
      final List<EncryptedMessageItem> encryptedItems = [];

      try {
        // Criptografar para cada destinatário selecionado
        for (final publicKey in value) {
          final encryptedText = await _keyService.encryptMessage(
            message.plainText,
            publicKey,
          );

          if (encryptedText != null) {
            encryptedItems.add(EncryptedMessageItem(
              encryptedText: encryptedText,
              createdAt: DateTime.now().toUtc(),
            ));
          }
        }

        // Criar cópia da mensagem com itens atualizados
        final updatedMessage = EncryptedMessage(
          id: message.id,
          plainText: message.plainText,
          createdAt: message.createdAt,
          isImported: message.isImported,
          senderPublicKey: message.senderPublicKey,
          items: encryptedItems,
        );

        // Atualizar na lista de mensagens
        await _messageService.updateMessage(updatedMessage);

        // Registrar a atualização da mensagem e compartilhar
        print(
            "Mensagem atualizada com ${encryptedItems.length} novos itens criptografados");
        final shareable =
            await _messageService.compactMessageForSharing(updatedMessage);
        await Share.share(shareable);
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'error_encrypting'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        print('Erro ao criptografar: $e');
      }
    });
  }

  // Excluir uma mensagem
  void _deleteMessage(EncryptedMessage message) async {
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
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _messageService.deleteMessage(message.id);

        Get.snackbar(
          'success'.tr,
          'message_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
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

  // Método para lidar com a importação de mensagens
  void _handleImportMessage() {
    // Verificar se o usuário possui chave antes de importar
    if (!_keyService.hasKeys.value) {
      // Se não possuir chave própria, mostrar mensagem de aviso
      Get.dialog(
        AlertDialog(
          title: Text('no_public_key_title'.tr),
          content: Text('need_public_key_for_import'.tr),
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
    } else {
      // Se possuir chave própria, prosseguir com a importação
      Get.to(() => const ImportMessagePage())?.then((result) async {
        // Only reload if a new message was imported (result is true)
        if (result == true) {
          await _messageService.loadMessages();
        }
      });
    }
  }
}
