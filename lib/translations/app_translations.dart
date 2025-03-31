import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'welcome': 'Secure Message',
          'secure_message':
              'Where your messages are encrypted and secure, no matter which chat you are using.',
          'authenticate': 'Authenticate to Continue',
          'biometric_not_available':
              'Biometric authentication is not available on this device',
          'setup_biometric':
              'Please set up biometric authentication in your device settings',
          'open_settings': 'Open Settings',
          'error': 'Error',
          'settings_error': 'Could not open settings',
          'logout': 'Logout',
          'encryption_keys': 'Encryption Keys',
          'my_key': 'My Key',
          'received_keys': 'Third Party Keys',
          'your_public_key': 'Your Public Key',
          'public_key_placeholder': 'Public key will be displayed here',
          'generate_first_key': 'Generate my keys',
          'contact_name': 'Contact Name',
          'enter_contact_name': 'Enter contact name',
          'public_key': 'Public Key',
          'delete_key': 'Delete Key',
          'delete_key_title': 'Delete Encryption Key',
          'delete_key_warning':
              'Are you sure you want to delete your encryption key? This action cannot be undone and you will need to generate a new key to continue using encrypted messages.',
          'generate_key_title': 'Generate Encryption Key',
          'generate_key_warning':
              'This will generate a new encryption key pair. Make sure you are in a secure location and that no one is watching your screen.',
          'key_deleted': 'Encryption key deleted successfully',
          'key_generated': 'New encryption key generated successfully',
          'delete': 'Delete',
          'generate': 'Generate',
          'cancel': 'Cancel',
          'success': 'Success',
          'copy_key': 'Copy Key',
          'share_key': 'Share Key',
          'show_qr': 'Show QR Code',
          'scan_qr_code': 'Scan QR Code',
          'key_copied': 'Public key copied to clipboard',
          'public_key_share': 'Share Public Key',
          'close': 'Close',
          'add_new_key': 'Add New Key',
          'add_key_title': 'Add Third Party Key',
          'add_key_manually': 'Enter Key Manually',
          'add_key_scan': 'Scan QR Code',
          'enter_key': 'Enter Public Key',
          'key_added': 'Key added successfully',
          'invalid_key': 'Invalid key format',
          'scan_qr': 'Scan QR Code',
          'scan_instructions': 'Position the QR code within the frame',
          'scan_success': 'Key scanned successfully',
          'scan_error': 'Failed to scan QR code',
          'error_loading_keys': 'Failed to load encryption keys',
          'error_generating_keys': 'Failed to generate encryption keys',
          'error_deleting_keys': 'Failed to delete encryption keys',
          'error_loading_third_party_keys': 'Failed to load third-party keys',
          'error_saving_third_party_keys': 'Failed to save third-party keys',
          'keys_generated': 'Encryption keys generated successfully',
          'keys_deleted': 'Encryption keys deleted successfully',
          'cannot_add_own_key':
              'You cannot add your own key to third-party keys',
          'delete_third_party_key_title': 'Delete Third Party Key',
          'delete_third_party_key_warning':
              'Are you sure you want to delete this third-party key? This action cannot be undone.',
          'new_message': 'New Message',
          'enter_message': 'Enter your message here...',
          'continue': 'Continue',
          'select_recipients': 'Select Recipients',
          'select_at_least_one_recipient':
              'Please select at least one recipient',
          'error_loading_messages': 'Failed to load messages',
          'error_saving_messages': 'Failed to save messages',
          'message_saved': 'Message saved successfully',
          'message_deleted': 'Message deleted successfully',
          'error_deleting_message': 'Failed to delete message',
          'authorized_third_parties': 'Authorized Third Parties',
          'no_messages': 'No messages yet',
          'delete_message_title': 'Delete Message',
          'delete_message_warning':
              'Are you sure you want to delete this message? This action cannot be undone.',
          'message_detail': 'Message Detail',
          'message_id': 'Message ID',
          'message_content': 'Content',
          'created_at': 'Created at',
          'message_not_for_you': 'This message was not encrypted for you',
          'error_decrypting': 'Error decrypting message',
          'error_encrypting_message': 'Error encrypting message',
          'me': 'Me',
          'message_from_you': 'Your Message',
          'message_from_other': 'Message from Contact',
          'sharing_not_implemented': 'Sharing is not implemented yet',
          'info': 'Information',
          'encrypting_message': 'Encrypting message...',
          'message_options': 'Message Options',
          'encrypt_message': 'Encrypt New Message',
          'import_message': 'Descrypt Message',
          'import': 'Import',
          'decrypting_message': 'Decrypting message...',
          'enter_encrypted_message': 'Paste the encrypted message here...',
          'invalid_message_format':
              'Invalid message format. The message should start with "sec-" followed by encoded data.',
          'warning': 'Warning',
          'yes': 'Yes',
          'no': 'No',
          'invalid_message_structure': 'The message structure is invalid.',
          'error_importing_message': 'Error importing the message.',
          'message_imported': 'Message imported successfully.',
          'export_message': 'Export',
          'export_message_instructions':
              'Here is the encrypted message that you can share with others:',
          'copy': 'Copy',
          'message_copied': 'Message copied to clipboard',
          'no_third_party_keys': 'No Third Party Keys',
          'no_third_party_keys_title': 'No Third Party Keys',
          'no_third_party_keys_message':
              'You need to add at least one third party key before creating encrypted messages.',
          'add_third_party_keys_message':
              'Ask for your contacts\' public keys to send encrypted messages to them.',
          'add_third_party_key': 'Add Key',
          'processing_message': 'Processing message...',
          'message_from_unknown': 'Unknown Contact',
          'sender': 'Sender',
          'message_actions': 'Message Actions',
          'create_new_message': 'Create New Message',
          'confirm_delete': 'Confirm Deletion',
          'confirm_delete_message':
              'Are you sure you want to delete this message?',
          'message_options_title': 'Message Options',
          'no_messages_description':
              'Your inbox is empty. Create or import a message to get started.',
          'contact_name_required': 'Contact name is required',
          'key_required': 'Public key is required',
          'key_already_exists': 'This key already exists in your contacts',
          'public_key_info':
              'Only people who have your public key can send encrypted messages to you.',
          'start_messaging': 'Start Messaging',
          'no_public_key_title': 'No Encryption Key',
          'need_public_key_for_import':
              'You need to generate your own encryption key before you can import encrypted messages.',
          'generate_key': 'Generate Key',
          'add': 'Add',
          'key_required_title': 'Encryption Key Required',
          'key_required_message':
              'You need to generate an encryption key before you can create encrypted messages.',
          'no_recipients_title': 'No Recipients',
          'no_recipients_message':
              'You need to add at least one contact key before you can create encrypted messages.',
          'add_recipients': 'Add Recipients',
          'no_personal_key_warning': 'You do not have a personal key',
          'no_personal_key_error':
              'You do not have a personal key. You will not be able to decrypt this message later.',
          'loading_messages': 'Loading messages...',
          'created_messages': 'Created',
          'imported_messages': 'Imported',
          'no_created_messages': 'No created messages',
          'no_imported_messages': 'No imported messages',
          'no_created_messages_description':
              'Create a new encrypted message to send to your contacts',
          'no_imported_messages_description':
              'Import an encrypted message that was shared with you',
          'generating_keys': 'Generating Keys',
          'please_wait':
              'Please wait while we generate your encryption keys...',
          'key_generation_failed':
              'Failed to generate encryption keys. Please try again.',
          'key_generation_error': 'An error occurred while generating keys',
          'ok': 'OK',
          'replace_key': 'Replace Key',
          'replace_key_title': 'Replace Encryption Key',
          'replace_key_warning':
              'Are you sure you want to replace your encryption key? This action cannot be undone and any previously encrypted messages will no longer be decryptable with the new key. Make sure you have saved any important messages.',
          'keys_replaced': 'Encryption keys replaced successfully',
          'error_replacing_keys': 'Failed to replace encryption keys',
          'replace': 'Replace',

          // Encryption Keys Guide translations
          'encryption_keys_guide': 'Encryption Keys Guide',
          'got_it': 'Got it',
          'what_are_encryption_keys': 'What are encryption keys?',
          'encryption_keys_description':
              'Encryption keys are digital codes used to encrypt and decrypt messages. They ensure that only the intended recipient can read the messages you send.',
          'public_vs_private': 'Public vs Private Keys',
          'public_vs_private_description':
              'This app uses asymmetric encryption with key pairs:\n• Private Key: Kept secret on your device. Never share it.\n• Public Key: Can be shared with others who want to send you encrypted messages.',
          'how_encryption_works': 'How encryption works',
          'how_encryption_works_description':
              'This app uses a hybrid encryption system:\n1. X25519 algorithm for secure key exchange (curve25519)\n2. AES-GCM 256-bit for symmetric encryption of messages\n\nWhen you send a message:\n• The app generates a random AES key\n• Your message is encrypted with this AES key\n• The AES key is encrypted with recipient\'s X25519 public key\n• Only the recipient\'s private key can unlock the AES key and decrypt the message',
          'sharing_public_key': 'Sharing your public key',
          'sharing_public_key_description':
              'Share your public key with others so they can send you encrypted messages. You can share it via:\n• QR Code\n• Copy & Paste\n• Share button\n\nYour public key is safe to share - it cannot be used to decrypt messages.',
          'managing_others_keys': 'Managing others\' keys',
          'managing_others_keys_description':
              'Add public keys from your contacts to send them encrypted messages. You can:\n• Scan their QR code\n• Enter their key manually\n• Give them a recognizable name',
          'security_best_practices': 'Security best practices',
          'security_best_practices_description':
              '• This app never connects to the internet nor stores any data on servers\n• This app uses military-grade encryption (X25519 and AES-GCM 256-bit)\n• Messages are end-to-end encrypted and never stored on any device\n• Your private key never leaves your device\n• All encrypted data includes authentication codes to prevent tampering\n• Generate a new key pair if you suspect your device is compromised\n• You can replace your keys, but remember that previously encrypted messages can only be decrypted with the original key\n• Verify the identity of people whose public keys you add\n• Use secure channels when sharing public keys',

          // Key regeneration
          'regenerate_keys': 'Regenerate Keys',
          'regenerate_keys_title': 'Regenerate Encryption Keys',
          'regenerate_keys_warning':
              'This will delete your current keys and generate new ones. All previous messages will not be decryptable anymore. This action cannot be undone.',
          'regenerate': 'Regenerate',
          'keys_regenerated':
              'Keys regenerated successfully. Previous messages will no longer be decryptable.',
          'keys_regeneration_failed':
              'Failed to regenerate keys. Please try again.',
          'refresh': 'Refresh',

          // Key testing
          'test_keys': 'Test Keys',
          'testing_keys': 'Testing Keys',
          'no_keys_to_test': 'No keys available to test',
          'keys_test_passed':
              'Key test passed successfully! Your keys are working properly.',
          'keys_test_failed':
              'Key test failed. Your keys may not be working correctly.',
          'error_testing_keys': 'An error occurred while testing keys',
        },
      };
}
