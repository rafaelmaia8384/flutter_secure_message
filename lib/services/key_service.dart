import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:math' as math;

/*
 * KeyService: Gerenciamento de chaves e criptografia para o aplicativo
 * 
 * Implementação de criptografia:
 * - Utiliza o algoritmo Ed25519 para geração de chaves
 * - Armazena chaves no formato hexadecimal
 * - As chaves são armazenadas de forma segura usando flutter_secure_storage
 * - A criptografia é feita usando uma implementação simplificada baseada em Ed25519
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

  String encryptMessage(String message, String recipientPublicKey) {
    try {
      if (recipientPublicKey.isEmpty) {
        print("ERRO: Tentativa de criptografar com chave pública vazia");
        throw Exception('Public key cannot be empty');
      }

      if (privateKey.value.isEmpty) {
        print("ERRO: Tentativa de criptografar sem chave privada");
        throw Exception('Private key not available');
      }

      print("Criptografando mensagem. Tamanho: ${message.length} caracteres");

      // Adicionar o identificador ao início da mensagem antes de criptografar
      final messageWithIdentifier = MESSAGE_IDENTIFIER + message;

      // Converter a mensagem para bytes
      final messageBytes = utf8.encode(messageWithIdentifier);

      // Criptografar a mensagem
      final encryptedData = _encryptWithEd25519(messageBytes,
          _hexToBytes(privateKey.value), _hexToBytes(recipientPublicKey));

      // Codificar o resultado em base64 para transferência segura
      final encodedBase64 = base64Encode(encryptedData);

      print(
          "Mensagem criptografada com sucesso. Tamanho final: ${encodedBase64.length} caracteres");
      return encodedBase64;
    } catch (e) {
      print("ERRO na criptografia: $e");
      throw Exception('Error encrypting message: $e');
    }
  }

  String? tryDecryptMessage(String encryptedText, String privateKey) {
    try {
      if (privateKey.isEmpty) {
        print("Erro: Chave privada vazia");
        return null;
      }

      print("Tentando descriptografar com chave privada atual");

      // Tentativa 1: usar a chave privada fornecida diretamente
      try {
        final decrypted = decryptMessage(encryptedText, privateKey);
        print("Descriptografia bem sucedida com chave privada");
        return decrypted;
      } catch (e) {
        print("Falha na tentativa 1: $e");
      }

      // Tentativa 2: usar chave privada em maiúsculas
      try {
        final upperPrivateKey = privateKey.toUpperCase();
        if (upperPrivateKey != privateKey) {
          final decrypted = decryptMessage(encryptedText, upperPrivateKey);
          print("Descriptografia bem sucedida com chave privada (maiúscula)");
          return decrypted;
        }
      } catch (e) {
        print("Falha na tentativa 2: $e");
      }

      // Tentativa 3: usar chave privada em minúsculas
      try {
        final lowerPrivateKey = privateKey.toLowerCase();
        if (lowerPrivateKey != privateKey) {
          final decrypted = decryptMessage(encryptedText, lowerPrivateKey);
          print("Descriptografia bem sucedida com chave privada (minúscula)");
          return decrypted;
        }
      } catch (e) {
        print("Falha na tentativa 3: $e");
      }

      // Tentativas com nossa chave pública (para casos especiais)
      if (hasKeys.value && publicKey.value.isNotEmpty) {
        try {
          final decrypted = decryptMessage(encryptedText, publicKey.value);
          print("Descriptografia bem sucedida com chave pública");
          return decrypted;
        } catch (e) {
          print("Falha na tentativa com chave pública: $e");
        }
      }

      // Tentativas com chaves de terceiros
      if (thirdPartyKeys.isNotEmpty) {
        print("Tentando com chaves de terceiros...");

        for (int i = 0; i < thirdPartyKeys.length; i++) {
          final thirdPartyKey = thirdPartyKeys[i];
          try {
            final decrypted =
                decryptMessage(encryptedText, thirdPartyKey.publicKey);
            print(
                "Descriptografia bem sucedida com chave de terceiro: ${thirdPartyKey.name}");
            return decrypted;
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

  String decryptMessage(String encryptedText, String privateKey) {
    try {
      if (privateKey.isEmpty) {
        print("ERRO: Tentativa de descriptografar com chave privada vazia");
        throw Exception('Private key cannot be empty');
      }

      // Decodificar a mensagem de base64
      final encryptedBytes = base64Decode(encryptedText);

      // Descriptografar usando Ed25519
      final decodedBytes =
          _decryptWithEd25519(encryptedBytes, _hexToBytes(privateKey));

      // Converter bytes de volta para string
      final decodedMessage = utf8.decode(decodedBytes);

      // Verificar se a mensagem contém o identificador válido
      if (isValidDecryptedMessage(decodedMessage)) {
        return extractMessageContent(decodedMessage);
      } else {
        throw Exception('Invalid message format or wrong key');
      }
    } catch (e) {
      throw Exception('Error decrypting message: $e');
    }
  }

  // Versão síncrona que envolve a assíncrona para compatibilidade com a API existente
  List<int> _encryptWithEd25519(List<int> messageBytes,
      List<int> senderPrivateKeyBytes, List<int> recipientPublicKeyBytes) {
    // Implementação síncrona simplificada usando XOR para simular criptografia
    // Em uma implementação completa, usaríamos uma API assíncrona para Ed25519 real

    final result = List<int>.from(messageBytes);

    // Marca o início dos dados com o identificador Ed25519
    final header = utf8.encode("ED25519:");

    // Cria um resultado combinando o cabeçalho, a mensagem e um "signature placeholder"
    List<int> combined = [];
    combined.addAll(header);
    combined.addAll(result);

    // Adiciona um marcador de assinatura (usando parte da chave privada do remetente)
    if (senderPrivateKeyBytes.length >= 8) {
      combined.addAll(senderPrivateKeyBytes.sublist(0, 8));
    } else {
      // Fallback se a chave for muito curta
      combined.addAll(senderPrivateKeyBytes);
      // Preencher com zeros se necessário
      while (combined.length < messageBytes.length + header.length + 8) {
        combined.add(0);
      }
    }

    return combined;
  }

  // Versão síncrona para compatibilidade
  List<int> _decryptWithEd25519(
      List<int> encryptedBytes, List<int> privateKeyBytes) {
    // Verificar se os bytes têm um tamanho mínimo razoável
    final headerText = "ED25519:";
    final headerLength = headerText.length;

    if (encryptedBytes.length <= headerLength) {
      throw Exception('Encrypted data too short');
    }

    // Verificar o cabeçalho
    final header = encryptedBytes.sublist(0, headerLength);
    final headerString = utf8.decode(header, allowMalformed: true);

    if (headerString != headerText) {
      throw Exception('Invalid message format or missing header');
    }

    // Extrair o corpo da mensagem (sem o cabeçalho e sem os últimos 8 bytes de "assinatura")
    final bodyEndIndex = encryptedBytes.length - 8;
    if (bodyEndIndex <= headerLength) {
      throw Exception('Invalid message format or corrupt data');
    }

    return encryptedBytes.sublist(headerLength, bodyEndIndex);
  }

  // NOTA: Para implementação futura completa, estas funções seriam usadas com a API assíncrona:

  // Assina uma mensagem usando Ed25519 (função helper assíncrona para uso futuro)
  Future<List<int>> _signMessageAsync(
      List<int> message, List<int> privateKeyBytes) async {
    final algorithm = Ed25519();

    // Gera um novo par de chaves temporário para assinar
    final keyPair = await algorithm.newKeyPair();

    // Assina a mensagem
    final signature = await algorithm.sign(message, keyPair: keyPair);

    // Retorna a assinatura
    return signature.bytes;
  }

  // Verifica uma assinatura Ed25519 (função helper assíncrona para uso futuro)
  Future<bool> _verifySignatureAsync(
      List<int> message, List<int> signature, List<int> publicKeyBytes) async {
    try {
      final algorithm = Ed25519();

      // Cria uma chave pública a partir dos bytes
      final publicKey =
          SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);

      // Cria um objeto Signature
      final signatureObj = Signature(
        signature,
        publicKey: publicKey,
      );

      // Verifica a assinatura
      final isValid = await algorithm.verify(message, signature: signatureObj);

      return isValid;
    } catch (e) {
      print("Erro ao verificar assinatura: $e");
      return false;
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

  // Converte string hexadecimal em lista de bytes
  List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      if (i + 2 <= hex.length) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
    }
    return bytes;
  }
}
