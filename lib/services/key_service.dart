import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cryptography/cryptography.dart';

/*
 * KeyService: Key management and encryption service for the application
 * 
 * Encryption implementation:
 * - Uses a simplified hybrid encryption implementation
 * - Asymmetric keys generated using secure algorithms
 * - Stores keys in base64 format
 * - Keys are securely stored using flutter_secure_storage
 * - Each message has an identifier prefix added for validation
 * - Supports storing third-party public keys
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
      return this; // Returns the service even with errors to prevent application failures
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
      // Check if the key is in valid base64 format
      if (key.isEmpty) return false;

      // Simplified rule for valid base64 verification
      final RegExp base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      if (!base64Pattern.hasMatch(key)) return false;

      // Try to decode to verify validity
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

      // Add identifier to the beginning of the message before encrypting
      final messageWithIdentifier = MESSAGE_IDENTIFIER + message;

      // Convert message to bytes
      final messageBytes = utf8.encode(messageWithIdentifier);

      // Convert public key from base64 to bytes
      final recipientPublicKeyBytes = base64Decode(recipientPublicKeyBase64);
      final recipientPublicKeyObj = SimplePublicKey(
        recipientPublicKeyBytes,
        type: KeyPairType.x25519,
      );

      try {
        // 1. Generate a random key for encryption
        final secretKey = await _cipher.newSecretKey();

        // 2. Generate a random nonce
        final nonce = _cipher.newNonce();

        // 3. Encrypt the message with AES-GCM
        final secretBox = await _cipher.encrypt(
          messageBytes,
          secretKey: secretKey,
          nonce: nonce,
        );

        // 4. Extract symmetric key in bytes
        final symmetricKeyBytes = await secretKey.extractBytes();

        // 5. Load sender's private key
        final senderPrivateKeyBytes = base64Decode(privateKey.value);

        // 6. Create a temporary key pair for the sender
        final senderKeyPair = await _keyExchangeAlgorithm
            .newKeyPairFromSeed(senderPrivateKeyBytes);

        // 7. Calculate shared key using X25519
        final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
          keyPair: senderKeyPair,
          remotePublicKey: recipientPublicKeyObj,
        );

        // 8. Extract shared key in bytes
        final sharedSecretBytes = await sharedSecret.extractBytes();

        // 9. Use shared key to encrypt the symmetric key
        final sharedKeyCipher = AesGcm.with256bits();
        final sharedKeyNonce = sharedKeyCipher.newNonce();
        final encryptedSymmetricKey = await sharedKeyCipher.encrypt(
          symmetricKeyBytes,
          secretKey: SecretKey(sharedSecretBytes),
          nonce: sharedKeyNonce,
        );

        // 10. Combine all elements in a map
        final resultMap = {
          'keyNonce': base64Encode(sharedKeyNonce),
          'encryptedKey': base64Encode(encryptedSymmetricKey.cipherText),
          'keyMac': base64Encode(encryptedSymmetricKey.mac.bytes),
          'messageNonce': base64Encode(nonce),
          'message': base64Encode(secretBox.cipherText),
          'mac': base64Encode(secretBox.mac.bytes),
          'senderPublicKey': publicKey.value,
        };

        // 11. Encode result in JSON and base64 for secure transfer
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

      // Decode message from base64
      final jsonBytes = base64Decode(encryptedText);
      final jsonString = utf8.decode(jsonBytes);
      final Map<String, dynamic> data = json.decode(jsonString);

      try {
        // 1. Extract message components
        final keyNonce = base64Decode(data['keyNonce'] as String);
        final encryptedKey = base64Decode(data['encryptedKey'] as String);
        final keyMac = Mac(base64Decode(data['keyMac'] as String));
        final messageNonce = base64Decode(data['messageNonce'] as String);
        final encryptedMessage = base64Decode(data['message'] as String);
        final messageMac = Mac(base64Decode(data['mac'] as String));

        // 2. Get sender's public key
        String senderPublicKeyStr;
        if (data.containsKey('senderPublicKey')) {
          senderPublicKeyStr = data['senderPublicKey'] as String;
        } else {
          // For compatibility with previous versions, use our own public key
          senderPublicKeyStr = publicKey.value;
        }

        final senderPublicKeyBytes = base64Decode(senderPublicKeyStr);
        final senderPublicKey = SimplePublicKey(
          senderPublicKeyBytes,
          type: KeyPairType.x25519,
        );

        // 3. Load recipient's private key
        final privateKeyBytes = base64Decode(privateKeyStr);

        // 4. Create a temporary key pair for the recipient
        final receiverKeyPair =
            await _keyExchangeAlgorithm.newKeyPairFromSeed(privateKeyBytes);

        // 5. Calculate shared key using X25519
        final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
          keyPair: receiverKeyPair,
          remotePublicKey: senderPublicKey,
        );

        // 6. Extract shared key in bytes
        final sharedSecretBytes = await sharedSecret.extractBytes();

        // 7. Use shared key to decrypt the symmetric key
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

        // 8. Use symmetric key to decrypt the message
        final messageBox = SecretBox(
          encryptedMessage,
          nonce: messageNonce,
          mac: messageMac,
        );

        final decryptedBytes = await _cipher.decrypt(
          messageBox,
          secretKey: SecretKey(symmetricKeyBytes),
        );

        // 9. Convert bytes back to string
        final decryptedText = utf8.decode(decryptedBytes);

        // 10. Check if message contains valid identifier
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

      // Get user keys
      final publicKeyStr = publicKey.value;
      final privateKeyStr = privateKey.value;

      if (publicKeyStr.isEmpty || privateKeyStr.isEmpty) {
        return false;
      }

      // Test message
      final testMessage = "Testing self encryption.";

      // Encrypt message using high-level API
      try {
        // Encrypt using new implementation
        final encryptedBase64 = await encryptMessage(testMessage, publicKeyStr);

        // Decrypt using new implementation
        final decryptedMessage =
            await decryptMessage(encryptedBase64, privateKeyStr);

        // Check if content is correct
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
      // Clear existing keys
      await _storage.delete(key: 'public_key');
      await _storage.delete(key: 'private_key');

      publicKey.value = '';
      privateKey.value = '';
      hasKeys.value = false;

      // Generate new keys
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
    return message; // Returns original message if it doesn't have the identifier
  }

  // Tests encryption between different users
  Future<bool> testUserToCommunication() async {
    try {
      // Current user keys (Alice)
      final alicePublicKey = publicKey.value;
      final alicePrivateKey = privateKey.value;

      // Create keys for test user (Bob)
      final bobKeyPair = await _keyExchangeAlgorithm.newKeyPair();
      final bobPrivateKeyBytes = await bobKeyPair.extractPrivateKeyBytes();
      final bobPublicKeyObj = await bobKeyPair.extractPublicKey();
      final bobPublicKeyBytes = bobPublicKeyObj.bytes;

      final bobPublicKey = base64Encode(bobPublicKeyBytes);
      final bobPrivateKey = base64Encode(bobPrivateKeyBytes);

      // Test message
      final testMessage = "Testing communication between Alice and Bob.";
      try {
        // Alice encrypts message for Bob
        final encryptedForBob = await encryptMessage(testMessage, bobPublicKey);

        // Save current Alice's public key
        final currentPublicKey = publicKey.value;

        // Simulate we're on Bob's device
        // (using Bob's private key and Alice's public key)
        publicKey.value = alicePublicKey; // Set Alice's public key

        // Bob decrypts message with his private key
        final decryptedByBob =
            await decryptMessage(encryptedForBob, bobPrivateKey);

        // Restore state
        publicKey.value = currentPublicKey;

        final success1 = (decryptedByBob == testMessage);

        // Test 2: Bob encrypts for Alice

        // Simulate we're on Bob's device
        publicKey.value = bobPublicKey; // Now Bob is the sender

        // Bob encrypts message for Alice
        final encryptedForAlice =
            await encryptMessage(testMessage, alicePublicKey);

        // Restore state (back to being Alice)
        publicKey.value = alicePublicKey;

        // Alice decrypts message with her private key
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
