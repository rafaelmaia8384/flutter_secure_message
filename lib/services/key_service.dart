import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';
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
    try {
      await loadKeys();
      await loadThirdPartyKeys();

      return this;
    } catch (e) {
      return this; // Retorna o serviço mesmo com erro para evitar falhas na aplicação
    }
  }

  Future<void> loadKeys() async {
    try {
      final storedPublicKey = await _storage.read(key: 'public_key');
      final storedPrivateKey = await _storage.read(key: 'private_key');

      if (storedPublicKey != null && storedPrivateKey != null) {
        // Validate hex format
        if (!_isValidKeyFormat(storedPublicKey) ||
            !_isValidKeyFormat(storedPrivateKey)) {
          throw Exception('Invalid key format');
        }

        publicKey.value = storedPublicKey;
        privateKey.value = storedPrivateKey;
        hasKeys.value = true;
      } else {
        publicKey.value = '';
        privateKey.value = '';
        hasKeys.value = false;
      }
    } catch (e) {
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
      // Gerar par de chaves usando X25519
      final keyPair = await _keyExchangeAlgorithm.newKeyPair();
      final privateKeyObj = await keyPair.extractPrivateKeyBytes();
      final publicKeyObj = await keyPair.extractPublicKey();

      // Extrair bytes
      final publicKeyBytes = publicKeyObj.bytes;
      final privateKeyBytes = privateKeyObj;

      if (publicKeyBytes.isEmpty || privateKeyBytes.isEmpty) {
        return false;
      }
      // Converter as chaves para base64 para armazenamento mais fácil
      final privateKeyBase64 = base64Encode(privateKeyBytes);
      final publicKeyBase64 = base64Encode(publicKeyBytes);

      // Atualizar o estado temporariamente para testar a criptografia
      privateKey.value = privateKeyBase64;
      publicKey.value = publicKeyBase64;

      // Importante: definir hasKeys como true ANTES do teste
      hasKeys.value = true;

      // Testar se podemos criptografar e descriptografar com essas chaves
      final testResult = await testSelfEncryption();

      // Testar o cenário de comunicação entre usuários diferentes
      final testCommunication = await testUserToCommunication();

      if (!testResult || !testCommunication) {
        // Limpar chaves inválidas
        privateKey.value = "";
        publicKey.value = "";
        hasKeys.value = false;
        return false;
      }

      // Armazenar as chaves
      await _storage.write(key: 'public_key', value: publicKeyBase64);
      await _storage.write(key: 'private_key', value: privateKeyBase64);

      // hasKeys já está definido como true acima
      return true;
    } catch (e) {
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
        return false;
      }
    } catch (e) {
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
        throw Exception('Public key cannot be empty');
      }

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
        return encodedBase64;
      } catch (e) {
        throw Exception('Specific encryption error: $e');
      }
    } catch (e) {
      throw Exception('Error encrypting message: $e');
    }
  }

  Future<String> decryptMessage(
      String encryptedText, String privateKeyStr) async {
    try {
      if (privateKeyStr.isEmpty) {
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
        throw Exception('Specific decryption error: $e');
      }
    } catch (e) {
      throw Exception('Error decrypting message: $e');
    }
  }

  Future<String?> tryDecryptMessage(
      String encryptedText, String privateKeyStr) async {
    try {
      if (privateKeyStr.isEmpty) {
        return null;
      }

      try {
        final decrypted = await decryptMessage(encryptedText, privateKeyStr);
        return decrypted;
      } catch (e) {}

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> testSelfEncryption() async {
    try {
      if (!hasKeys.value) {
        return false;
      }

      // Obter as chaves do usuário
      final publicKeyStr = publicKey.value;
      final privateKeyStr = privateKey.value;

      if (publicKeyStr.isEmpty || privateKeyStr.isEmpty) {
        return false;
      }

      // Mensagem de teste
      final testMessage = "Testando criptografia para mim mesmo.";

      // Criptografa a mensagem usando a API de alto nível
      try {
        // Criptografar usando a nova implementação
        final encryptedBase64 = await encryptMessage(testMessage, publicKeyStr);

        // Descriptografar usando a nova implementação
        final decryptedMessage =
            await decryptMessage(encryptedBase64, privateKeyStr);

        // Verifica se o conteúdo está correto
        final success = (decryptedMessage == testMessage);

        return success;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> forceRegenerateKeys() async {
    try {
      // Limpar chaves existentes
      await _storage.delete(key: 'public_key');
      await _storage.delete(key: 'private_key');

      publicKey.value = '';
      privateKey.value = '';
      hasKeys.value = false;

      // Gerar novas chaves
      final result = await generateNewKeys();

      return result;
    } catch (e) {
      return false;
    }
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

      // Mensagem de teste
      final testMessage = "Testando comunicação entre Alice e Bob.";
      try {
        // Alice criptografa mensagem para Bob
        final encryptedForBob = await encryptMessage(testMessage, bobPublicKey);

        // Salvar chave pública de Alice atual
        final currentPublicKey = publicKey.value;

        // Simular que estamos no dispositivo de Bob
        // (usando a chave privada de Bob e a chave pública de Alice)
        publicKey.value = alicePublicKey; // Define chave pública de Alice

        // Bob descriptografa mensagem com sua chave privada
        final decryptedByBob =
            await decryptMessage(encryptedForBob, bobPrivateKey);

        // Restaurar estado
        publicKey.value = currentPublicKey;

        final success1 = (decryptedByBob == testMessage);

        // Teste 2: Bob criptografa para Alice

        // Simular que estamos no dispositivo de Bob
        publicKey.value = bobPublicKey; // Agora Bob é o remetente

        // Bob criptografa mensagem para Alice
        final encryptedForAlice =
            await encryptMessage(testMessage, alicePublicKey);

        // Restaurar estado (voltamos a ser Alice)
        publicKey.value = alicePublicKey;

        // Alice descriptografa mensagem com sua chave privada
        final decryptedByAlice =
            await decryptMessage(encryptedForAlice, alicePrivateKey);

        final success2 = (decryptedByAlice == testMessage);

        return success1 && success2;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
