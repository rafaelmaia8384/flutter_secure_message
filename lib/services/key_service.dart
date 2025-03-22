import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:math' as math;

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
      print("Iniciando geração de novas chaves...");

      // Generate a new Ed25519 key pair
      final algorithm = Ed25519();
      print("Algoritmo de criptografia: Ed25519");

      final keyPair = await algorithm.newKeyPair();
      print("Par de chaves gerado");

      // Get the private key bytes
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      print(
          "Bytes da chave privada extraídos, tamanho: ${privateKeyBytes.length}");

      // Get the public key bytes
      final publicKey = await keyPair.extractPublicKey();
      final publicKeyBytes = await publicKey.bytes;
      print(
          "Bytes da chave pública extraídos, tamanho: ${publicKeyBytes.length}");

      // Convert keys to hex strings
      final publicKeyString = publicKeyBytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join('');
      final privateKeyString = privateKeyBytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join('');

      print("Chaves convertidas para formato hexadecimal:");
      print(
          "- Chave pública: ${publicKeyString.substring(0, math.min(10, publicKeyString.length))}... (${publicKeyString.length} caracteres)");
      print("- Chave privada: tamanho ${privateKeyString.length} caracteres");

      // Verificando se as chaves estão vazias por algum motivo
      if (publicKeyString.isEmpty || privateKeyString.isEmpty) {
        print("ERRO: Chaves geradas estão vazias");
        throw Exception('Generated keys are empty');
      }

      // Store keys securely
      print("Salvando chaves no armazenamento seguro...");
      await _storage.write(key: 'public_key', value: publicKeyString);
      await _storage.write(key: 'private_key', value: privateKeyString);

      // Update state
      this.publicKey.value = publicKeyString;
      this.privateKey.value = privateKeyString;
      hasKeys.value = true;

      print("Novas chaves geradas e salvas com sucesso");
      return true;
    } catch (e) {
      print("ERRO ao gerar novas chaves: $e");

      // Garantir que o estado seja consistente em caso de erro
      publicKey.value = '';
      privateKey.value = '';
      hasKeys.value = false;

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
      // Check if the key is a valid hex string
      if (key.isEmpty) return false;
      if (key.length % 2 != 0) return false;
      if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(key)) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  String encryptMessage(String message, String publicKey) {
    try {
      // Verificação adicional para garantir que a chave não esteja vazia
      if (publicKey.isEmpty) {
        print("ERRO: Tentativa de criptografar com chave vazia");
        throw Exception('Public key cannot be empty');
      }

      // Log para debug
      print(
          "Criptografando mensagem. Tamanho da mensagem: ${message.length} caracteres");
      print(
          "Usando chave: ${publicKey.substring(0, math.min(10, publicKey.length))}... (${publicKey.length} caracteres)");

      // Adicionar o identificador ao início da mensagem antes de criptografar
      final messageWithIdentifier = MESSAGE_IDENTIFIER + message;
      final String encodedMessage =
          _encodeMessage(messageWithIdentifier, publicKey);

      print(
          "Mensagem criptografada com sucesso. Tamanho final: ${encodedMessage.length} caracteres");
      return encodedMessage;
    } catch (e) {
      print("ERRO na criptografia: $e");
      throw Exception('Error encrypting message: $e');
    }
  }

  // Verifica se uma mensagem descriptografada contém o identificador válido
  bool isValidDecryptedMessage(String message) {
    return message.startsWith(MESSAGE_IDENTIFIER);
  }

  // Extrai o conteúdo real da mensagem após o identificador
  String extractMessageContent(String message) {
    if (isValidDecryptedMessage(message)) {
      return message.substring(MESSAGE_IDENTIFIER.length);
    }
    return message; // Retorna a mensagem original se não tiver o identificador
  }

  String decryptMessage(String encryptedText, String privateKey) {
    try {
      // Decriptografa a mensagem
      final String decodedMessage = _decodeMessage(encryptedText, privateKey);

      // Verifica se a mensagem contém o identificador válido
      if (isValidDecryptedMessage(decodedMessage)) {
        return extractMessageContent(decodedMessage);
      } else {
        throw Exception('Invalid message format or wrong key');
      }
    } catch (e) {
      throw Exception('Error decrypting message: $e');
    }
  }

  // Tenta descriptografar uma mensagem com uma chave
  // Retorna null se a descriptografia falhar ou a mensagem não for válida
  String? tryDecryptMessage(String encryptedText, String privateKey) {
    try {
      // Verificação segura: se a chave for muito curta, não tente usar substring
      if (privateKey.isEmpty) {
        print("Erro: Chave vazia");
        return null;
      }

      print("Tentando descriptografar com chave privada atual");

      // Tentativa 1: usar a chave privada fornecida diretamente
      try {
        final String decodedMessage = _decodeMessage(encryptedText, privateKey);
        if (isValidDecryptedMessage(decodedMessage)) {
          print("Descriptografia bem sucedida com chave privada");
          return extractMessageContent(decodedMessage);
        }
      } catch (e) {
        print("Falha na tentativa 1: $e");
      }

      print("Tentando versões alternativas da chave...");

      // Tentativa 2: Usar versão em maiúsculas da chave privada
      try {
        final String upperPrivateKey = privateKey.toUpperCase();
        if (upperPrivateKey != privateKey) {
          final String decodedWithUpperKey =
              _decodeMessage(encryptedText, upperPrivateKey);
          if (isValidDecryptedMessage(decodedWithUpperKey)) {
            print("Descriptografia bem sucedida com chave privada maiúscula");
            return extractMessageContent(decodedWithUpperKey);
          }
        }
      } catch (e) {
        print("Falha na tentativa 2: $e");
      }

      // Tentativa 3: Usar versão em minúsculas da chave privada
      try {
        final String lowerPrivateKey = privateKey.toLowerCase();
        if (lowerPrivateKey != privateKey) {
          final String decodedWithLowerKey =
              _decodeMessage(encryptedText, lowerPrivateKey);
          if (isValidDecryptedMessage(decodedWithLowerKey)) {
            print("Descriptografia bem sucedida com chave privada minúscula");
            return extractMessageContent(decodedWithLowerKey);
          }
        }
      } catch (e) {
        print("Falha na tentativa 3: $e");
      }

      // Se houver uma chave pública, tente com ela também (casos de compatibilidade)
      if (hasKeys.value && publicKey.value.isNotEmpty) {
        print("Tentando com a chave pública...");

        // Tentativa 4: Chave pública padrão
        try {
          final String decodedWithPublicKey =
              _decodeMessage(encryptedText, publicKey.value);
          if (isValidDecryptedMessage(decodedWithPublicKey)) {
            print("Descriptografia bem sucedida com chave pública");
            return extractMessageContent(decodedWithPublicKey);
          }
        } catch (e) {
          print("Falha na tentativa 4: $e");
        }

        // Tentativa 5: Chave pública em maiúsculas
        try {
          final String upperPublicKey = publicKey.value.toUpperCase();
          if (upperPublicKey != publicKey.value) {
            final String decodedWithUpperPublic =
                _decodeMessage(encryptedText, upperPublicKey);
            if (isValidDecryptedMessage(decodedWithUpperPublic)) {
              print("Descriptografia bem sucedida com chave pública maiúscula");
              return extractMessageContent(decodedWithUpperPublic);
            }
          }
        } catch (e) {
          print("Falha na tentativa 5: $e");
        }

        // Tentativa 6: Chave pública em minúsculas
        try {
          final String lowerPublicKey = publicKey.value.toLowerCase();
          if (lowerPublicKey != publicKey.value) {
            final String decodedWithLowerPublic =
                _decodeMessage(encryptedText, lowerPublicKey);
            if (isValidDecryptedMessage(decodedWithLowerPublic)) {
              print("Descriptografia bem sucedida com chave pública minúscula");
              return extractMessageContent(decodedWithLowerPublic);
            }
          }
        } catch (e) {
          print("Falha na tentativa 6: $e");
        }
      }

      // Tentativas com chaves de terceiros (caso seja uma mensagem para um contato)
      if (thirdPartyKeys.isNotEmpty) {
        print("Tentando com chaves de terceiros...");

        for (int i = 0; i < thirdPartyKeys.length; i++) {
          final thirdPartyKey = thirdPartyKeys[i];
          try {
            final String decodedWithThirdParty =
                _decodeMessage(encryptedText, thirdPartyKey.publicKey);
            if (isValidDecryptedMessage(decodedWithThirdParty)) {
              print(
                  "Descriptografia bem sucedida com chave de terceiro: ${thirdPartyKey.name}");
              return extractMessageContent(decodedWithThirdParty);
            }
          } catch (e) {
            print(
                "Falha na tentativa com chave de terceiro ${thirdPartyKey.name}: $e");
          }
        }
      }

      print("Todas as tentativas de descriptografia falharam.");
      return null;
    } catch (e) {
      print("Erro geral ao tentar descriptografar: $e");
      return null;
    }
  }

  // Simple mock encoding for demonstration
  String _encodeMessage(String message, String key) {
    // Garantir que a key não seja vazia
    if (key.isEmpty) {
      throw Exception('Key cannot be empty');
    }

    // Padronizar a chave para minúsculas para evitar problemas de case-sensitivity
    String normalizedKey = key.toLowerCase();

    // Garantir que não tentemos acessar mais caracteres do que existem na chave
    final keyLength = normalizedKey.length;
    // Use no máximo 10 caracteres da chave, mas não mais do que existe
    final keySize = keyLength < 10 ? keyLength : 10;
    final keyPart = normalizedKey.substring(0, keySize);

    final encoded = StringBuffer();

    for (int i = 0; i < message.length; i++) {
      final char = message.codeUnitAt(i);
      final keyChar = keyPart[i % keyPart.length].codeUnitAt(0);
      encoded.write((char ^ keyChar).toRadixString(16).padLeft(2, '0'));
    }

    return encoded.toString();
  }

  // Simple mock decoding for demonstration
  String _decodeMessage(String encoded, String key) {
    // Garantir que a key não seja vazia
    if (key.isEmpty) {
      throw Exception('Key cannot be empty');
    }

    // Padronizar a chave para minúsculas para evitar problemas de case-sensitivity
    String normalizedKey = key.toLowerCase();

    // Garantir que não tentemos acessar mais caracteres do que existem na chave
    final keyLength = normalizedKey.length;
    // Use no máximo 10 caracteres da chave, mas não mais do que existe
    final keySize = keyLength < 10 ? keyLength : 10;
    final keyPart = normalizedKey.substring(0, keySize);

    final decoded = StringBuffer();

    for (int i = 0; i < encoded.length; i += 2) {
      if (i + 2 <= encoded.length) {
        final charCode = int.parse(encoded.substring(i, i + 2), radix: 16);
        final keyChar = keyPart[(i ~/ 2) % keyPart.length].codeUnitAt(0);
        decoded.writeCharCode(charCode ^ keyChar);
      }
    }

    return decoded.toString();
  }
}
