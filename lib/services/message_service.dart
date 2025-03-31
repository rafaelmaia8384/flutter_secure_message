import 'dart:convert';
import 'package:get/get.dart';
import '../models/encrypted_message.dart';

class MessageService extends GetxService {
  Future<MessageService> init() async {
    print('Inicializando MessageService...');
    return this;
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

          // Criar JSON simplificado com apenas o texto puro
          // Não precisamos de id, sender ou createdAt para texto puro
          final Map<String, dynamic> simpleJson = {
            'p': message.plainText, // Incluir apenas o texto puro
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
        // Incluir apenas a lista de itens criptografados
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
            'id': simpleJson.containsKey('i')
                ? simpleJson['i']
                : DateTime.now().millisecondsSinceEpoch.toString(),
            'senderPublicKey':
                simpleJson.containsKey('s') ? simpleJson['s'] : 'anonymous',
            'createdAt': simpleJson.containsKey('c')
                ? simpleJson['c']
                : DateTime.now().toIso8601String(),
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

          // Converter para o formato padrão, gerando IDs e timestamps
          messageJson = {
            'id': compactJson.containsKey('i')
                ? compactJson['i']
                : DateTime.now().millisecondsSinceEpoch.toString(),
            'senderPublicKey':
                compactJson.containsKey('s') ? compactJson['s'] : 'anonymous',
            'createdAt': compactJson.containsKey('c')
                ? compactJson['c']
                : DateTime.now().toIso8601String(),
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
          !messageJson.containsKey('createdAt')) {
        print(
            'Estrutura de JSON inválida. Chaves presentes: ${messageJson.keys.join(", ")}');
        return null;
      }

      // Verificar se 'items' é uma lista
      if (messageJson.containsKey('items') && !(messageJson['items'] is List)) {
        print('Campo "items" não é uma lista');
        return null;
      }

      try {
        // Criar objeto EncryptedMessage a partir do JSON
        final message = EncryptedMessage.fromJson(messageJson);
        print('Objeto EncryptedMessage criado com sucesso. ID: ${message.id}');
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
}
