class RecipientMessage {
  final String name;
  final String publicKey;
  final String encryptedText;

  RecipientMessage({
    required this.name,
    required this.publicKey,
    required this.encryptedText,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'publicKey': publicKey,
      'encryptedText': encryptedText,
    };
  }

  factory RecipientMessage.fromJson(Map<String, dynamic> json) {
    return RecipientMessage(
      name: json['name'] as String,
      publicKey: json['publicKey'] as String,
      encryptedText: json['encryptedText'] as String,
    );
  }
}
