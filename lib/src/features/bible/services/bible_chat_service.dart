// 🤖 AI Bible Chat Service
// Advanced AI-powered Bible study companion service

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/bible_chat_models.dart';
import '../repository/bible_repository.dart';
import '../services/bible_chat_local_storage.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/ai_service.dart';

class BibleChatService {
  static final BibleChatService _instance = BibleChatService._internal();
  factory BibleChatService() => _instance;
  BibleChatService._internal();

  late final BibleRepository _bibleRepository;
  late final PremiumService _premiumService;
  late final BibleChatLocalStorage _localStorage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Current state
  BibleChatConversation? _currentConversation;
  BibleChatSettings _settings = BibleChatSettings();
  BibleChatContext? _currentContext;

  // Stream controllers
  final StreamController<BibleChatConversation?> _conversationController =
      StreamController<BibleChatConversation?>.broadcast();
  final StreamController<List<BibleChatConversation>>
      _conversationListController =
      StreamController<List<BibleChatConversation>>.broadcast();
  final StreamController<BibleChatSettings> _settingsController =
      StreamController<BibleChatSettings>.broadcast();

  // Cache
  final Map<String, BibleChatConversation> _conversationCache = {};
  final List<BibleChatPrompt> _promptCache = [];

  bool _isInitialized = false;

  /// Initialize the AI Chat service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _bibleRepository = BibleRepository();
      _premiumService = PremiumService();
      _localStorage = BibleChatLocalStorage();

      // Load user settings
      await _loadUserSettings();

      // Load predefined prompts
      await _loadChatPrompts();

      _isInitialized = true;
      debugPrint('✅ Bible Chat Service initialized');
    } catch (e) {
      debugPrint('❌ Bible Chat Service initialization failed: $e');
      rethrow;
    }
  }

  /// Check if AI Chat is available (premium feature)
  Future<bool> isAIChatAvailable() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Bible Chat: User not authenticated');
      return false;
    }

    final isPremium = await _premiumService.isPremium();
    debugPrint('🔍 Bible Chat: User ${user.uid} premium status: $isPremium');
    return isPremium;
  }

  /// Start a new conversation
  Future<BibleChatConversation> startNewConversation({
    String? title,
    BibleChatContext? context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Bible Chat: Cannot start conversation - user not authenticated');
      throw Exception('User not authenticated');
    }

    debugPrint('🔍 Bible Chat: Starting conversation for user ${user.uid}');

    if (!await isAIChatAvailable()) {
      debugPrint('❌ Bible Chat: Cannot start conversation - premium subscription required');
      throw Exception('AI Chat requires premium subscription');
    }

    final conversationId = _generateConversationId();
    final conversation = BibleChatConversation(
      id: conversationId,
      userId: user.uid,
      title: title ?? _generateConversationTitle(context),
      messages: [],
      context: context,
    );

    // Add welcome message
    final welcomeMessage = _generateWelcomeMessage(context);
    final updatedConversation = conversation.copyWith(
      messages: [welcomeMessage],
    );

    // Save to Firebase
    debugPrint('🔍 Bible Chat: Attempting to save conversation to Firebase...');
    await _saveConversation(updatedConversation);

    // Update current conversation
    _currentConversation = updatedConversation;
    _conversationController.add(_currentConversation);

    debugPrint('✅ New Bible chat conversation started: $conversationId');
    return updatedConversation;
  }

  /// Send a message in the current conversation
  Future<BibleChatMessage> sendMessage(
    String content, {
    BibleChatContext? context,
  }) async {
    if (_currentConversation == null) {
      throw Exception('No active conversation');
    }

    if (!await isAIChatAvailable()) {
      throw Exception('AI Chat requires premium subscription');
    }

    // Create user message
    final userMessage = BibleChatMessage(
      id: _generateMessageId(),
      role: 'user',
      content: content,
      metadata: {
        'context': context?.toMap(),
      },
    );

    // Add user message to conversation
    final currentConv = _currentConversation;
    if (currentConv == null) {
      throw Exception('No active conversation available');
    }
    
    final updatedMessages = [...currentConv.messages, userMessage];
    _currentConversation = currentConv.copyWith(
      messages: updatedMessages,
      context: context ?? currentConv.context,
    );

    // Update UI immediately with user message
    _conversationController.add(_currentConversation);

    try {
      // Generate AI response
      final currentConvForAI = _currentConversation;
      if (currentConvForAI == null) {
        throw Exception('Conversation lost during AI response generation');
      }
      
      final aiResponse = await _generateAIResponse(
        content,
        currentConvForAI,
        context ?? currentConvForAI.context,
      );

      // Add AI response to conversation
      final finalMessages = [...updatedMessages, aiResponse];
      final currentConvForUpdate = _currentConversation;
      if (currentConvForUpdate == null) {
        throw Exception('Conversation lost during message update');
      }
      
      _currentConversation = currentConvForUpdate.copyWith(
        messages: finalMessages,
      );

      // Save updated conversation
      final conversationToSave = _currentConversation;
      if (conversationToSave != null) {
        await _saveConversation(conversationToSave);
      }

      // Update UI with AI response
      _conversationController.add(_currentConversation);

      debugPrint(
          '✅ AI response generated for conversation: ${_currentConversation?.id ?? 'unknown'}');
      return aiResponse;
    } catch (e) {
      debugPrint('❌ Error generating AI response: $e');

      // Add error message
      final errorMessage = BibleChatMessage(
        id: _generateMessageId(),
        role: 'assistant',
        content:
            'Maaf, saya mengalami kesulitan merespons pertanyaan Anda. Silakan coba lagi.',
        type: BibleChatMessageType.text,
        metadata: {'error': e.toString()},
      );

      final errorMessages = [...updatedMessages, errorMessage];
      final currentConvForError = _currentConversation;
      if (currentConvForError != null) {
        _currentConversation = currentConvForError.copyWith(
          messages: errorMessages,
        );
      }

      _conversationController.add(_currentConversation);
      rethrow;
    }
  }

  /// Generate AI response using real AI service
  Future<BibleChatMessage> _generateAIResponse(
    String userInput,
    BibleChatConversation conversation,
    BibleChatContext? context,
  ) async {
    try {
      // Try real AI first (OpenAI/Gemini)
      String aiResponse;
      
      try {
        // Prepare conversation history for AI
        final conversationHistory = conversation.messages
            .take(10) // Limit to last 10 messages for context
            .map((msg) => {
                  'role': msg.role,
                  'content': msg.content,
                })
            .toList();

        // Add Bible context to user message if available
        String contextualMessage = userInput;
        if (context != null) {
          contextualMessage = 'Context: ${context.getContextDescription()}\n\nUser question: $userInput';
        }

        // Generate AI response using best available provider (GitHub -> OpenAI -> Gemini)
        String usedProvider = 'unknown';
        String usedModel = 'unknown';
        
        try {
          debugPrint('🔍 Calling GitHub Models API...');
          aiResponse = await AIService.generateGitHubModelsResponse(
            userMessage: contextualMessage,
            systemPrompt: AIService.getBibleChatSystemPrompt(),
            conversationHistory: conversationHistory,
            model: 'DeepSeek-R1', // Try DeepSeek-R1 model
          );
          debugPrint('✅ GitHub Models response received: ${aiResponse.length} chars');
          usedProvider = 'github';
          usedModel = 'DeepSeek-R1';
        } catch (githubError) {
          debugPrint('GitHub Models failed, trying OpenAI: $githubError');
          try {
            aiResponse = await AIService.generateOpenAIResponse(
              userMessage: contextualMessage,
              systemPrompt: AIService.getBibleChatSystemPrompt(),
              conversationHistory: conversationHistory,
            );
            usedProvider = 'openai';
            usedModel = 'gpt-3.5-turbo';
          } catch (openAIError) {
            debugPrint('OpenAI failed, trying Gemini: $openAIError');
            aiResponse = await AIService.generateGeminiResponse(
              userMessage: contextualMessage,
              systemPrompt: AIService.getBibleChatSystemPrompt(),
            );
            usedProvider = 'gemini';
            usedModel = 'gemini-1.5-flash';
          }
        }
        
        // Parse Bible references from AI response if any
        debugPrint('🔍 Extracting Bible references...');
        final references = _extractBibleReferences(aiResponse);
        debugPrint('✅ Found ${references.length} references');
        
        debugPrint('🔍 Determining message type...');
        final messageType = _determineMessageType(aiResponse);
        debugPrint('✅ Message type: $messageType');
        
        debugPrint('🔍 Creating BibleChatMessage...');
        return BibleChatMessage(
          id: _generateMessageId(),
          role: 'assistant',
          content: aiResponse,
          references: references,
          type: messageType,
          metadata: {
            'provider': usedProvider,
            'model': usedModel,
            'context': context?.toMap(),
          },
        );
        
      } catch (aiError) {
        debugPrint('❌ AI services failed, using fallback: $aiError');
        // Fallback to pattern-based responses
        final response = await _generateSmartResponse(userInput, context);
        
        return BibleChatMessage(
          id: _generateMessageId(),
          role: 'assistant',
          content: response['content'] ?? 'Maaf, saya tidak dapat memberikan respons saat ini.',
          references: response['references'] ?? <BibleReference>[],
          type: response['type'] ?? BibleChatMessageType.text,
          metadata: {'provider': 'fallback', ...?response['metadata']},
        );
      }
      
    } catch (e) {
      debugPrint('❌ AI response generation failed: $e');
      rethrow;
    }
  }

  /// Convert string references to BibleReference objects
  List<BibleReference> _convertStringReferencesToBibleReferences(List<String> stringReferences) {
    final references = <BibleReference>[];
    
    for (final ref in stringReferences) {
      // Parse reference format like "Yohanes 3:16" or "Mazmur 23:1"
      final match = RegExp(r'(\w+)\s+(\d+):(\d+)').firstMatch(ref);
      if (match != null) {
        final bookName = match.group(1)!.toLowerCase();
        final chapter = int.tryParse(match.group(2)!) ?? 1;
        final verse = int.tryParse(match.group(3)!) ?? 1;
        
        references.add(BibleReference(
          collectionId: 'tb', // Indonesian translation
          bookId: bookName,
          chapter: chapter,
          startVerse: verse,
          verseText: '', // Text will be loaded when needed
        ));
      }
    }
    
    return references;
  }

  /// Extract Bible references from AI response text
  List<BibleReference> _extractBibleReferences(String text) {
    final references = <BibleReference>[];
    
    // Simple regex patterns for Bible references
    final patterns = [
      RegExp(r'\b(\w+)\s+(\d+):(\d+)(?:-(\d+))?\b', caseSensitive: false),
      RegExp(r'\b(\w+)\s+(\d+)\s*:\s*(\d+)\b', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final bookName = match.group(1)!;
        final chapter = int.tryParse(match.group(2)!) ?? 1;
        final startVerse = int.tryParse(match.group(3)!) ?? 1;
        final endVerse = (match.groupCount >= 4 && match.group(4) != null) ? int.tryParse(match.group(4)!) : null;
        
        references.add(BibleReference(
          collectionId: 'indo_tb', // Default collection
          bookId: bookName.toLowerCase(),
          chapter: chapter,
          startVerse: startVerse,
          endVerse: endVerse,
        ));
      }
    }
    
    return references;
  }

  /// Determine message type based on content
  BibleChatMessageType _determineMessageType(String content) {
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('doa') || lowerContent.contains('prayer') || lowerContent.contains('amin')) {
      return BibleChatMessageType.prayer;
    }
    
    if (lowerContent.contains('ayat') || lowerContent.contains('verse') || 
        RegExp(r'\b\w+\s+\d+:\d+\b').hasMatch(content)) {
      return BibleChatMessageType.verse;
    }
    
    if (lowerContent.contains('mengajarkan') || lowerContent.contains('arti') || 
        lowerContent.contains('meaning') || lowerContent.contains('insight')) {
      return BibleChatMessageType.insight;
    }
    
    return BibleChatMessageType.text;
  }

  /// Smart pattern-based response generator (placeholder for AI integration)
  Future<Map<String, dynamic>> _generateSmartResponse(
    String userInput,
    BibleChatContext? context,
  ) async {
    final input = userInput.toLowerCase().trim();

    // Detect question types and generate appropriate responses
    if (input.contains('apa arti') ||
        input.contains('what does') ||
        input.contains('maksud')) {
      return await _generateExplanationResponse(userInput, context);
    }

    if (input.contains('doa') ||
        input.contains('prayer') ||
        input.contains('pray')) {
      return await _generatePrayerResponse(userInput, context);
    }

    if (input.contains('ayat') ||
        input.contains('verse') ||
        input.contains('pasal')) {
      return await _generateVerseResponse(userInput, context);
    }

    if (input.contains('bagaimana') ||
        input.contains('how to') ||
        input.contains('cara')) {
      return await _generateHowToResponse(userInput, context);
    }

    if (input.contains('mengapa') ||
        input.contains('why') ||
        input.contains('kenapa')) {
      return await _generateWhyResponse(userInput, context);
    }

    // Default conversational response
    return await _generateConversationalResponse(userInput, context);
  }

  /// Generate explanation response
  Future<Map<String, dynamic>> _generateExplanationResponse(
    String input,
    BibleChatContext? context,
  ) async {
    final responses = [
      'Berdasarkan konteks Alkitab, konsep ini memiliki makna yang mendalam. Mari kita lihat lebih detail...',
      'Dalam tradisi Kristen, hal ini dipahami sebagai...',
      'Ayat-ayat terkait memberikan pencerahan tentang...',
    ];

    return {
      'content': responses.isNotEmpty ? responses[Random().nextInt(responses.length)] : 'Maaf, saya tidak dapat memberikan penjelasan saat ini.',
      'type': BibleChatMessageType.insight,
      'references': await _getRelatedVerses(input, context),
      'metadata': {'responseType': 'explanation'},
    };
  }

  /// Generate prayer response
  Future<Map<String, dynamic>> _generatePrayerResponse(
    String input,
    BibleChatContext? context,
  ) async {
    final prayers = [
      'Mari berdoa bersama:\n\n"Bapa yang Mahakasih, terima kasih atas firman-Mu yang memberikan penghiburan dan hikmat. Bantulah kami untuk memahami dan menerapkan ajaran-Mu dalam hidup kami. Amin."',
      'Doa untuk pemahaman:\n\n"Tuhan, bukakan mata hati kami untuk memahami kebenaran firman-Mu. Berikan kami hikmat untuk menjalani hidup sesuai kehendak-Mu. Amin."',
      'Doa syukur:\n\n"Bapa surgawi, kami bersyukur atas kasih-Mu yang tidak pernah berubah. Terima kasih telah memberikan pengharapan melalui firman-Mu. Amin."',
    ];

    return {
      'content': prayers.isNotEmpty ? prayers[Random().nextInt(prayers.length)] : 'Doa: Tuhan, berikan kami hikmat dan pengertian. Amin.',
      'type': BibleChatMessageType.prayer,
      'references': <BibleReference>[], // Empty references for prayer responses
      'metadata': {'responseType': 'prayer'},
    };
  }

  /// Generate verse-related response
  Future<Map<String, dynamic>> _generateVerseResponse(
    String input,
    BibleChatContext? context,
  ) async {
    final verses = await _getPopularVerses();
    final selectedVerse = verses.isNotEmpty ? verses[Random().nextInt(verses.length)] : {
      'text': 'Karena begitu besar kasih Allah akan dunia ini...',
      'reference': 'Yohanes 3:16'
    };

    return {
      'content':
          'Berikut adalah ayat yang relevan dengan topik Anda:\n\n"${selectedVerse['text']}"\n\n${selectedVerse['reference']}\n\nAyat ini mengajarkan kita tentang...',
      'type': BibleChatMessageType.verse,
      'references': _convertStringReferencesToBibleReferences([selectedVerse['reference']]),
      'metadata': {'responseType': 'verse'},
    };
  }

  /// Generate how-to response
  Future<Map<String, dynamic>> _generateHowToResponse(
    String input,
    BibleChatContext? context,
  ) async {
    final guides = [
      'Alkitab memberikan panduan praktis untuk ini:\n\n1. Mulai dengan doa dan renungan\n2. Cari ayat-ayat yang relevan\n3. Terapkan dalam kehidupan sehari-hari\n4. Bagikan dengan komunitas iman',
      'Berikut langkah-langkah berdasarkan ajaran Alkitab:\n\n1. Percayai pada rencana Tuhan\n2. Berdoa dengan tekun\n3. Cari hikmat melalui firman-Nya\n4. Bertindak dengan kasih',
    ];

    return {
      'content': guides.isNotEmpty ? guides[Random().nextInt(guides.length)] : 'Alkitab memberikan panduan untuk kehidupan kita.',
      'type': BibleChatMessageType.insight,
      'references': <BibleReference>[], // Empty references for how-to responses
      'metadata': {'responseType': 'howto'},
    };
  }

  /// Generate why response
  Future<Map<String, dynamic>> _generateWhyResponse(
    String input,
    BibleChatContext? context,
  ) async {
    final explanations = [
      'Pertanyaan yang sangat mendalam! Alkitab mengajarkan bahwa...',
      'Ini adalah pertanyaan yang banyak orang renungkan. Menurut firman Tuhan...',
      'Tuhan memberikan jawaban untuk pertanyaan ini melalui...',
    ];

    return {
      'content': explanations.isNotEmpty ? explanations[Random().nextInt(explanations.length)] : 'Tuhan memiliki rencana yang baik untuk kita.',
      'type': BibleChatMessageType.insight,
      'references': await _getRelatedVerses(input, context),
      'metadata': {'responseType': 'why'},
    };
  }

  /// Generate conversational response
  Future<Map<String, dynamic>> _generateConversationalResponse(
    String input,
    BibleChatContext? context,
  ) async {
    final responses = [
      'Terima kasih telah berbagi. Mari kita jelajahi bersama apa yang Alkitab katakan tentang hal ini...',
      'Saya memahami kekhawatiran Anda. Firman Tuhan seringkali memberikan penghiburan dalam situasi seperti ini...',
      'Pertanyaan yang menarik! Mari kita lihat apa yang dapat kita pelajari dari Alkitab...',
      'Saya senang bisa berdiskusi dengan Anda tentang iman. Alkitab memiliki banyak hikmat untuk dibagikan...',
    ];

    return {
      'content': responses.isNotEmpty ? responses[Random().nextInt(responses.length)] : 'Terima kasih atas pertanyaan Anda. Mari kita belajar dari Alkitab bersama.',
      'type': BibleChatMessageType.text,
      'references': <BibleReference>[], // Empty references for conversational responses
      'metadata': {'responseType': 'conversational'},
    };
  }

  /// Get related verses based on input
  Future<List<BibleReference>> _getRelatedVerses(
      String input, BibleChatContext? context) async {
    // This would ideally search through the Bible database
    // For now, return some popular verses
    final popular = await _getPopularVerses();
    return [
      BibleReference(
        collectionId: 'tb',
        bookId: 'yohanes',
        chapter: 3,
        startVerse: 16,
        verseText: popular[0]['text'],
      ),
    ];
  }

  /// Get popular Bible verses
  Future<List<Map<String, dynamic>>> _getPopularVerses() async {
    return [
      {
        'text':
            'Karena begitu besar kasih Allah akan dunia ini, sehingga Ia telah mengaruniakan Anak-Nya yang tunggal, supaya setiap orang yang percaya kepada-Nya tidak binasa, melainkan beroleh hidup yang kekal.',
        'reference': 'Yohanes 3:16',
      },
      {
        'text': 'TUHAN adalah gembalaku, takkan kekurangan aku.',
        'reference': 'Mazmur 23:1',
      },
      {
        'text':
            'Sebab Aku ini mengetahui rancangan-rancangan apa yang ada pada-Ku mengenai kamu, demikianlah firman TUHAN, yaitu rancangan damai sejahtera dan bukan rancangan kecelakaan, untuk memberikan kepadamu hari depan yang penuh harapan.',
        'reference': 'Yeremia 29:11',
      },
    ];
  }

  /// Load user conversations with local storage fallback
  Future<List<BibleChatConversation>> loadUserConversations() async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    final user = _auth.currentUser;
    
    // Try Firebase first if user is authenticated
    if (user != null) {
      try {
        final snapshot = await _database
            .ref('bible/chat/conversations/${user.uid}')
            .orderByChild('updatedAt')
            .limitToLast(50)
            .get();

        final conversations = <BibleChatConversation>[];

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          for (final entry in data.entries) {
            try {
              final conversationData =
                  Map<String, dynamic>.from(entry.value as Map);
              conversationData['id'] = entry.key; // Add the key as id
              final conversation =
                  BibleChatConversation.fromMap(conversationData);
              conversations.add(conversation);
              _conversationCache[conversation.id] = conversation;
            } catch (e) {
              debugPrint('❌ Error parsing conversation ${entry.key}: $e');
            }
          }
          
          // Sort by most recent
          conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          _conversationListController.add(conversations);
          return conversations;
        }
      } catch (e) {
        debugPrint('❌ Firebase error, trying local storage: $e');
      }
    }

    // Fallback to local storage
    try {
      final conversations = await _localStorage.getConversations();
      _conversationListController.add(conversations);
      return conversations;
    } catch (e) {
      debugPrint('❌ Error loading from local storage: $e');
      return [];
    }
  }

  /// Load a specific conversation
  Future<BibleChatConversation?> loadConversation(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check cache first
    if (_conversationCache.containsKey(conversationId)) {
      final conversation = _conversationCache[conversationId];
      if (conversation != null) {
        _currentConversation = conversation;
        _conversationController.add(conversation);
        return conversation;
      }
    }

    try {
      final snapshot = await _database
          .ref('bible/chat/conversations/${user.uid}/$conversationId')
          .get();

      if (snapshot.exists) {
        final conversation = BibleChatConversation.fromSnapshot(snapshot);
        _conversationCache[conversationId] = conversation;
        _currentConversation = conversation;
        _conversationController.add(conversation);
        return conversation;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error loading conversation $conversationId: $e');
      return null;
    }
  }

  /// Save conversation to Firebase with local storage fallback
  Future<void> _saveConversation(BibleChatConversation conversation) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Always save to local storage first
    try {
      await _localStorage.saveConversation(conversation);
      _conversationCache[conversation.id] = conversation;
      debugPrint('✅ Conversation saved to local storage: ${conversation.id}');
    } catch (localError) {
      debugPrint('❌ Error saving to local storage: $localError');
    }

    // Try to save to Firebase if user is authenticated
    final user = _auth.currentUser;
    if (user != null) {
      try {
        debugPrint('🔍 Saving to Firebase path: bible/chat/conversations/${user.uid}/${conversation.id}');
        debugPrint('🔍 User authenticated: ${user.uid}');
        await _database
            .ref('bible/chat/conversations/${user.uid}/${conversation.id}')
            .set(conversation.toMap());
        debugPrint('✅ Conversation synced to Firebase: ${conversation.id}');
      } catch (firebaseError) {
        debugPrint('❌ Error saving to Firebase (using local storage): $firebaseError');
        // Don't rethrow - local storage is working
      }
    } else {
      debugPrint('❌ Cannot save to Firebase: User not authenticated');
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _database
          .ref('bible/chat/conversations/${user.uid}/$conversationId')
          .remove();

      _conversationCache.remove(conversationId);

      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
        _conversationController.add(null);
      }

      debugPrint('✅ Conversation deleted: $conversationId');

      // Refresh conversation list
      await loadUserConversations();
    } catch (e) {
      debugPrint('❌ Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Update chat settings
  Future<void> updateSettings(BibleChatSettings settings) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _database
          .ref('bible/chat/settings/${user.uid}')
          .set(settings.toMap());

      _settings = settings;
      _settingsController.add(settings);

      debugPrint('✅ Chat settings updated');
    } catch (e) {
      debugPrint('❌ Error updating settings: $e');
      rethrow;
    }
  }

  /// Load user settings
  Future<void> _loadUserSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot =
          await _database.ref('bible/chat/settings/${user.uid}').get();

      if (snapshot.exists) {
        _settings = BibleChatSettings.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map));
      }

      _settingsController.add(_settings);
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
    }
  }

  /// Load predefined chat prompts
  Future<void> _loadChatPrompts() async {
    // This would ideally load from Firebase or assets
    // For now, use hardcoded prompts
    _promptCache.addAll([
      BibleChatPrompt(
        id: 'daily_reflection',
        title: 'Renungan Harian',
        prompt: 'Bagikan renungan berdasarkan ayat yang sedang saya baca',
        category: 'devotional',
        isContextSensitive: true,
      ),
      BibleChatPrompt(
        id: 'prayer_request',
        title: 'Doa',
        prompt: 'Bantu saya membuat doa berdasarkan situasi ini',
        category: 'prayer',
      ),
      BibleChatPrompt(
        id: 'verse_explanation',
        title: 'Penjelasan Ayat',
        prompt: 'Jelaskan makna dari ayat ini',
        category: 'study',
        isContextSensitive: true,
      ),
    ]);
  }

  /// Generate conversation title
  String _generateConversationTitle(BibleChatContext? context) {
    if (context != null && context.bookId != null) {
      return 'Chat tentang ${context.bookId}';
    }
    return 'Percakapan Alkitab ${DateTime.now().day}/${DateTime.now().month}';
  }

  /// Generate welcome message
  BibleChatMessage _generateWelcomeMessage(BibleChatContext? context) {
    String content = 'Shalom! Saya adalah asisten Alkitab AI Anda. ';

    if (context != null && context.bookId != null) {
      content +=
          'Saya melihat Anda sedang membaca ${context.getContextDescription()}. ';
    }

    content +=
        'Bagaimana saya bisa membantu Anda memahami firman Tuhan hari ini?';

    return BibleChatMessage(
      id: _generateMessageId(),
      role: 'assistant',
      content: content,
      type: BibleChatMessageType.text,
    );
  }

  /// Generate unique IDs
  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Stream getters
  Stream<BibleChatConversation?> get currentConversationStream =>
      _conversationController.stream;
  Stream<List<BibleChatConversation>> get conversationListStream =>
      _conversationListController.stream;
  Stream<BibleChatSettings> get settingsStream => _settingsController.stream;

  /// Getters
  BibleChatConversation? get currentConversation => _currentConversation;
  BibleChatSettings get settings => _settings;
  List<BibleChatPrompt> get availablePrompts => _promptCache;

  /// Dispose resources
  void dispose() {
    _conversationController.close();
    _conversationListController.close();
    _settingsController.close();
  }
}
