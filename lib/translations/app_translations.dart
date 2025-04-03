import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'welcome': 'Secure Message',
          'secure_message':
              'You don\'t need to trust intermediaries to have a secure conversation.',
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
              'Invalid message format. The message should start with "sec-msg:" followed by encoded data.',
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
          'decrypted_message': 'Decrypted',
          'encrypt_and_share': 'Encrypt and Share',

          // HomePage specific
          'encrypt_new_message': 'Encrypt new Message',
          'decrypt_message': 'Decrypt Message',
          'how_it_works': 'How it works',
          'buy_me_a_coffee': 'Buy me a coffee',
          'internet_connection_info':
              'This app does not require an internet connection. It uses a hybrid encryption system to encrypt and decrypt messages.',

          // Encryption Keys Guide translations
          'encryption_keys_guide': 'Keys Guide',
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
          'encrypt_and_share': 'Encrypt and Share',

          // Key testing
          'test_keys': 'Test Keys',
          'testing_keys': 'Testing Keys',
          'no_keys_to_test': 'No keys available to test',
          'keys_test_passed':
              'Key test passed successfully! Your keys are working properly.',
          'keys_test_failed':
              'Key test failed. Your keys may not be working correctly.',
          'error_testing_keys': 'An error occurred while testing keys',

          // How to Get Started Guide translations
          'how_to_get_started_title': 'How to Get Started',
          'how_to_get_started_step1_title': '1. Share Your Public Key',
          'how_to_get_started_step1_desc':
              'Share your Public Key (found in \'My Key\') with contacts you want to receive messages from. They need this to encrypt messages for you.',
          'how_to_get_started_step2_title': '2. Add Contact Keys',
          'how_to_get_started_step2_desc':
              'Go to \'Third Party Keys\', tap \'Add New Key\', and add the Public Keys of contacts you want to send messages to. Give them recognizable names.',
          'how_to_get_started_step3_title': '3. Start Messaging',
          'how_to_get_started_step3_desc':
              'Use \'Encrypt new Message\' to send secure messages to your added contacts, or \'Decrypt Message\' to import and read messages sent to you.',

          // Buy me a coffee Dialog translations
          'buy_me_a_coffee_title': 'Support the Developer',
          'buy_me_a_coffee_message':
              'If you find this app useful, please consider supporting its development with a small donation. It helps keep the app free and ad-free!',
          'buy_me_a_coffee_button': 'Buy me a coffee',
          'error_launching_url': 'Could not open the link',
        },
        'pt_BR': {
          'welcome': 'Mensagem Segura',
          'secure_message':
              'Você não precisa confiar em intermediários para ter uma conversa segura.',
          'authenticate': 'Autentique-se para Continuar',
          'biometric_not_available':
              'Autenticação biométrica não está disponível neste dispositivo',
          'setup_biometric':
              'Por favor, configure a autenticação biométrica nas configurações do seu dispositivo',
          'open_settings': 'Abrir Configurações',
          'error': 'Erro',
          'settings_error': 'Não foi possível abrir as configurações',
          'logout': 'Sair',
          'encryption_keys': 'Chaves de Criptografia',
          'my_key': 'Minha Chave',
          'received_keys': 'Chaves de Terceiros',
          'your_public_key': 'Sua Chave Pública',
          'public_key_placeholder': 'A chave pública será exibida aqui',
          'generate_first_key': 'Gerar minhas chaves',
          'contact_name': 'Nome do Contato',
          'enter_contact_name': 'Digite o nome do contato',
          'public_key': 'Chave Pública',
          'delete_key': 'Excluir Chave',
          'delete_key_title': 'Excluir Chave de Criptografia',
          'delete_key_warning':
              'Tem certeza de que deseja excluir sua chave de criptografia? Esta ação não pode ser desfeita e você precisará gerar uma nova chave para continuar usando mensagens criptografadas.',
          'generate_key_title': 'Gerar Chave de Criptografia',
          'generate_key_warning':
              'Isso gerará um novo par de chaves de criptografia. Certifique-se de estar em um local seguro e que ninguém esteja olhando sua tela.',
          'key_deleted': 'Chave de criptografia excluída com sucesso',
          'key_generated': 'Nova chave de criptografia gerada com sucesso',
          'delete': 'Excluir',
          'generate': 'Gerar',
          'cancel': 'Cancelar',
          'success': 'Sucesso',
          'copy_key': 'Copiar Chave',
          'share_key': 'Compartilhar Chave',
          'show_qr': 'Mostrar Código QR',
          'scan_qr_code': 'Escanear Código QR',
          'key_copied': 'Chave pública copiada para a área de transferência',
          'public_key_share': 'Compartilhar Chave Pública',
          'close': 'Fechar',
          'add_new_key': 'Adicionar Nova Chave',
          'add_key_title': 'Adicionar Chave de Terceiro',
          'add_key_manually': 'Inserir Chave Manualmente',
          'add_key_scan': 'Escanear Código QR',
          'enter_key': 'Digite a Chave Pública',
          'key_added': 'Chave adicionada com sucesso',
          'invalid_key': 'Formato de chave inválido',
          'scan_qr': 'Escanear Código QR',
          'scan_instructions': 'Posicione o código QR dentro da moldura',
          'scan_success': 'Chave escaneada com sucesso',
          'scan_error': 'Falha ao escanear o código QR',
          'error_loading_keys': 'Falha ao carregar as chaves de criptografia',
          'error_generating_keys': 'Falha ao gerar as chaves de criptografia',
          'error_deleting_keys': 'Falha ao excluir as chaves de criptografia',
          'error_loading_third_party_keys':
              'Falha ao carregar as chaves de terceiros',
          'error_saving_third_party_keys':
              'Falha ao salvar as chaves de terceiros',
          'keys_generated': 'Chaves de criptografia geradas com sucesso',
          'keys_deleted': 'Chaves de criptografia excluídas com sucesso',
          'cannot_add_own_key':
              'Você não pode adicionar sua própria chave às chaves de terceiros',
          'delete_third_party_key_title': 'Excluir Chave de Terceiro',
          'delete_third_party_key_warning':
              'Tem certeza de que deseja excluir esta chave de terceiro? Esta ação não pode ser desfeita.',
          'new_message': 'Nova Mensagem',
          'enter_message': 'Digite sua mensagem aqui...',
          'continue': 'Continuar',
          'select_recipients': 'Selecionar Destinatários',
          'select_at_least_one_recipient':
              'Por favor, selecione pelo menos um destinatário',
          'error_loading_messages': 'Falha ao carregar as mensagens',
          'error_saving_messages': 'Falha ao salvar as mensagens',
          'message_saved': 'Mensagem salva com sucesso',
          'message_deleted': 'Mensagem excluída com sucesso',
          'error_deleting_message': 'Falha ao excluir a mensagem',
          'authorized_third_parties': 'Terceiros Autorizados',
          'no_messages': 'Nenhuma mensagem ainda',
          'delete_message_title': 'Excluir Mensagem',
          'delete_message_warning':
              'Tem certeza de que deseja excluir esta mensagem? Esta ação não pode ser desfeita.',
          'message_detail': 'Detalhes da Mensagem',
          'message_id': 'ID da Mensagem',
          'message_content': 'Conteúdo',
          'created_at': 'Criada em',
          'message_not_for_you':
              'Esta mensagem não foi criptografada para você',
          'error_decrypting': 'Erro ao descriptografar a mensagem',
          'error_encrypting_message': 'Erro ao criptografar a mensagem',
          'me': 'Eu',
          'message_from_you': 'Sua Mensagem',
          'message_from_other': 'Mensagem do Contato',
          'sharing_not_implemented':
              'Compartilhamento ainda não foi implementado',
          'info': 'Informação',
          'encrypting_message': 'Criptografando mensagem...',
          'message_options': 'Opções da Mensagem',
          'encrypt_message': 'Criptografar Nova Mensagem',
          'import_message': 'Descriptografar Mensagem',
          'import': 'Importar',
          'decrypting_message': 'Descriptografando mensagem...',
          'enter_encrypted_message': 'Cole a mensagem criptografada aqui...',
          'invalid_message_format':
              'Formato de mensagem inválido. A mensagem deve começar com "sec-msg:" seguido de dados codificados.',
          'warning': 'Atenção',
          'yes': 'Sim',
          'no': 'Não',
          'invalid_message_structure': 'A estrutura da mensagem é inválida.',
          'error_importing_message': 'Erro ao importar a mensagem.',
          'message_imported': 'Mensagem importada com sucesso.',
          'export_message': 'Exportar',
          'export_message_instructions':
              'Aqui está a mensagem criptografada que você pode compartilhar com outros:',
          'copy': 'Copiar',
          'message_copied': 'Mensagem copiada para a área de transferência',
          'no_third_party_keys': 'Nenhuma Chave de Terceiro',
          'no_third_party_keys_title': 'Nenhuma Chave de Terceiro',
          'no_third_party_keys_message':
              'Você precisa adicionar pelo menos uma chave de terceiro antes de criar mensagens criptografadas.',
          'add_third_party_keys_message':
              'Peça as chaves públicas dos seus contatos para enviar mensagens criptografadas a eles.',
          'add_third_party_key': 'Adicionar Chave',
          'processing_message': 'Processando mensagem...',
          'message_from_unknown': 'Contato Desconhecido',
          'sender': 'Remetente',
          'message_actions': 'Ações da Mensagem',
          'create_new_message': 'Criar Nova Mensagem',
          'confirm_delete': 'Confirmar Exclusão',
          'confirm_delete_message':
              'Tem certeza de que deseja excluir esta mensagem?',
          'message_options_title': 'Opções da Mensagem',
          'no_messages_description':
              'Sua caixa de entrada está vazia. Crie ou importe uma mensagem para começar.',
          'contact_name_required': 'Nome do contato é obrigatório',
          'key_required': 'Chave pública é obrigatória',
          'key_already_exists': 'Esta chave já existe em seus contatos',
          'public_key_info':
              'Apenas pessoas que possuem sua chave pública podem enviar mensagens criptografadas para você.',
          'start_messaging': 'Começar a Mensagem',
          'no_public_key_title': 'Sem Chave de Criptografia',
          'need_public_key_for_import':
              'Você precisa gerar sua própria chave de criptografia antes de poder importar mensagens criptografadas.',
          'generate_key': 'Gerar Chave',
          'add': 'Adicionar',
          'key_required_title': 'Chave de Criptografia Obrigatória',
          'key_required_message':
              'Você precisa gerar uma chave de criptografia antes de poder criar mensagens criptografadas.',
          'no_recipients_title': 'Sem Destinatários',
          'no_recipients_message':
              'Você precisa adicionar pelo menos um contato antes de poder criar mensagens criptografadas.',
          'add_recipients': 'Adicionar Destinatários',
          'no_personal_key_warning': 'Você não possui uma chave pessoal',
          'no_personal_key_error':
              'Você não possui uma chave pessoal. Não será possível descriptografar esta mensagem posteriormente.',
          'loading_messages': 'Carregando mensagens...',
          'created_messages': 'Criadas',
          'imported_messages': 'Importadas',
          'no_created_messages': 'Nenhuma mensagem criada',
          'no_imported_messages': 'Nenhuma mensagem importada',
          'no_created_messages_description':
              'Crie uma nova mensagem criptografada para enviar aos seus contatos',
          'no_imported_messages_description':
              'Importe uma mensagem criptografada que foi compartilhada com você',
          'generating_keys': 'Gerando Chaves',
          'please_wait':
              'Por favor, aguarde enquanto geramos suas chaves de criptografia...',
          'key_generation_failed':
              'Falha ao gerar as chaves de criptografia. Por favor, tente novamente.',
          'key_generation_error': 'Ocorreu um erro ao gerar as chaves',
          'ok': 'OK',
          'replace_key': 'Substituir Chave',
          'replace_key_title': 'Substituir Chave de Criptografia',
          'replace_key_warning':
              'Tem certeza de que deseja substituir sua chave de criptografia? Esta ação não pode ser desfeita e quaisquer mensagens previamente criptografadas não poderão ser descriptografadas com a nova chave. Certifique-se de ter salvo qualquer mensagem importante.',
          'keys_replaced': 'Chaves de criptografia substituídas com sucesso',
          'error_replacing_keys':
              'Falha ao substituir as chaves de criptografia',
          'replace': 'Substituir',
          'decrypted_message': 'Descriptografada',
          'encrypt_and_share': 'Encriptar e Compartilhar',

          // Específico da HomePage
          'encrypt_new_message': 'Criptografar nova Mensagem',
          'decrypt_message': 'Descriptografar Mensagem',
          'how_it_works': 'Como Funciona',
          'buy_me_a_coffee': 'Me pague um café',
          'internet_connection_info':
              'Este aplicativo não requer conexão com a internet. Ele utiliza um sistema de criptografia híbrido para criptografar e descriptografar mensagens.',

          // Traduções do Guia de Chaves de Criptografia
          'encryption_keys_guide': 'Guia de Chaves',
          'got_it': 'Entendi',
          'what_are_encryption_keys': 'O que são chaves de criptografia?',
          'encryption_keys_description':
              'Chaves de criptografia são códigos digitais usados para criptografar e descriptografar mensagens. Elas garantem que apenas o destinatário pretendido possa ler as mensagens enviadas.',
          'public_vs_private': 'Chaves Públicas vs Privadas',
          'public_vs_private_description':
              'Este aplicativo utiliza criptografia assimétrica com pares de chaves:\n• Chave Privada: Mantida em segredo no seu dispositivo. Nunca a compartilhe.\n• Chave Pública: Pode ser compartilhada com quem deseja enviar mensagens criptografadas para você.',
          'how_encryption_works': 'Como a criptografia funciona',
          'how_encryption_works_description':
              'Este aplicativo utiliza um sistema de criptografia híbrido:\n1. Algoritmo X25519 para troca segura de chaves (curve25519)\n2. AES-GCM 256-bit para criptografia simétrica das mensagens\n\nAo enviar uma mensagem:\n• O aplicativo gera uma chave AES aleatória\n• Sua mensagem é criptografada com essa chave AES\n• A chave AES é criptografada com a chave pública X25519 do destinatário\n• Apenas a chave privada do destinatário pode desbloquear a chave AES e descriptografar a mensagem',
          'sharing_public_key': 'Compartilhando sua chave pública',
          'sharing_public_key_description':
              'Compartilhe sua chave pública com outros para que possam enviar mensagens criptografadas para você. Você pode compartilhá-la via:\n• Código QR\n• Copiar e Colar\n• Botão de compartilhamento\n\nSua chave pública é segura para compartilhar – ela não pode ser utilizada para descriptografar mensagens.',
          'managing_others_keys': 'Gerenciando chaves de terceiros',
          'managing_others_keys_description':
              'Adicione chaves públicas dos seus contatos para enviar mensagens criptografadas para eles. Você pode:\n• Escanear o código QR\n• Inserir a chave manualmente\n• Atribuir um nome identificável',
          'security_best_practices': 'Boas práticas de segurança',
          'security_best_practices_description':
              '• Este aplicativo nunca se conecta à internet nem armazena dados em servidores\n• Utiliza criptografia de nível militar (X25519 e AES-GCM 256-bit)\n• As mensagens são criptografadas de ponta a ponta e nunca armazenadas em nenhum dispositivo\n• Sua chave privada nunca sai do seu dispositivo\n• Todos os dados criptografados incluem códigos de autenticação para evitar adulterações\n• Gere um novo par de chaves se suspeitar que seu dispositivo foi comprometido\n• Você pode substituir suas chaves, mas lembre-se de que mensagens previamente criptografadas só poderão ser descriptografadas com a chave original\n• Verifique a identidade das pessoas cujas chaves públicas você adiciona\n• Utilize canais seguros ao compartilhar chaves públicas',

          // Regeneração de Chaves
          'regenerate_keys': 'Regenerar Chaves',
          'regenerate_keys_title': 'Regenerar Chaves de Criptografia',
          'regenerate_keys_warning':
              'Isso excluirá suas chaves atuais e gerará novas. Todas as mensagens anteriores não poderão mais ser descriptografadas. Esta ação não pode ser desfeita.',
          'regenerate': 'Regenerar',
          'keys_regenerated':
              'Chaves regeneradas com sucesso. Mensagens anteriores não poderão mais ser descriptografadas.',
          'keys_regeneration_failed':
              'Error al regenerar las claves. Por favor, inténtalo de nuevo.',
          'refresh': 'Atualizar',
          'encrypt_and_share': 'Encriptar e Compartilhar',

          // Teste de Chaves
          'test_keys': 'Testar Chaves',
          'testing_keys': 'Testando Chaves',
          'no_keys_to_test': 'Nenhuma chave disponível para teste',
          'keys_test_passed':
              'Teste de chave concluído com sucesso! Suas chaves estão funcionando corretamente.',
          'keys_test_failed':
              'Teste de chave falhou. Suas chaves podem não estar funcionando corretamente.',
          'error_testing_keys': 'Ocorreu um erro ao testar as chaves',

          // Traduções do Guia de Como Começar
          'how_to_get_started_title': 'Como Começar',
          'how_to_get_started_step1_title': '1. Compartilhe Sua Chave Pública',
          'how_to_get_started_step1_desc':
              'Compartilhe sua Chave Pública (encontrada em "Minha Chave") com os contatos dos quais deseja receber mensagens. Eles precisam dela para criptografar mensagens para você.',
          'how_to_get_started_step2_title': '2. Adicione Chaves de Contato',
          'how_to_get_started_step2_desc':
              'Vá em "Chaves de Terceiros", toca em "Adicionar Nova Chave" e adicione as chaves públicas dos contatos para os quais deseja enviar mensagens. Dê a elas nomes identificáveis.',
          'how_to_get_started_step3_title': '3. Crie uma Mensagem',
          'how_to_get_started_step3_desc':
              'Utilize "Criptografar nova Mensagem" para enviar mensagens seguras aos seus contatos adicionados, ou "Descriptografar Mensagem" para importar e ler mensagens enviadas para você.',

          // Diálogo "Me pague um café"
          'buy_me_a_coffee_title': 'Apoie o Desenvolvedor',
          'buy_me_a_coffee_message':
              'Se você achar este aplicativo útil, considere apoiar seu desenvolvimento com uma pequena doação. Isso ajuda a manter o app gratuito e sem anúncios!',
          'buy_me_a_coffee_button': 'Me pague um café',
          'error_launching_url': 'Não foi possível abrir o link',
        },
        'es': {
          'welcome': 'Mensaje Seguro',
          'secure_message':
              'No necesitas confiar en intermediarios para tener una conversación segura.',
          'authenticate': 'Autentícate para Continuar',
          'biometric_not_available':
              'La autenticación biométrica no está disponible en este dispositivo',
          'setup_biometric':
              'Por favor, configura la autenticación biométrica en los ajustes de tu dispositivo',
          'open_settings': 'Abrir Ajustes',
          'error': 'Error',
          'settings_error': 'No se pudieron abrir los ajustes',
          'logout': 'Cerrar sesión',
          'encryption_keys': 'Claves de Encriptación',
          'my_key': 'Mi Clave',
          'received_keys': 'Claves de Terceros',
          'your_public_key': 'Tu Clave Pública',
          'public_key_placeholder': 'La clave pública se mostrará aquí',
          'generate_first_key': 'Generar mis claves',
          'contact_name': 'Nombre del Contacto',
          'enter_contact_name': 'Introduce el nombre del contacto',
          'public_key': 'Clave Pública',
          'delete_key': 'Eliminar Clave',
          'delete_key_title': 'Eliminar Clave de Encriptación',
          'delete_key_warning':
              '¿Estás seguro de que deseas eliminar tu clave de encriptación? Esta acción no se puede deshacer y necesitarás generar una nueva clave para continuar usando mensajes encriptados.',
          'generate_key_title': 'Generar Clave de Encriptación',
          'generate_key_warning':
              'Esto generará un nuevo par de claves de encriptación. Asegúrate de estar en un lugar seguro y de que nadie esté observando tu pantalla.',
          'key_deleted': 'Clave de encriptación eliminada con éxito',
          'key_generated': 'Nueva clave de encriptación generada con éxito',
          'delete': 'Eliminar',
          'generate': 'Generar',
          'cancel': 'Cancelar',
          'success': 'Éxito',
          'copy_key': 'Copiar Clave',
          'share_key': 'Compartir Clave',
          'show_qr': 'Mostrar Código QR',
          'scan_qr_code': 'Escanear Código QR',
          'key_copied': 'Clave pública copiada al portapapeles',
          'public_key_share': 'Compartir Clave Pública',
          'close': 'Cerrar',
          'add_new_key': 'Agregar Nueva Clave',
          'add_key_title': 'Agregar Clave de Tercero',
          'add_key_manually': 'Introducir Clave Manualmente',
          'add_key_scan': 'Escanear Código QR',
          'enter_key': 'Introduce la Clave Pública',
          'key_added': 'Clave agregada con éxito',
          'invalid_key': 'Formato de clave inválido',
          'scan_qr': 'Escanear Código QR',
          'scan_instructions': 'Posiciona el código QR dentro del marco',
          'scan_success': 'Clave escaneada con éxito',
          'scan_error': 'Error al escanear el código QR',
          'error_loading_keys': 'Error al cargar las claves de encriptación',
          'error_generating_keys':
              'Error al generar las claves de encriptación',
          'error_deleting_keys': 'Error al eliminar las claves de encriptación',
          'error_loading_third_party_keys':
              'Error al cargar las claves de terceros',
          'error_saving_third_party_keys':
              'Error al guardar las claves de terceros',
          'keys_generated': 'Claves de encriptación generadas con éxito',
          'keys_deleted': 'Claves de encriptación eliminadas con éxito',
          'cannot_add_own_key':
              'No puedes agregar tu propia clave a las claves de terceros',
          'delete_third_party_key_title': 'Eliminar Clave de Tercero',
          'delete_third_party_key_warning':
              '¿Estás seguro de que deseas eliminar esta clave de tercero? Esta acción no se puede deshacer.',
          'new_message': 'Nuevo Mensaje',
          'enter_message': 'Escribe tu mensaje aquí...',
          'continue': 'Continuar',
          'select_recipients': 'Seleccionar Destinatarios',
          'select_at_least_one_recipient':
              'Por favor, selecciona al menos un destinatario',
          'error_loading_messages': 'Error al cargar los mensajes',
          'error_saving_messages': 'Error al guardar los mensajes',
          'message_saved': 'Mensaje guardado con éxito',
          'message_deleted': 'Mensaje eliminado con éxito',
          'error_deleting_message': 'Error al eliminar el mensaje',
          'authorized_third_parties': 'Terceros Autorizados',
          'no_messages': 'Aún no hay mensajes',
          'delete_message_title': 'Eliminar Mensaje',
          'delete_message_warning':
              '¿Estás seguro de que deseas eliminar este mensaje? Esta acción no se puede deshacer.',
          'message_detail': 'Detalle del Mensaje',
          'message_id': 'ID del Mensaje',
          'message_content': 'Contenido',
          'created_at': 'Creado el',
          'message_not_for_you': 'Este mensaje no fue encriptado para ti',
          'error_decrypting': 'Error al desencriptar el mensaje',
          'error_encrypting_message': 'Error al encriptar el mensaje',
          'me': 'Yo',
          'message_from_you': 'Tu Mensaje',
          'message_from_other': 'Mensaje del Contacto',
          'sharing_not_implemented': 'El compartir aún no está implementado',
          'info': 'Información',
          'encrypting_message': 'Encriptando mensaje...',
          'message_options': 'Opciones del Mensaje',
          'encrypt_message': 'Encriptar Nuevo Mensaje',
          'import_message': 'Desencriptar Mensaje',
          'import': 'Importar',
          'decrypting_message': 'Desencriptando mensaje...',
          'enter_encrypted_message': 'Pega el mensaje encriptado aquí...',
          'invalid_message_format':
              'Formato de mensaje inválido. El mensaje debe comenzar con "sec-msg:" seguido de datos codificados.',
          'warning': 'Advertencia',
          'yes': 'Sí',
          'no': 'No',
          'invalid_message_structure': 'La estructura del mensaje es inválida.',
          'error_importing_message': 'Error al importar el mensaje.',
          'message_imported': 'Mensaje importado con éxito.',
          'export_message': 'Exportar',
          'export_message_instructions':
              'Aquí está el mensaje encriptado que puedes compartir con otros:',
          'copy': 'Copiar',
          'message_copied': 'Mensaje copiado al portapapeles',
          'no_third_party_keys': 'No hay Claves de Terceros',
          'no_third_party_keys_title': 'No hay Claves de Terceros',
          'no_third_party_keys_message':
              'Necesitas agregar al menos una clave de tercero antes de crear mensajes encriptados.',
          'add_third_party_keys_message':
              'Pide las claves públicas de tus contactos para enviarles mensajes encriptados.',
          'add_third_party_key': 'Agregar Clave',
          'processing_message': 'Procesando mensaje...',
          'message_from_unknown': 'Contacto Desconocido',
          'sender': 'Remitente',
          'message_actions': 'Acciones del Mensaje',
          'create_new_message': 'Crear Nuevo Mensaje',
          'confirm_delete': 'Confirmar Eliminación',
          'confirm_delete_message':
              '¿Estás seguro de que deseas eliminar este mensaje?',
          'message_options_title': 'Opciones del Mensaje',
          'no_messages_description':
              'Tu bandeja de entrada está vacía. Crea o importa un mensaje para empezar.',
          'contact_name_required': 'El nombre del contacto es obligatorio',
          'key_required': 'La clave pública es obligatoria',
          'key_already_exists': 'Esta clave ya existe en tus contactos',
          'public_key_info':
              'Solo las personas que tienen tu clave pública pueden enviarte mensajes encriptados.',
          'start_messaging': 'Comenzar a Mensajear',
          'no_public_key_title': 'Sin Clave de Encriptación',
          'need_public_key_for_import':
              'Necesitas generar tu propia clave de encriptación antes de poder importar mensajes encriptados.',
          'generate_key': 'Generar Clave',
          'add': 'Agregar',
          'key_required_title': 'Clave de Encriptación Requerida',
          'key_required_message':
              'Necesitas generar una clave de encriptación antes de poder crear mensajes encriptados.',
          'no_recipients_title': 'Sin Destinatarios',
          'no_recipients_message':
              'Necesitas agregar al menos un contacto antes de poder crear mensajes encriptados.',
          'add_recipients': 'Agregar Destinatarios',
          'no_personal_key_warning': 'No tienes una clave personal',
          'no_personal_key_error':
              'No tienes una clave personal. No podrás desencriptar este mensaje posteriormente.',
          'loading_messages': 'Cargando mensajes...',
          'created_messages': 'Creados',
          'imported_messages': 'Importados',
          'no_created_messages': 'No hay mensajes creados',
          'no_imported_messages': 'No hay mensajes importados',
          'no_created_messages_description':
              'Crea un nuevo mensaje encriptado para enviarlo a tus contactos',
          'no_imported_messages_description':
              'Importa un mensaje encriptado que alguien haya compartido contigo',
          'generating_keys': 'Generando Claves',
          'please_wait':
              'Por favor, espera mientras generamos tus claves de encriptación...',
          'key_generation_failed':
              'Error al generar las claves de encriptación. Por favor, inténtalo de nuevo.',
          'key_generation_error': 'Ocurrió un error al generar las claves',
          'ok': 'OK',
          'replace_key': 'Reemplazar Clave',
          'replace_key_title': 'Reemplazar Clave de Encriptación',
          'replace_key_warning':
              '¿Estás seguro de que deseas reemplazar tu clave de encriptación? Esta acción no se puede deshacer y cualquier mensaje previamente encriptado ya no podrá ser desencriptado con la nueva clave. Asegúrate de haber guardado cualquier mensaje importante.',
          'keys_replaced': 'Claves de encriptación reemplazadas con éxito',
          'error_replacing_keys':
              'Error al reemplazar las claves de encriptación',
          'replace': 'Reemplazar',
          'decrypted_message': 'Desencriptado',
          'encrypt_and_share': 'Encriptar y Compartir',

          // Específico de la HomePage
          'encrypt_new_message': 'Encriptar nuevo Mensaje',
          'decrypt_message': 'Desencriptar Mensaje',
          'how_it_works': 'Cómo Funciona',
          'buy_me_a_coffee': 'Invítame un café',
          'internet_connection_info':
              'Esta aplicación no requiere conexión a internet. Utiliza un sistema híbrido de encriptación para encriptar y desencriptar mensajes.',

          // Traducciones de la Guía de Claves de Encriptación
          'encryption_keys_guide': 'Guía de Claves',
          'got_it': 'Entendido',
          'what_are_encryption_keys': '¿Qué son las claves de encriptación?',
          'encryption_keys_description':
              'Las claves de encriptación son códigos digitales utilizados para encriptar y desencriptar mensajes. Garantizan que solo el destinatario previsto pueda leer los mensajes enviados.',
          'public_vs_private': 'Claves Públicas vs Privadas',
          'public_vs_private_description':
              'Esta aplicación utiliza encriptación asimétrica con pares de claves:\n• Clave Privada: Se mantiene en secreto en tu dispositivo. Nunca la compartas.\n• Clave Pública: Puede ser compartida con otros que deseen enviarte mensajes encriptados.',
          'how_encryption_works': 'Cómo Funciona la Encriptación',
          'how_encryption_works_description':
              'Esta aplicación utiliza un sistema híbrido de encriptación:\n1. Algoritmo X25519 para un intercambio seguro de claves (curve25519)\n2. AES-GCM de 256 bits para la encriptación simétrica de los mensajes\n\nAl enviar un mensaje:\n• La aplicación genera una clave AES aleatoria\n• Tu mensaje es encriptado con esta clave AES\n• La clave AES es encriptada con la clave pública X25519 del destinatario\n• Solo la clave privada del destinatario puede desbloquear la clave AES y desencriptar el mensaje',
          'sharing_public_key': 'Compartir tu clave pública',
          'sharing_public_key_description':
              'Comparte tu clave pública con otros para que puedan enviarte mensajes encriptados. Puedes compartirla mediante:\n• Código QR\n• Copiar y Pegar\n• Botón de compartir\n\nTu clave pública es segura para compartir, no se puede utilizar para desencriptar mensajes.',
          'managing_others_keys': 'Administrar claves de otros',
          'managing_others_keys_description':
              'Agrega las claves públicas de tus contactos para enviarles mensajes encriptados. Puedes:\n• Escanear su código QR\n• Introducir la clave manualmente\n• Asignarles un nombre reconocible',
          'security_best_practices': 'Mejores prácticas de seguridad',
          'security_best_practices_description':
              '• Esta aplicación nunca se conecta a internet ni almacena datos en servidores\n• Utiliza encriptación de nivel militar (X25519 y AES-GCM de 256 bits)\n• Los mensajes están encriptados de extremo a extremo y nunca se almacenan en ningún dispositivo\n• Tu clave privada nunca sale de tu dispositivo\n• Todos los datos encriptados incluyen códigos de autenticación para evitar manipulaciones\n• Genera un nuevo par de claves si sospechas que tu dispositivo ha sido comprometido\n• Puedes reemplazar tus claves, pero recuerda que los mensajes previamente encriptados solo podrán ser desencriptados con la clave original\n• Verifica la identidad de las personas a las que les agregas la clave pública\n• Usa canales seguros al compartir claves públicas',

          // Regeneración de Claves
          'regenerate_keys': 'Regenerar Claves',
          'regenerate_keys_title': 'Regenerar Claves de Encriptación',
          'regenerate_keys_warning':
              'Esto eliminará tus claves actuales y generará nuevas. Todos los mensajes anteriores ya no podrán ser desencriptados. Esta acción no se puede deshacer.',
          'regenerate': 'Regenerar',
          'keys_regenerated':
              'Claves regeneradas con éxito. Los mensajes anteriores ya no podrán ser desencriptados.',
          'keys_regeneration_failed':
              'Error al regenerar las claves. Por favor, inténtalo de nuevo.',
          'refresh': 'Actualizar',
          'encrypt_and_share': 'Encriptar y Compartir',

          // Prueba de Claves
          'test_keys': 'Probar Claves',
          'testing_keys': 'Probando Claves',
          'no_keys_to_test': 'No hay claves disponibles para probar',
          'keys_test_passed':
              '¡La prueba de claves se completó con éxito! Tus claves están funcionando correctamente.',
          'keys_test_failed':
              'La prueba de claves falló. Es posible que tus claves no estén funcionando correctamente.',
          'error_testing_keys': 'Ocurrió un error al probar las claves',

          // Traducciones de la Guía de Cómo Empezar
          'how_to_get_started_title': 'Cómo Empezar',
          'how_to_get_started_step1_title': '1. Comparte Tu Clave Pública',
          'how_to_get_started_step1_desc':
              'Comparte tu Clave Pública (ubicada en "Mi Clave") con los contactos de los que deseas recibir mensajes. Ellos la necesitarán para encriptar mensajes para ti.',
          'how_to_get_started_step2_title': '2. Agrega Claves de Contacto',
          'how_to_get_started_step2_desc':
              'Dirígete a "Claves de Terceros", toca en "Agregar Nueva Clave" y añade las claves públicas de los contactos a los que deseas enviar mensajes. Asígnales nombres reconocibles.',
          'how_to_get_started_step3_title': '3. Comienza a Mensajear',
          'how_to_get_started_step3_desc':
              'Utiliza "Encriptar nuevo Mensaje" para enviar mensajes seguros a tus contactos agregados, o "Desencriptar Mensaje" para importar y leer mensajes enviados a ti.',

          // Diálogo "Invítame un café"
          'buy_me_a_coffee_title': 'Apoya al Desarrollador',
          'buy_me_a_coffee_message':
              'Si encuentras útil esta aplicación, por favor considera apoyar su desarrollo con una pequeña donación. ¡Esto ayuda a mantener la aplicación gratuita y sin anuncios!',
          'buy_me_a_coffee_button': 'Invítame un café',
          'error_launching_url': 'No se pudo abrir el enlace',
        },
      };
}
