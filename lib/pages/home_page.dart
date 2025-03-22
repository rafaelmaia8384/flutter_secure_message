import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../controllers/app_controller.dart';
import '../services/key_service.dart';
import '../services/message_service.dart';
import 'new_message_page.dart';
import 'message_detail_page.dart';
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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final RxInt _previousMessageCount = 0.obs;
  final MessageService _messageService = Get.put(MessageService());
  final AppController _appController = Get.find<AppController>();
  final KeyService _keyService = Get.find<KeyService>();
  Worker? _animationWorker;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Inicializar o contador de mensagens
    _previousMessageCount.value = _messageService.messages.length;

    // Iniciar a animação quando a página é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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

  @override
  void dispose() {
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
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              // Verificar se novas mensagens foram adicionadas desde a última verificação
              if (_messageService.messages.length >
                  _previousMessageCount.value) {
                // Como há novas mensagens, atualizar a contagem e sinalizar para animar
                _previousMessageCount.value = _messageService.messages.length;
                _appController.triggerMessageAnimation();
              } else {
                // Apenas atualizar o contador
                _previousMessageCount.value = _messageService.messages.length;
              }

              if (_messageService.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_messages'.tr,
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
                          'no_messages_description'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final option = await _showMessageOptionsDialog();
                          if (option == 'create') {
                            // Check if user has third-party keys
                            if (_keyService.thirdPartyKeys.isEmpty) {
                              Get.dialog(
                                AlertDialog(
                                  title: Text('no_third_party_keys_title'.tr),
                                  content:
                                      Text('no_third_party_keys_message'.tr),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text('close'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        Get.toNamed('/keys',
                                            arguments: {'initialTab': 1});
                                      },
                                      child: Text('add_third_party_key'.tr),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Get.to(() => const NewMessagePage())
                                  ?.then((_) async {
                                await _messageService.loadMessages();
                                if (_messageService.messages.length >
                                    _previousMessageCount.value) {
                                  _previousMessageCount.value =
                                      _messageService.messages.length;
                                  _appController.triggerMessageAnimation();
                                }
                              });
                            }
                          } else if (option == 'import') {
                            _handleImportMessage();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: Text('start_messaging'.tr),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Criar uma lista ordenada por data de criação (mais recentes primeiro)
              final sortedMessages = _messageService.messages.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return ListView.builder(
                itemCount: sortedMessages.length,
                itemBuilder: (context, index) {
                  final message = sortedMessages[index];

                  // Se não estiver animando ou o controller não estiver em estado válido, retornar o card sem animação
                  if (!_appController.shouldAnimateNewMessages.value ||
                      !mounted ||
                      _animationController.status ==
                          AnimationStatus.dismissed) {
                    return _buildMessageCard(message);
                  }

                  // Calcular a duração do atraso baseado no índice
                  // para criar um efeito de cascata
                  final delay = index * 0.2;
                  final start = 0.2 + delay > 0.9 ? 0.9 : 0.2 + delay;

                  // Criar uma animação personalizada para cada item
                  return AnimatedItemWidget(
                    controller: _animationController,
                    startInterval: start,
                    child: _buildMessageCard(message),
                  );
                },
              );
            }),
          ),
          // Botão de ação na parte inferior
          Obx(() => _messageService.messages.isNotEmpty
              ? ActionButton(
                  label: 'message_options'.tr,
                  icon: Icons.add,
                  onPressed: () async {
                    final option = await _showMessageOptionsDialog();
                    if (option == 'create') {
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
                                  Get.toNamed('/keys',
                                      arguments: {'initialTab': 1});
                                },
                                child: Text('add_third_party_key'.tr),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Get.to(() => const NewMessagePage())?.then((_) async {
                          await _messageService.loadMessages();
                          if (_messageService.messages.length >
                              _previousMessageCount.value) {
                            _previousMessageCount.value =
                                _messageService.messages.length;
                            _appController.triggerMessageAnimation();
                          }
                        });
                      }
                    } else if (option == 'import') {
                      _handleImportMessage();
                    }
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildMessageCard(EncryptedMessage message) {
    // Formata a data de criação da mensagem no formato dd/MM/yyyy HH:mm
    final dateFormat = _formatDate(message.createdAt);

    // Obtém o nome do remetente da mensagem
    String senderName;
    if (message.senderPublicKey == _keyService.publicKey.value) {
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

    return ListTile(
      title: Text(
        senderName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        dateFormat,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        // Usar o ícone apropriado dependendo da plataforma (adaptação iOS/Android)
        icon: Theme.of(context).platform == TargetPlatform.iOS
            ? const Icon(Icons.ios_share, color: Colors.blue)
            : const Icon(Icons.share, color: Colors.blue),
        onPressed: () => _shareMessage(message),
      ),
      onTap: () {
        // Navegar para a página de detalhes da mensagem
        Get.to(() => MessageDetailPage(message: message));
      },
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

  // Mostra diálogo de opções para mensagens
  Future<String?> _showMessageOptionsDialog() async {
    return await Get.dialog<String>(
      AlertDialog(
        title: Text('message_options_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create),
              title: Text('create_new_message'.tr),
              onTap: () => Get.back(result: 'create'),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text('import_message'.tr),
              onTap: () => Get.back(result: 'import'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
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
