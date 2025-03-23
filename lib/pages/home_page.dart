import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../controllers/app_controller.dart';
import '../services/key_service.dart';
import '../services/message_service.dart';
import 'new_message_page.dart';
import 'import_message_page.dart';
import '../models/encrypted_message.dart';
import '../widgets/action_button.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  final RxInt _previousMessageCount = 0.obs;
  final MessageService _messageService = Get.put(MessageService());
  final AppController _appController = Get.find<AppController>();
  final KeyService _keyService = Get.find<KeyService>();
  Worker? _animationWorker;
  final RxBool _isLoading = false.obs;
  final RxInt _selectedTabIndex = 0.obs; // Track the selected tab index

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize the tab controller with the same ticker provider
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

    // Iniciar a animação quando a página é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMessagesWithDelay();
        _animationController.forward();
      }
    });

    // Observar mudanças na variável shouldAnimateNewMessages
    _animationWorker =
        ever(_appController.shouldAnimateNewMessages, (shouldAnimate) {
      if (shouldAnimate && mounted) {
        _animationController.reset();
        _animationController.forward();
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

      // Atualizar o contador e animar se novas mensagens foram carregadas
      if (_messageService.messages.length > _previousMessageCount.value) {
        _previousMessageCount.value = _messageService.messages.length;
        _appController.triggerMessageAnimation();
      }
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

    // Remover o listener antes de descartar o controller
    _animationWorker?.dispose();

    // Garantir que a animação seja interrompida antes de descartar
    _animationController.stop();
    _animationController.dispose();
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
    // Check if user has third-party keys
    if (_keyService.thirdPartyKeys.isEmpty) {
      Get.dialog(
        AlertDialog(
          title: Text('no_third_party_keys_title'.tr),
          content: Text('no_third_party_keys_message'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('close'.tr),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/keys', arguments: {'initialTab': 1});
              },
              child: Text('add_third_party_key'.tr),
            ),
          ],
        ),
      );
    } else {
      Get.to(() => const NewMessagePage())?.then((_) async {
        await _loadMessagesWithDelay();
      });
    }
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

      // Verificar se novas mensagens foram adicionadas desde a última verificação
      if (_messageService.messages.length > _previousMessageCount.value) {
        // Como há novas mensagens, atualizar a contagem e sinalizar para animar
        _previousMessageCount.value = _messageService.messages.length;
        _appController.triggerMessageAnimation();
      } else {
        // Apenas atualizar o contador
        _previousMessageCount.value = _messageService.messages.length;
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
      filteredMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return RefreshIndicator(
        onRefresh: _loadMessagesWithDelay,
        child: ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: filteredMessages.length,
          itemBuilder: (context, index) {
            final message = filteredMessages[index];

            // Animation logic
            if (!_appController.shouldAnimateNewMessages.value ||
                !mounted ||
                _animationController.status == AnimationStatus.dismissed) {
              return _buildChatBubble(message);
            }

            // Last item added should animate
            if (index == 0 && _appController.shouldAnimateNewMessages.value) {
              return AnimatedItemWidget(
                controller: _animationController,
                startInterval: 0.0,
                child: _buildChatBubble(message),
              );
            }

            return _buildChatBubble(message);
          },
        ),
      );
    });
  }

  Widget _buildChatBubble(EncryptedMessage message) {
    // Formata a data de criação da mensagem
    final dateFormat = _formatDate(message.createdAt);

    // Obtém o nome do remetente da mensagem
    bool isOwnMessage = message.senderPublicKey == _keyService.publicKey.value;

    String senderName;
    if (isOwnMessage) {
      senderName = 'me'.tr;
    } else {
      // Procurar nas chaves de terceiros pelo senderPublicKey
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

    // Tenta descriptografar a mensagem
    String decryptedMessage = '';
    String errorMessage = '';

    try {
      final userPrivateKey = _keyService.privateKey.value;

      // Tenta descriptografar cada item da mensagem
      bool decryptionSuccess = false;

      for (var item in message.items) {
        try {
          final decryptedContent =
              _keyService.tryDecryptMessage(item.encryptedText, userPrivateKey);

          if (decryptedContent != null) {
            decryptedMessage = decryptedContent;
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

    // Calcula o número de terceiros autorizados - 1
    final thirdPartyCount = message.items.length - 1;

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
                              decryptedMessage,
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
                            thirdPartyCount.toString(),
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
                // constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                // visualDensity: VisualDensity.compact,
              ),

              // Botão de excluir
              IconButton(
                icon: const Icon(Icons.delete_forever, size: 20),
                onPressed: () => _deleteMessage(message),
                // constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                // visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
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
    try {
      final messageService = Get.find<MessageService>();
      final exportString = messageService.compactMessageForSharing(message);

      // Compartilhar diretamente usando share_plus
      await Share.share(
        exportString,
        subject: 'Encrypted Message',
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
      Get.to(() => const ImportMessagePage());
    }
  }
}

// Widget que anima a entrada de um item na lista
class AnimatedItemWidget extends StatelessWidget {
  final AnimationController controller;
  final Widget child;
  final double startInterval;

  const AnimatedItemWidget({
    Key? key,
    required this.controller,
    required this.child,
    this.startInterval = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar se o controller ainda está ativo
    if (!controller.isAnimating &&
        controller.status == AnimationStatus.dismissed) {
      return child;
    }

    // Criar uma animação que começa após o intervalo definido
    // e termina um pouco depois
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        startInterval, // Início da animação (0.0 a 1.0)
        startInterval + 0.4, // Fim da animação (startInterval + duração)
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0.0, 30 * (1.0 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
