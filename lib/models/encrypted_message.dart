import 'package:flutter/foundation.dart';

class EncryptedMessage {
  final String id;
  final String senderPublicKey;
  final List<EncryptedMessageItem> items;
  final DateTime createdAt;

  EncryptedMessage({
    required this.id,
    required this.senderPublicKey,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderPublicKey': senderPublicKey,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      id: json['id'] as String,
      senderPublicKey: json['senderPublicKey'] as String,
      items: (json['items'] as List)
          .map((item) => EncryptedMessageItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
  }
}

class EncryptedMessageItem {
  final String encryptedText;
  final DateTime createdAt;

  EncryptedMessageItem({
    required this.encryptedText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'encryptedText': encryptedText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EncryptedMessageItem.fromJson(Map<String, dynamic> json) {
    return EncryptedMessageItem(
      encryptedText: json['encryptedText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
  }
}
