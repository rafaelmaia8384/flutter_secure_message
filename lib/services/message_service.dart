import 'dart:convert';
import 'package:get/get.dart';
import '../models/encrypted_message.dart';

class MessageService extends GetxService {
  Future<MessageService> init() async {
    print('Inicializing MessageService...');
    return this;
  }

  // Method to compact a message for sharing
  String compactMessageForSharing(EncryptedMessage message) {
    try {
      // Check if the message has encrypted items to share
      if (message.items.isEmpty) {
        print('Warning: Message has no encrypted items to share');

        // If there are no items to share, nothing to do
        throw Exception('message_empty_for_sharing'.tr);
      }

      // 1. Create compact JSON with minimized keys
      final Map<String, dynamic> compactJson = {
        // Include only the list of encrypted items
        't': message.items
            .map((item) => {
                  'e': item.encryptedText,
                })
            .toList(),
      };

      // 2. Convert to JSON string without extra spaces
      final String jsonString = jsonEncode(compactJson);

      // 3. Encode to base64
      final String base64String = base64Encode(utf8.encode(jsonString));

      // 4. Add a prefix to identify the format
      return "sec-msg:$base64String";
    } catch (e) {
      print('Error compacting message: $e');
      throw Exception('Error compacting message: $e');
    }
  }

  // Method to extract a message from a shared string
  EncryptedMessage? extractMessageFromSharedString(String sharedString) {
    try {
      // Clean the string, removing spaces, line breaks and other invisible characters
      String cleanedString = sharedString.trim();

      // Logs to help with debugging
      print('Trying to extract message from shared string...');
      print('Original length: ${sharedString.length}');
      print('Length after cleaning: ${cleanedString.length}');

      String jsonString;
      Map<String, dynamic> messageJson;

      // Check the format of the message
      if (cleanedString.startsWith("sec-msg:")) {
        print('Format detected: standard format');
        String base64String = cleanedString.substring("sec-msg:".length);

        try {
          // Decode the base64
          List<int> decodedBytes = base64Decode(base64String);
          jsonString = utf8.decode(decodedBytes);

          // Analyze the compact JSON
          final Map<String, dynamic> compactJson = json.decode(jsonString);
          print(
              'Successfully decoded compact JSON. Keys: ${compactJson.keys.join(", ")}');

          // Convert to standard format
          messageJson = {
            'senderPublicKey':
                compactJson.containsKey('s') ? compactJson['s'] : 'anonymous',
            'items': (compactJson['t'] as List?)
                    ?.map((item) => {
                          'encryptedText': item['e'],
                        })
                    .toList() ??
                [],
            'isImported': true,
          };
        } catch (e) {
          print('Error in decoding: $e');
          throw FormatException('Error in decoding: $e');
        }
      } else {
        // Check if it's a direct JSON string (without encoding)
        try {
          print('Trying to decode as direct JSON...');
          messageJson = json.decode(cleanedString);
          print('Direct JSON decoded successfully');
        } catch (e) {
          print('Not a valid message format: $e');
          return null;
        }
      }

      // Check basic JSON structure before trying to create the object
      if (!messageJson.containsKey('senderPublicKey')) {
        print(
            'Invalid JSON structure. Present keys: ${messageJson.keys.join(", ")}');
        return null;
      }

      // Check if 'items' is a list
      if (messageJson.containsKey('items') && !(messageJson['items'] is List)) {
        print('"items" is not a list');
        return null;
      }

      try {
        // Create EncryptedMessage object from JSON
        final message = EncryptedMessage.fromJson(messageJson);
        print('EncryptedMessage object created successfully.');
        if (message.items.isNotEmpty) {
          print('The message has ${message.items.length} items');
        }
        return message;
      } catch (e) {
        print('Error creating EncryptedMessage object: $e');
        return null;
      }
    } catch (e) {
      print('General error extracting message: $e');
      return null;
    }
  }
}
