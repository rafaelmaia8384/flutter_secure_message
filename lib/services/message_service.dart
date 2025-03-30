import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/encrypted_message.dart';
import 'key_service.dart';

class MessageService extends GetxService {
  final GetStorage _storage = GetStorage();
  final KeyService _keyService = Get.find<KeyService>();
  final RxList<EncryptedMessage> messages = <EncryptedMessage>[].obs;

  Future<MessageService> init() async {
    print('Inicializando MessageService...');
    await loadMessages();
    return this;
  }

  @override
  void onInit() {
    super.onInit();
    // loadMessages é chamado pelo método init() agora
  }

  Future<void> loadMessages() async {
    try {
      final storedMessages = _storage.read('messages');
      print('Tentando carregar mensagens do armazenamento...');

      if (storedMessages != null) {
        print('Dados encontrados: ${storedMessages.length} caracteres');
        final List<dynamic> jsonList = json.decode(storedMessages);
        print('JSON decodificado com ${jsonList.length} mensagens');

        messages.value =
            jsonList.map((json) => EncryptedMessage.fromJson(json)).toList();

        print('Mensagens carregadas com sucesso: ${messages.length} mensagens');
      } else {
        print('Nenhum dado de mensagem encontrado no armazenamento');
        messages.clear();
      }
    } catch (e) {
      print('Erro ao carregar mensagens: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_messages'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> saveMessages() async {
    try {
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storage.write('messages', jsonString);

      print('Mensagens salvas: ${messages.length} mensagens');
      print('Tamanho do JSON salvo: ${jsonString.length} caracteres');

      // Verificar se os dados foram persistidos
      final storedData = _storage.read('messages');
      if (storedData != null) {
        print(
            'Dados confirmados no armazenamento: ${storedData.length} caracteres');
      } else {
        print(
            'ERRO: Os dados não foram encontrados no armazenamento após salvar');
      }
    } catch (e) {
      print('Erro ao salvar mensagens: $e');
      Get.snackbar(
        'error'.tr,
        'error_saving_messages'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> addMessage(EncryptedMessage message) async {
    messages.add(message);
    await saveMessages();
  }

  Future<void> deleteMessage(dynamic messageOrId) async {
    if (messageOrId is EncryptedMessage) {
      messages.removeWhere((msg) => msg.id == messageOrId.id);
    } else if (messageOrId is String) {
      messages.removeWhere((msg) => msg.id == messageOrId);
    }
    await saveMessages();
  }

  // Método para compactar uma mensagem para compartilhamento
  String compactMessageForSharing(EncryptedMessage message) {
    try {
      // Verificar se a mensagem tem items criptografados para compartilhar
      if (message.items.isEmpty) {
        print('Aviso: Mensagem sem itens criptografados para compartilhar');

        // Se a mensagem não tem itens criptografados, mas tem texto puro,
        // retorna um formato simplificado para compartilhar apenas o texto
        if (message.plainText.isNotEmpty) {
          print('Compartilhando apenas o texto puro da mensagem');

          // Criar JSON simplificado com apenas os metadados e o texto puro
          final Map<String, dynamic> simpleJson = {
            'i': message.id,
            's': message.senderPublicKey,
            'c': message.createdAt.toIso8601String(),
            'p': message.plainText, // Incluir o texto puro
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
        'i': message.id,
        's': message.senderPublicKey,
        'c': message.createdAt.toIso8601String(),
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

  // Método para extrair uma mensagem de uma string compartilhada
  EncryptedMessage? extractMessageFromSharedString(String sharedString) {
    try {
      // Limpar a string, removendo espaços, quebras de linha e outros caracteres não visíveis
      String cleanedString = sharedString.trim();

      // Logs para ajudar na depuração
      print('Tentando extrair mensagem de string compartilhada...');
      print('Comprimento original: ${sharedString.length}');
      print('Comprimento após limpeza: ${cleanedString.length}');

      String jsonString;
      Map<String, dynamic> messageJson;

      // Verificar o formato da mensagem
      if (cleanedString.startsWith("sec-txt-")) {
        print('Formato detectado: texto puro (sem criptografia)');
        // Formato para texto puro
        String base64String = cleanedString.substring("sec-txt-".length);

        try {
          // Decodificar o base64
          List<int> decodedBytes = base64Decode(base64String);
          jsonString = utf8.decode(decodedBytes);

          // Analisar o JSON simplificado
          final Map<String, dynamic> simpleJson = json.decode(jsonString);
          print(
              'JSON de texto puro decodificado com sucesso. Chaves: ${simpleJson.keys.join(", ")}');

          // Converter para o formato padrão
          messageJson = {
            'id': simpleJson['i'],
            'senderPublicKey': simpleJson['s'],
            'createdAt': simpleJson['c'],
            'plainText': simpleJson['p'],
            'items': [], // Lista vazia de itens
            'isImported': true, // Marcar como importada
          };
        } catch (e) {
          print('Erro na decodificação do formato de texto puro: $e');
          throw FormatException('Erro na decodificação: $e');
        }
      } else if (cleanedString.startsWith("sec-")) {
        print('Formato detectado: sc2 (otimizado)');
        // Formato otimizado
        String base64String = cleanedString.substring("sec-".length);

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
            'id': compactJson['i'],
            'senderPublicKey': compactJson['s'],
            'createdAt': compactJson['c'],
            'items': (compactJson['t'] as List)
                .map((item) => {
                      'encryptedText': item['e'],
                      'createdAt': item['d'],
                    })
                .toList(),
          };
        } catch (e) {
          print('Erro na decodificação do formato sc2: $e');
          throw FormatException('Erro na decodificação: $e');
        }
      } else if (cleanedString.startsWith("sec-")) {
        print('Formato detectado: secure-chat (original)');
        // Formato original
        String base64String = cleanedString.substring("sec-".length);

        try {
          // Decodificar o base64
          List<int> decodedBytes = base64Decode(base64String);
          jsonString = utf8.decode(decodedBytes);
          messageJson = json.decode(jsonString);
          print(
              'JSON original decodificado com sucesso. Chaves: ${messageJson.keys.join(", ")}');
        } catch (e) {
          print('Erro na decodificação do formato secure-chat: $e');
          throw FormatException('Erro na decodificação: $e');
        }
      } else {
        // Verificar se é uma string JSON direta (sem codificação)
        try {
          print('Tentando decodificar como JSON direto...');
          messageJson = json.decode(cleanedString);
          print('JSON direto decodificado com sucesso');
        } catch (e) {
          print('Não é um formato válido de mensagem: $e');
          return null;
        }
      }

      // Verificar estrutura básica do JSON antes de tentar criar o objeto
      if (!messageJson.containsKey('id') ||
          !messageJson.containsKey('senderPublicKey') ||
          !messageJson.containsKey('items') ||
          !messageJson.containsKey('createdAt')) {
        print(
            'Estrutura de JSON inválida. Chaves presentes: ${messageJson.keys.join(", ")}');
        return null;
      }

      // Verificar se 'items' é uma lista
      if (!(messageJson['items'] is List)) {
        print('Campo "items" não é uma lista');
        return null;
      }

      try {
        // Criar objeto EncryptedMessage a partir do JSON
        final message = EncryptedMessage.fromJson(messageJson);
        print('Objeto EncryptedMessage criado com sucesso. ID: ${message.id}');
        print('A mensagem tem ${message.items.length} itens');
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

  Future<void> updateMessage(EncryptedMessage updatedMessage) async {
    // Encontrar o índice da mensagem com o mesmo ID
    final index = messages.indexWhere((msg) => msg.id == updatedMessage.id);

    if (index >= 0) {
      // Log da contagem de itens antes da atualização
      final oldItemsCount = messages[index].items.length;

      // Substituir a mensagem existente pela atualizada
      messages[index] = updatedMessage;
      await saveMessages();

      // Log da contagem de itens após a atualização
      final newItemsCount = updatedMessage.items.length;

      print('Mensagem atualizada com sucesso. ID: ${updatedMessage.id}');
      print(
          'Contagem de itens criptografados: antes=$oldItemsCount, depois=$newItemsCount');
    } else {
      print(
          'Erro: Mensagem não encontrada para atualização. ID: ${updatedMessage.id}');
      throw Exception('Message not found for update');
    }
  }
}
