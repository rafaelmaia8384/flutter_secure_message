class EncryptedMessage {
  final String senderPublicKey;
  final List<EncryptedMessageItem> items;
  final bool isImported;

  EncryptedMessage({
    required this.senderPublicKey,
    required this.items,
    this.isImported = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      senderPublicKey: json['senderPublicKey'] as String? ?? '',
      items: (json['items'] as List)
          .map((item) => EncryptedMessageItem.fromJson(item))
          .toList(),
      isImported: json['isImported'] as bool? ?? false,
    );
  }
}

class EncryptedMessageItem {
  final String encryptedText;

  EncryptedMessageItem({
    required this.encryptedText,
  });

  Map<String, dynamic> toJson() => {
        'encryptedText': encryptedText,
      };

  factory EncryptedMessageItem.fromJson(Map<String, dynamic> json) {
    return EncryptedMessageItem(
      encryptedText: json['encryptedText'] as String,
    );
  }
}
