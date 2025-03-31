import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:cryptography/cryptography.dart';

/*
 * KeyService: Gerenciamento de chaves e criptografia para o aplicativo
 * 
 * Implementação de criptografia:
 * - Utiliza uma implementação simplificada de criptografia híbrida
 * - Chaves assimétricas geradas usando algoritmos seguros
 * - Armazena chaves no formato base64
 * - As chaves são armazenadas de forma segura usando flutter_secure_storage
 * - Cada mensagem tem um identificador adicionado como prefixo para validação
 * - Suporta armazenamento de chaves públicas de terceiros
 */

class ThirdPartyKey {
  final String name;
  final String publicKey;
  final DateTime addedAt;

  ThirdPartyKey({
    required this.name,
    required this.publicKey,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'publicKey': publicKey,
        'addedAt': addedAt.toIso8601String(),
      };

  factory ThirdPartyKey.fromJson(Map<String, dynamic> json) => ThirdPartyKey(
        name: json['name'] as String,
        publicKey: json['publicKey'] as String,
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'] as String)
            : null,
      );
}

class KeyService extends GetxService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final RxBool hasKeys = false.obs;
  final RxString publicKey = ''.obs;
  final RxString privateKey = ''.obs;
  final thirdPartyKeys = <ThirdPartyKey>[].obs;

  // Algoritmos de criptografia
  final _keyExchangeAlgorithm = X25519();
  final _cipher = AesGcm.with256bits();

  // Identificador para validar mensagens descriptografadas
  static const String MESSAGE_IDENTIFIER = "secure-chat:";

  Future<KeyService> init() async {
    print("Inicializando KeyService...");
    try {
      await loadKeys();
      await loadThirdPartyKeys();

      print("KeyService inicializado com sucesso:");
      print("- Tem chaves: ${hasKeys.value}");
      print("- Tamanho da chave pública: ${publicKey.value.length} caracteres");
      print(
          "- Tamanho da chave privada: ${privateKey.value.length} caracteres");
      print("- Quantidade de chaves de terceiros: ${thirdPartyKeys.length}");

      return this;
    } catch (e) {
      print("Erro ao inicializar KeyService: $e");
      return this; // Retorna o serviço mesmo com erro para evitar falhas na aplicação
    }
  }

  Future<void> loadKeys() async {
    try {
      print("Carregando chaves do armazenamento seguro...");
      final storedPublicKey = await _storage.read(key: 'public_key');
      final storedPrivateKey = await _storage.read(key: 'private_key');

      if (storedPublicKey != null && storedPrivateKey != null) {
        print("Chaves encontradas no armazenamento. Validando formato...");

        // Validate hex format
        if (!_isValidKeyFormat(storedPublicKey) ||
            !_isValidKeyFormat(storedPrivateKey)) {
          print("ERRO: Formato de chave inválido");
          throw Exception('Invalid key format');
        }

        publicKey.value = storedPublicKey;
        privateKey.value = storedPrivateKey;
        hasKeys.value = true;
        print("Chaves carregadas e validadas com sucesso");
      } else {
        print("Nenhuma chave encontrada no armazenamento");
        publicKey.value = '';
        privateKey.value = '';
        hasKeys.value = false;
      }
    } catch (e) {
      print("Erro ao carregar chaves: $e");
      // Garantir que o estado seja consistente em caso de erro
      publicKey.value = '';
      privateKey.value = '';
      hasKeys.value = false;
      throw Exception('Error loading keys: $e');
    }
  }

  Future<void> loadThirdPartyKeys() async {
    try {
      final storedKeys = await _storage.read(key: 'third_party_keys');
      if (storedKeys != null) {
        final List<dynamic> jsonList = json.decode(storedKeys);
        thirdPartyKeys.value =
            jsonList.map((json) => ThirdPartyKey.fromJson(json)).toList();
      }
    } catch (e) {
      // Error handling is done in the UI layer
    }
  }

  Future<void> saveThirdPartyKeys() async {
    try {
      final jsonList = thirdPartyKeys.map((key) => key.toJson()).toList();
      await _storage.write(
        key: 'third_party_keys',
        value: json.encode(jsonList),
      );
    } catch (e) {
      // Error handling is done in the UI layer
    }
  }

  Future<bool> generateNewKeys() async {
    try {
      print("Gerando novo par de chaves X25519...");

      // Gerar par de chaves usando X25519
      final keyPair = await _keyExchangeAlgorithm.newKeyPair();
      final privateKeyObj = await keyPair.extractPrivateKeyBytes();
      final publicKeyObj = await keyPair.extractPublicKey();

      // Extrair bytes
      final publicKeyBytes = publicKeyObj.bytes;
      final privateKeyBytes = privateKeyObj;

      if (publicKeyBytes.isEmpty || privateKeyBytes.isEmpty) {
        print("Erro: Geração de chaves resultou em chaves vazias!");
        return false;
      }

      print("Chaves geradas:");
      print(
          "Privada (primeiros bytes): ${_bytesToHex(privateKeyBytes.sublist(0, math.min(8, privateKeyBytes.length)))}...");
      print(
          "Pública (primeiros bytes): ${_bytesToHex(publicKeyBytes.sublist(0, math.min(8, publicKeyBytes.length)))}...");

      // Converter as chaves para base64 para armazenamento mais fácil
      final privateKeyBase64 = base64Encode(privateKeyBytes);
      final publicKeyBase64 = base64Encode(publicKeyBytes);

      // Atualizar o estado temporariamente para testar a criptografia
      privateKey.value = privateKeyBase64;
      publicKey.value = publicKeyBase64;

      // Importante: definir hasKeys como true ANTES do teste
      hasKeys.value = true;

      // Testar se podemos criptografar e descriptografar com essas chaves
      print("\nTestando criptografia e descriptografia com as novas chaves...");
      final testResult = await testSelfEncryption();

      // Testar o cenário de comunicação entre usuários diferentes
      final testCommunication = await testUserToCommunication();

      if (!testResult || !testCommunication) {
        print("FALHA: As chaves não passaram nos testes de criptografia!");
        // Limpar chaves inválidas
        privateKey.value = "";
        publicKey.value = "";
        hasKeys.value = false;
        return false;
      }

      // Armazenar as chaves
      print("Salvando chaves...");
      await _storage.write(key: 'public_key', value: publicKeyBase64);
      await _storage.write(key: 'private_key', value: privateKeyBase64);

      // hasKeys já está definido como true acima
      print("Chaves salvas com sucesso!");
      return true;
    } catch (e) {
      print("Erro ao gerar novas chaves: $e");
      return false;
    }
  }

  Future<bool> deleteKeys() async {
    try {
      await _storage.delete(key: 'public_key');
      await _storage.delete(key: 'private_key');

      publicKey.value = '';
      privateKey.value = '';
      hasKeys.value = false;

      return true;
    } catch (e) {
      return false;
    }
  }

  bool addThirdPartyKey(String publicKeyString, String name) {
    try {
      // Check if the key is equal to the user's key first
      if (hasKeys.value && publicKeyString == publicKey.value) {
        return false;
      }

      // Then validate the key format
      if (!_isValidKeyFormat(publicKeyString)) {
        return false;
      }

      final newKey = ThirdPartyKey(
        name: name,
        publicKey: publicKeyString,
        addedAt: DateTime.now().toUtc(),
      );

      thirdPartyKeys.add(newKey);
      saveThirdPartyKeys();
      return true;
    } catch (e) {
      return false;
    }
  }

  void deleteThirdPartyKey(int index) {
    if (index >= 0 && index < thirdPartyKeys.length) {
      thirdPartyKeys.removeAt(index);
      saveThirdPartyKeys();
    }
  }

  bool _isValidKeyFormat(String key) {
    try {
      // Verificar se a chave está em formato base64 válido
      if (key.isEmpty) return false;

      // Regra simplificada para verificação de base64 válido
      final RegExp base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      if (!base64Pattern.hasMatch(key)) return false;

      // Tentar decodificar para verificar validade
      try {
        base64Decode(key);
        return true;
      } catch (e) {
        print("Erro ao decodificar base64: $e");
        return false;
      }
    } catch (e) {
      print("Erro ao validar formato de chave: $e");
      return false;
    }
  }

  bool isValidPublicKey(String key) {
    // Reutilizar a lógica de validação de formato de chave
    return _isValidKeyFormat(key);
  }

  Future<String> encryptMessage(
      String message, String recipientPublicKeyBase64) async {
    try {
      if (recipientPublicKeyBase64.isEmpty) {
        print("ERRO: Tentativa de criptografar com chave pública vazia");
        throw Exception('Public key cannot be empty');
      }

      print("Criptografando mensagem. Tamanho: ${message.length} caracteres");

      // Adicionar o identificador ao início da mensagem antes de criptografar
      final messageWithIdentifier = MESSAGE_IDENTIFIER + message;

      // Converter a mensagem para bytes
      final messageBytes = utf8.encode(messageWithIdentifier);

      // Converter a chave pública de base64 para bytes
      final recipientPublicKeyBytes = base64Decode(recipientPublicKeyBase64);
      final recipientPublicKeyObj = SimplePublicKey(
        recipientPublicKeyBytes,
        type: KeyPairType.x25519,
      );

      try {
        // 1. Gerar uma chave aleatória para criptografia
        final secretKey = await _cipher.newSecretKey();

        // 2. Gerar um nonce aleatório
        final nonce = _cipher.newNonce();

        // 3. Criptografar a mensagem com AES-GCM
        final secretBox = await _cipher.encrypt(
          messageBytes,
          secretKey: secretKey,
          nonce: nonce,
        );

        // 4. Extrair a chave simétrica em bytes
        final symmetricKeyBytes = await secretKey.extractBytes();

        // 5. Carregar a chave privada do remetente
        final senderPrivateKeyBytes = base64Decode(privateKey.value);

        // 6. Criar um par de chaves temporário para o remetente
        final senderKeyPair = await _keyExchangeAlgorithm
            .newKeyPairFromSeed(senderPrivateKeyBytes);

        // 7. Calcular a chave compartilhada usando X25519
        final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
          keyPair: senderKeyPair,
          remotePublicKey: recipientPublicKeyObj,
        );

        // 8. Extrair a chave compartilhada em bytes
        final sharedSecretBytes = await sharedSecret.extractBytes();

        // 9. Usar a chave compartilhada para criptografar a chave simétrica
        final sharedKeyCipher = AesGcm.with256bits();
        final sharedKeyNonce = sharedKeyCipher.newNonce();
        final encryptedSymmetricKey = await sharedKeyCipher.encrypt(
          symmetricKeyBytes,
          secretKey: SecretKey(sharedSecretBytes),
          nonce: sharedKeyNonce,
        );

        // 10. Combinar todos os elementos em um mapa
        final resultMap = {
          'keyNonce': base64Encode(sharedKeyNonce),
          'encryptedKey': base64Encode(encryptedSymmetricKey.cipherText),
          'keyMac': base64Encode(encryptedSymmetricKey.mac.bytes),
          'messageNonce': base64Encode(nonce),
          'message': base64Encode(secretBox.cipherText),
          'mac': base64Encode(secretBox.mac.bytes),
          'senderPublicKey': publicKey.value,
        };

        // 11. Codificar o resultado em JSON e base64 para transferência segura
        final encodedJson = json.encode(resultMap);
        final encodedBase64 = base64Encode(utf8.encode(encodedJson));

        print(
            "Mensagem criptografada com sucesso. Tamanho final: ${encodedBase64.length} caracteres");
        return encodedBase64;
      } catch (e) {
        print("Erro específico na criptografia: $e");
        throw Exception('Specific encryption error: $e');
      }
    } catch (e) {
      print("ERRO na criptografia: $e");
      throw Exception('Error encrypting message: $e');
    }
  }

  Future<String> decryptMessage(
      String encryptedText, String privateKeyStr) async {
    try {
      if (privateKeyStr.isEmpty) {
        print("ERRO: Tentativa de descriptografar com chave privada vazia");
        throw Exception('Private key cannot be empty');
      }

      // Decodificar a mensagem de base64
      final jsonBytes = base64Decode(encryptedText);
      final jsonString = utf8.decode(jsonBytes);
      final Map<String, dynamic> data = json.decode(jsonString);

      try {
        // 1. Extrair componentes da mensagem
        final keyNonce = base64Decode(data['keyNonce'] as String);
        final encryptedKey = base64Decode(data['encryptedKey'] as String);
        final keyMac = Mac(base64Decode(data['keyMac'] as String));
        final messageNonce = base64Decode(data['messageNonce'] as String);
        final encryptedMessage = base64Decode(data['message'] as String);
        final messageMac = Mac(base64Decode(data['mac'] as String));

        // 2. Obter a chave pública do remetente
        String senderPublicKeyStr;
        if (data.containsKey('senderPublicKey')) {
          senderPublicKeyStr = data['senderPublicKey'] as String;
        } else {
          // Para compatibilidade com versões anteriores, usar nossa própria chave pública
          senderPublicKeyStr = publicKey.value;
          print("Aviso: Usando chave pública própria para compatibilidade.");
        }

        final senderPublicKeyBytes = base64Decode(senderPublicKeyStr);
        final senderPublicKey = SimplePublicKey(
          senderPublicKeyBytes,
          type: KeyPairType.x25519,
        );

        // 3. Carregar a chave privada do destinatário
        final privateKeyBytes = base64Decode(privateKeyStr);

        // 4. Criamos um par de chaves temporário para o destinatário
        final receiverKeyPair =
            await _keyExchangeAlgorithm.newKeyPairFromSeed(privateKeyBytes);

        // 5. Calcular a chave compartilhada usando X25519
        final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
          keyPair: receiverKeyPair,
          remotePublicKey: senderPublicKey,
        );

        // 6. Extrair a chave compartilhada em bytes
        final sharedSecretBytes = await sharedSecret.extractBytes();

        // 7. Usar a chave compartilhada para descriptografar a chave simétrica
        final sharedKeyCipher = AesGcm.with256bits();
        final encryptedKeyBox = SecretBox(
          encryptedKey,
          nonce: keyNonce,
          mac: keyMac,
        );

        final symmetricKeyBytes = await sharedKeyCipher.decrypt(
          encryptedKeyBox,
          secretKey: SecretKey(sharedSecretBytes),
        );

        // 8. Usar a chave simétrica para descriptografar a mensagem
        final messageBox = SecretBox(
          encryptedMessage,
          nonce: messageNonce,
          mac: messageMac,
        );

        final decryptedBytes = await _cipher.decrypt(
          messageBox,
          secretKey: SecretKey(symmetricKeyBytes),
        );

        // 9. Converter os bytes de volta para string
        final decryptedText = utf8.decode(decryptedBytes);

        // 10. Verificar se a mensagem contém o identificador válido
        if (decryptedText.startsWith(MESSAGE_IDENTIFIER)) {
          return decryptedText.substring(MESSAGE_IDENTIFIER.length);
        } else {
          throw Exception('Invalid message format or wrong key');
        }
      } catch (e) {
        print("Erro específico na descriptografia: $e");
        throw Exception('Specific decryption error: $e');
      }
    } catch (e) {
      print("Erro ao descriptografar: $e");
      throw Exception('Error decrypting message: $e');
    }
  }

  Future<String?> tryDecryptMessage(
      String encryptedText, String privateKeyStr) async {
    try {
      if (privateKeyStr.isEmpty) {
        print("Erro: Chave privada vazia");
        return null;
      }

      print("Tentando descriptografar com chave privada atual");

      try {
        final decrypted = await decryptMessage(encryptedText, privateKeyStr);
        print("Descriptografia bem sucedida com chave privada");
        return decrypted;
      } catch (e) {
        print("Falha na descriptografia com chave privada: $e");
      }

      // Se não conseguiu descriptografar com a chave privada,
      // a mensagem não é destinada ao usuário atual ou está corrompida
      print(
          "Não foi possível descriptografar a mensagem com a chave privada atual");
      return null;
    } catch (e) {
      print("Erro geral ao tentar descriptografar: $e");
      return null;
    }
  }

  Future<bool> testSelfEncryption() async {
    try {
      if (!hasKeys.value) {
        print("Não há chaves para testar");
        return false;
      }

      // Obter as chaves do usuário
      final publicKeyStr = publicKey.value;
      final privateKeyStr = privateKey.value;

      if (publicKeyStr.isEmpty || privateKeyStr.isEmpty) {
        print("Chaves vazias, não é possível testar");
        return false;
      }

      print("\n===== TESTE DE CRIPTOGRAFIA PARA SI MESMO =====");

      // Converte as chaves de string para bytes
      final publicKeyBytes = base64Decode(publicKeyStr);
      final privateKeyBytes = base64Decode(privateKeyStr);

      // Exibe informações das chaves
      String pubKeyHex = _bytesToHex(
          publicKeyBytes.sublist(0, math.min(16, publicKeyBytes.length)));
      String privKeyHex = _bytesToHex(
          privateKeyBytes.sublist(0, math.min(16, privateKeyBytes.length)));
      print("Chave pública (primeiros bytes): $pubKeyHex");
      print("Chave privada (primeiros bytes): $privKeyHex");

      // Mensagem de teste
      final testMessage = "Testando criptografia para mim mesmo.";
      print("Mensagem original: $testMessage");

      // Criptografa a mensagem usando a API de alto nível
      try {
        // Criptografar usando a nova implementação
        final encryptedBase64 = await encryptMessage(testMessage, publicKeyStr);

        // Descriptografar usando a nova implementação
        final decryptedMessage =
            await decryptMessage(encryptedBase64, privateKeyStr);

        // Verifica se o conteúdo está correto
        final success = (decryptedMessage == testMessage);
        print("Teste " + (success ? "bem-sucedido" : "falhou"));
        print("Original: $testMessage");
        print("Descriptografado: $decryptedMessage");
        print("==========================================\n");

        return success;
      } catch (e) {
        print("FALHA no teste de criptografia: $e");
        return false;
      }
    } catch (e) {
      print("Erro durante o teste de criptografia: $e");
      return false;
    }
  }

  Future<bool> forceRegenerateKeys() async {
    try {
      print("Forçando regeneração de chaves...");

      // Limpar chaves existentes
      await _storage.delete(key: 'public_key');
      await _storage.delete(key: 'private_key');

      publicKey.value = '';
      privateKey.value = '';
      hasKeys.value = false;

      // Gerar novas chaves
      print("Gerando novas chaves...");
      final result = await generateNewKeys();

      if (result) {
        print("Regeneração de chaves concluída com sucesso!");
      } else {
        print("Falha na regeneração de chaves.");
      }

      return result;
    } catch (e) {
      print("Erro ao regenerar chaves: $e");
      return false;
    }
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  bool isValidDecryptedMessage(String message) {
    return message.startsWith(MESSAGE_IDENTIFIER);
  }

  String extractMessageContent(String message) {
    if (isValidDecryptedMessage(message)) {
      return message.substring(MESSAGE_IDENTIFIER.length);
    }
    return message; // Retorna a mensagem original se não tiver o identificador
  }

  // Testa a criptografia entre usuários diferentes
  Future<bool> testUserToCommunication() async {
    try {
      print("\n===== TESTE DE COMUNICAÇÃO ENTRE USUÁRIOS =====");

      // Chaves do usuário atual (Alice)
      final alicePublicKey = publicKey.value;
      final alicePrivateKey = privateKey.value;

      // Criar chaves para um usuário de teste (Bob)
      final bobKeyPair = await _keyExchangeAlgorithm.newKeyPair();
      final bobPrivateKeyBytes = await bobKeyPair.extractPrivateKeyBytes();
      final bobPublicKeyObj = await bobKeyPair.extractPublicKey();
      final bobPublicKeyBytes = bobPublicKeyObj.bytes;

      final bobPublicKey = base64Encode(bobPublicKeyBytes);
      final bobPrivateKey = base64Encode(bobPrivateKeyBytes);

      print("Chaves do usuário de teste (Bob) geradas:");
      print(
          "Pública (primeiros bytes): ${_bytesToHex(bobPublicKeyBytes.sublist(0, math.min(8, bobPublicKeyBytes.length)))}...");

      // Mensagem de teste
      final testMessage = "Testando comunicação entre Alice e Bob.";
      print("Mensagem original: $testMessage");

      // Teste 1: Alice criptografa para Bob
      print("\nTeste 1: Alice criptografa para Bob");
      try {
        // Alice criptografa mensagem para Bob
        final encryptedForBob = await encryptMessage(testMessage, bobPublicKey);
        print("Mensagem criptografada por Alice para Bob");

        // Salvar chave pública de Alice atual
        final currentPublicKey = publicKey.value;

        // Simular que estamos no dispositivo de Bob
        // (usando a chave privada de Bob e a chave pública de Alice)
        publicKey.value = alicePublicKey; // Define chave pública de Alice

        // Bob descriptografa mensagem com sua chave privada
        final decryptedByBob =
            await decryptMessage(encryptedForBob, bobPrivateKey);
        print("Mensagem descriptografada por Bob: $decryptedByBob");

        // Restaurar estado
        publicKey.value = currentPublicKey;

        final success1 = (decryptedByBob == testMessage);
        print("Teste 1 " + (success1 ? "bem-sucedido" : "falhou"));

        // Teste 2: Bob criptografa para Alice
        print("\nTeste 2: Bob criptografa para Alice");

        // Simular que estamos no dispositivo de Bob
        publicKey.value = bobPublicKey; // Agora Bob é o remetente

        // Bob criptografa mensagem para Alice
        final encryptedForAlice =
            await encryptMessage(testMessage, alicePublicKey);
        print("Mensagem criptografada por Bob para Alice");

        // Restaurar estado (voltamos a ser Alice)
        publicKey.value = alicePublicKey;

        // Alice descriptografa mensagem com sua chave privada
        final decryptedByAlice =
            await decryptMessage(encryptedForAlice, alicePrivateKey);
        print("Mensagem descriptografada por Alice: $decryptedByAlice");

        final success2 = (decryptedByAlice == testMessage);
        print("Teste 2 " + (success2 ? "bem-sucedido" : "falhou"));

        print("==========================================\n");

        return success1 && success2;
      } catch (e) {
        print("FALHA no teste de comunicação entre usuários: $e");
        return false;
      }
    } catch (e) {
      print("Erro durante o teste de comunicação entre usuários: $e");
      return false;
    }
  }
}
