import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_message/services/key_service.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'dart:async'; // Import for StreamController

// Define the callback type matching the interface
typedef FlutterSecureStorageCallback = void Function(String? value);

// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};
  // Add StreamController for onCupertinoProtectedDataAvailabilityChanged
  final StreamController<bool> _availabilityController =
      StreamController<bool>.broadcast();

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    String? oldValue = _storage[key];
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
    // Notify listeners if value changed
    if (_listeners.containsKey(key)) {
      if (oldValue != value) {
        // Pass only the value to the listener
        _listeners[key]?.forEach((listener) => listener(value));
      }
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_storage.containsKey(key)) {
      _storage.remove(key);
      // Notify listeners if key existed
      if (_listeners.containsKey(key)) {
        // Pass null as value for deletion
        _listeners[key]?.forEach((listener) => listener(null));
      }
    }
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.unmodifiable(_storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final keysToRemove = _storage.keys.toList();
    _storage.clear();
    // Notify listeners for all removed keys
    keysToRemove.forEach((key) {
      if (_listeners.containsKey(key)) {
        // Pass null as value for deletion
        _listeners[key]?.forEach((listener) => listener(null));
      }
    });
    _listeners.clear(); // Clear all listeners on deleteAll
  }

  // Implement the remaining methods with default behavior or mocks as needed
  @override
  // ignore: unused_element
  AndroidOptions get aOptions => const AndroidOptions();

  @override
  // ignore: unused_element
  IOSOptions get iOptions => const IOSOptions();

  @override
  // ignore: unused_element
  LinuxOptions get lOptions => const LinuxOptions();

  @override
  // ignore: unused_element
  MacOsOptions get mOptions => const MacOsOptions();

  @override
  // ignore: unused_element
  WindowsOptions get wOptions => const WindowsOptions();

  @override
  // ignore: unused_element
  WebOptions get webOptions => const WebOptions();

  // Correct implementation for isCupertinoProtectedDataAvailable (as a method)
  @override
  Future<bool> isCupertinoProtectedDataAvailable() async {
    // Mock implementation: return false or a configurable value
    return false;
  }

  // Implement the getter for the stream
  @override
  Stream<bool> get onCupertinoProtectedDataAvailabilityChanged =>
      _availabilityController.stream;

  // Map to hold listeners (Callback type updated)
  final Map<String, List<FlutterSecureStorageCallback>> _listeners = {};

  @override
  void registerListener(
      {required String key, required FlutterSecureStorageCallback listener}) {
    _listeners.putIfAbsent(key, () => []).add(listener);
  }

  @override
  void unregisterListener(
      {required String key, required FlutterSecureStorageCallback listener}) {
    _listeners[key]?.remove(listener);
    if (_listeners[key]?.isEmpty ?? false) {
      _listeners.remove(key);
    }
  }

  @override
  void unregisterAllListenersForKey({required String key}) {
    _listeners.remove(key);
  }

  @override
  void unregisterAllListeners() {
    _listeners.clear();
  }

  // Method to simulate availability change (for testing purposes)
  void simulateCupertinoAvailabilityChange(bool available) {
    _availabilityController.add(available);
  }

  // Clean up stream controller
  void dispose() {
    _availabilityController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyService keyService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() async {
    // Reset GetX bindings and inject mock storage
    Get.reset();
    mockStorage = MockFlutterSecureStorage();
    // Inject the KeyService with the mock storage
    keyService = KeyService();
    // Manually assign the mock storage. In a real app, use dependency injection.
    // This requires modifying KeyService slightly or using a testing setup that allows injection.
    // For now, we'll assume KeyService can be instantiated and we can manually manipulate its state for testing
    // or that it fetches the storage via Get.put/find which we can mock.
    Get.put<FlutterSecureStorage>(mockStorage); // Make mock available via GetX

    // Initialize KeyService (it might try to load keys from storage)
    await keyService.init();
  });

  tearDown(() {
    Get.reset(); // Clean up GetX bindings after each test
  });

  test('Test Self Encryption', () async {
    // Generate new keys
    final generated = await keyService.generateNewKeys();
    expect(generated, isTrue, reason: "Key generation should succeed.");
    expect(keyService.hasKeys.value, isTrue,
        reason: "Service should report having keys.");

    // Get user keys
    final publicKeyStr = keyService.publicKey.value;
    final privateKeyStr = keyService.privateKey.value;

    expect(publicKeyStr, isNotEmpty,
        reason: "Public key should not be empty after generation.");
    expect(privateKeyStr, isNotEmpty,
        reason: "Private key should not be empty after generation.");

    // Test message
    final testMessage = "Testing self encryption.";

    // Encrypt message using the service
    final encryptedBase64 =
        await keyService.encryptMessage(testMessage, publicKeyStr);
    expect(encryptedBase64, isNotEmpty,
        reason: "Encrypted message should not be empty.");

    // Decrypt message using the service
    final decryptedMessage =
        await keyService.decryptMessage(encryptedBase64, privateKeyStr);

    // Check if content is correct
    expect(decryptedMessage, equals(testMessage),
        reason: "Decrypted message should match the original.");
  });

  test('Test User-to-User Communication', () async {
    // Generate keys for Alice (current user)
    final generatedAlice = await keyService.generateNewKeys();
    expect(generatedAlice, isTrue,
        reason: "Alice's key generation should succeed.");
    final alicePublicKey = keyService.publicKey.value;
    final alicePrivateKey = keyService.privateKey.value;

    // Create keys for test user (Bob) manually for isolation
    final keyExchangeAlgorithm = X25519();
    final bobKeyPair = await keyExchangeAlgorithm.newKeyPair();
    final bobPrivateKeyBytes = await bobKeyPair.extractPrivateKeyBytes();
    final bobPublicKeyObj = await bobKeyPair.extractPublicKey();
    final bobPublicKeyBytes = bobPublicKeyObj.bytes;

    final bobPublicKey = base64Encode(bobPublicKeyBytes);
    final bobPrivateKey = base64Encode(bobPrivateKeyBytes);

    // Test message
    final testMessage = "Testing communication between Alice and Bob.";

    // --- Test 1: Alice encrypts for Bob ---
    // Alice encrypts message for Bob using Bob's public key
    final encryptedForBob =
        await keyService.encryptMessage(testMessage, bobPublicKey);
    expect(encryptedForBob, isNotEmpty,
        reason: "Encrypted message for Bob should not be empty.");

    // Simulate Bob decrypting the message. Bob needs Alice's public key.
    // Bob decrypts message with his private key and Alice's public key (passed implicitly via encrypted structure)
    // For decryption, the KeyService needs the recipient's private key.
    // We need a way to simulate Bob's KeyService instance or directly call decrypt logic.
    // Let's temporarily switch the service's keys to Bob's perspective for decryption.
    // This is a bit hacky for a unit test; ideally, decryption logic might be refactored
    // to not depend solely on the service's current key state.

    // To properly test, we'd instantiate another KeyService for Bob or make decrypt static/inject keys.
    // For simplicity here, we'll call decrypt directly, providing Bob's keys.
    // We need to ensure decryptMessage uses the provided privateKeyStr and the sender's public key from the payload.
    final decryptedByBob =
        await keyService.decryptMessage(encryptedForBob, bobPrivateKey);

    expect(decryptedByBob, equals(testMessage),
        reason: "Bob should decrypt Alice's message correctly.");

    // --- Test 2: Bob encrypts for Alice ---
    // Simulate Bob encrypting a message for Alice.
    // Bob needs his private key and Alice's public key.
    // We'll simulate this by creating a temporary message structure or using the encrypt method carefully.
    // Let's assume Bob's KeyService instance would do this:
    // We need to provide Bob's private key and Alice's public key to the encryption logic.
    // The current encryptMessage uses the service's keys. We need to adapt this.

    // Option 1: Modify encryptMessage to accept sender keys (better design).
    // Option 2: Hackily set the service state to Bob's keys temporarily. (Chosen for now due to existing structure)

    // Save Alice's state
    final originalPublicKey = keyService.publicKey.value;
    final originalPrivateKey = keyService.privateKey.value;
    final originalHasKeys = keyService.hasKeys.value;

    // Set service state to Bob's keys
    keyService.publicKey.value = bobPublicKey;
    keyService.privateKey.value = bobPrivateKey;
    keyService.hasKeys.value = true; // Assume Bob has keys

    // Bob encrypts message for Alice using Alice's public key
    final encryptedForAlice =
        await keyService.encryptMessage(testMessage, alicePublicKey);
    expect(encryptedForAlice, isNotEmpty,
        reason: "Encrypted message for Alice should not be empty.");

    // Restore Alice's state before decryption
    keyService.publicKey.value = originalPublicKey;
    keyService.privateKey.value = originalPrivateKey;
    keyService.hasKeys.value = originalHasKeys;

    // Alice decrypts the message using her private key
    final decryptedByAlice =
        await keyService.decryptMessage(encryptedForAlice, alicePrivateKey);

    expect(decryptedByAlice, equals(testMessage),
        reason: "Alice should decrypt Bob's message correctly.");
  });
}
