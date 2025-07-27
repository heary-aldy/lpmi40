// 🤖 AI Bible Chat Models
// Models for AI-powered Bible study and conversation features

import 'package:firebase_database/firebase_database.dart';

/// Represents a conversation with the AI Bible assistant
class BibleChatConversation {
  final String id;
  final String userId;
  final String title; // Auto-generated or user-defined
  final List<BibleChatMessage> messages;
  final BibleChatContext? context; // Current Bible reading context
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final Map<String, dynamic>? metadata;

  BibleChatConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    this.context,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
    this.metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firebase snapshot
  factory BibleChatConversation.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    return BibleChatConversation(
      id: snapshot.key!,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Bible Chat',
      messages: (data['messages'] as List<dynamic>?)
          ?.map((m) => BibleChatMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList() ?? [],
      context: data['context'] != null 
          ? BibleChatContext.fromMap(Map<String, dynamic>.from(data['context']))
          : null,
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      isArchived: data['isArchived'] ?? false,
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Convert to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'context': context?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  BibleChatConversation copyWith({
    String? title,
    List<BibleChatMessage>? messages,
    BibleChatContext? context,
    bool? isArchived,
    Map<String, dynamic>? metadata,
  }) {
    return BibleChatConversation(
      id: id,
      userId: userId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isArchived: isArchived ?? this.isArchived,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Individual message in a Bible chat conversation
class BibleChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<BibleReference>? references; // Referenced verses
  final BibleChatMessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  BibleChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.references,
    this.type = BibleChatMessageType.text,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from map
  factory BibleChatMessage.fromMap(Map<String, dynamic> data) {
    return BibleChatMessage(
      id: data['id'] ?? '',
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      references: (data['references'] as List<dynamic>?)
          ?.map((r) => BibleReference.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
      type: BibleChatMessageType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => BibleChatMessageType.text,
      ),
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'references': references?.map((r) => r.toMap()).toList(),
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Type of chat message
enum BibleChatMessageType {
  text,           // Regular text message
  verse,          // Message containing Bible verses
  question,       // Study question
  insight,        // AI-generated insight
  prayer,         // Prayer suggestion
  reflection,     // Reflection prompt
}

/// Context for Bible chat (current reading location)
class BibleChatContext {
  final String? collectionId;   // Current Bible translation
  final String? bookId;         // Current book
  final int? chapter;           // Current chapter
  final List<int>? verses;      // Current verse(s)
  final String? topic;          // Discussion topic
  final Map<String, dynamic>? additionalContext;

  BibleChatContext({
    this.collectionId,
    this.bookId,
    this.chapter,
    this.verses,
    this.topic,
    this.additionalContext,
  });

  /// Create from map
  factory BibleChatContext.fromMap(Map<String, dynamic> data) {
    return BibleChatContext(
      collectionId: data['collectionId'],
      bookId: data['bookId'],
      chapter: data['chapter'],
      verses: (data['verses'] as List<dynamic>?)?.cast<int>(),
      topic: data['topic'],
      additionalContext: data['additionalContext'] != null
          ? Map<String, dynamic>.from(data['additionalContext'])
          : null,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'collectionId': collectionId,
      'bookId': bookId,
      'chapter': chapter,
      'verses': verses,
      'topic': topic,
      'additionalContext': additionalContext,
    };
  }

  /// Get a human-readable context description
  String getContextDescription() {
    if (bookId != null && chapter != null) {
      final verseStr = verses != null && verses!.isNotEmpty 
          ? verses!.length == 1 
              ? ':${verses!.first}'
              : ':${verses!.first}-${verses!.last}'
          : '';
      return '$bookId $chapter$verseStr';
    }
    return topic ?? 'General Discussion';
  }
}

/// Reference to a specific Bible verse or passage
class BibleReference {
  final String collectionId;
  final String bookId;
  final int chapter;
  final int? startVerse;
  final int? endVerse;
  final String? verseText;    // Cached verse text
  final String? translation;  // Translation abbreviation

  BibleReference({
    required this.collectionId,
    required this.bookId,
    required this.chapter,
    this.startVerse,
    this.endVerse,
    this.verseText,
    this.translation,
  });

  /// Create from map
  factory BibleReference.fromMap(Map<String, dynamic> data) {
    return BibleReference(
      collectionId: data['collectionId'] ?? '',
      bookId: data['bookId'] ?? '',
      chapter: data['chapter'] ?? 1,
      startVerse: data['startVerse'],
      endVerse: data['endVerse'],
      verseText: data['verseText'],
      translation: data['translation'],
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'collectionId': collectionId,
      'bookId': bookId,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'verseText': verseText,
      'translation': translation,
    };
  }

  /// Get formatted reference string (e.g., "John 3:16" or "Romans 8:28-30")
  String getFormattedReference() {
    final verseStr = startVerse != null
        ? endVerse != null && endVerse != startVerse
            ? ':$startVerse-$endVerse'
            : ':$startVerse'
        : '';
    
    return '$bookId $chapter$verseStr';
  }
}

/// AI Chat settings and preferences
class BibleChatSettings {
  final bool isEnabled;
  final String preferredLanguage;     // 'malay', 'english', 'indonesian'
  final String responseStyle;         // 'conversational', 'scholarly', 'devotional'
  final bool includeReferences;       // Include verse references in responses
  final bool enableStudyQuestions;    // Generate study questions
  final bool enablePrayerSuggestions; // Suggest prayers
  final int maxContextLength;         // Maximum conversation context
  final Map<String, dynamic>? customSettings;

  BibleChatSettings({
    this.isEnabled = true,
    this.preferredLanguage = 'malay',
    this.responseStyle = 'conversational',
    this.includeReferences = true,
    this.enableStudyQuestions = true,
    this.enablePrayerSuggestions = true,
    this.maxContextLength = 20,
    this.customSettings,
  });

  /// Create from map
  factory BibleChatSettings.fromMap(Map<String, dynamic> data) {
    return BibleChatSettings(
      isEnabled: data['isEnabled'] ?? true,
      preferredLanguage: data['preferredLanguage'] ?? 'malay',
      responseStyle: data['responseStyle'] ?? 'conversational',
      includeReferences: data['includeReferences'] ?? true,
      enableStudyQuestions: data['enableStudyQuestions'] ?? true,
      enablePrayerSuggestions: data['enablePrayerSuggestions'] ?? true,
      maxContextLength: data['maxContextLength'] ?? 20,
      customSettings: data['customSettings'] != null
          ? Map<String, dynamic>.from(data['customSettings'])
          : null,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'preferredLanguage': preferredLanguage,
      'responseStyle': responseStyle,
      'includeReferences': includeReferences,
      'enableStudyQuestions': enableStudyQuestions,
      'enablePrayerSuggestions': enablePrayerSuggestions,
      'maxContextLength': maxContextLength,
      'customSettings': customSettings,
    };
  }

  /// Create a copy with updated settings
  BibleChatSettings copyWith({
    bool? isEnabled,
    String? preferredLanguage,
    String? responseStyle,
    bool? includeReferences,
    bool? enableStudyQuestions,
    bool? enablePrayerSuggestions,
    int? maxContextLength,
    Map<String, dynamic>? customSettings,
  }) {
    return BibleChatSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      responseStyle: responseStyle ?? this.responseStyle,
      includeReferences: includeReferences ?? this.includeReferences,
      enableStudyQuestions: enableStudyQuestions ?? this.enableStudyQuestions,
      enablePrayerSuggestions: enablePrayerSuggestions ?? this.enablePrayerSuggestions,
      maxContextLength: maxContextLength ?? this.maxContextLength,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Predefined chat prompts and suggestions
class BibleChatPrompt {
  final String id;
  final String title;
  final String prompt;
  final String category;          // 'study', 'devotional', 'prayer', 'general'
  final List<String>? triggers;   // Keywords that trigger this prompt
  final bool isContextSensitive;  // Whether prompt adapts to current reading
  final Map<String, dynamic>? metadata;

  BibleChatPrompt({
    required this.id,
    required this.title,
    required this.prompt,
    required this.category,
    this.triggers,
    this.isContextSensitive = false,
    this.metadata,
  });

  /// Create from map
  factory BibleChatPrompt.fromMap(Map<String, dynamic> data) {
    return BibleChatPrompt(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      prompt: data['prompt'] ?? '',
      category: data['category'] ?? 'general',
      triggers: (data['triggers'] as List<dynamic>?)?.cast<String>(),
      isContextSensitive: data['isContextSensitive'] ?? false,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'prompt': prompt,
      'category': category,
      'triggers': triggers,
      'isContextSensitive': isContextSensitive,
      'metadata': metadata,
    };
  }
}

/// Available chat response styles
enum BibleChatResponseStyle {
  conversational,  // Friendly, casual discussion
  scholarly,       // Academic, detailed explanations
  devotional,      // Spiritual, inspirational focus
  pastoral,        // Caring, guidance-oriented
  educational,     // Teaching-focused, informative
}

/// Chat session statistics
class BibleChatStats {
  final int totalConversations;
  final int totalMessages;
  final int averageConversationLength;
  final Map<String, int> topicsDiscussed;
  final DateTime lastChatDate;
  final int streakDays;
  final Map<String, dynamic>? additionalStats;

  BibleChatStats({
    required this.totalConversations,
    required this.totalMessages,
    required this.averageConversationLength,
    required this.topicsDiscussed,
    required this.lastChatDate,
    required this.streakDays,
    this.additionalStats,
  });

  /// Create from map
  factory BibleChatStats.fromMap(Map<String, dynamic> data) {
    return BibleChatStats(
      totalConversations: data['totalConversations'] ?? 0,
      totalMessages: data['totalMessages'] ?? 0,
      averageConversationLength: data['averageConversationLength'] ?? 0,
      topicsDiscussed: Map<String, int>.from(data['topicsDiscussed'] ?? {}),
      lastChatDate: DateTime.parse(data['lastChatDate'] ?? DateTime.now().toIso8601String()),
      streakDays: data['streakDays'] ?? 0,
      additionalStats: data['additionalStats'] != null
          ? Map<String, dynamic>.from(data['additionalStats'])
          : null,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'totalConversations': totalConversations,
      'totalMessages': totalMessages,
      'averageConversationLength': averageConversationLength,
      'topicsDiscussed': topicsDiscussed,
      'lastChatDate': lastChatDate.toIso8601String(),
      'streakDays': streakDays,
      'additionalStats': additionalStats,
    };
  }
}
