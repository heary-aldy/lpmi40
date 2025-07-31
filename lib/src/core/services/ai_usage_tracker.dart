// 📊 AI Usage Tracker Service
// Tracks API usage for GitHub Models and other AI providers

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIUsageStats {
  final String provider;
  final String model;
  final DateTime date;
  final int requestCount;
  final int totalTokens;
  final int promptTokens;
  final int completionTokens;
  final double cost; // Estimated cost if available
  final Map<String, dynamic> metadata;

  AIUsageStats({
    required this.provider,
    required this.model,
    required this.date,
    required this.requestCount,
    required this.totalTokens,
    required this.promptTokens,
    required this.completionTokens,
    this.cost = 0.0,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'model': model,
      'date': date.toIso8601String(),
      'requestCount': requestCount,
      'totalTokens': totalTokens,
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'cost': cost,
      'metadata': metadata,
    };
  }

  factory AIUsageStats.fromMap(Map<String, dynamic> map) {
    return AIUsageStats(
      provider: map['provider'] ?? '',
      model: map['model'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      requestCount: map['requestCount'] ?? 0,
      totalTokens: map['totalTokens'] ?? 0,
      promptTokens: map['promptTokens'] ?? 0,
      completionTokens: map['completionTokens'] ?? 0,
      cost: (map['cost'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class AIUsageLimits {
  final int dailyRequestLimit;
  final int hourlyRequestLimit;
  final int dailyTokenLimit;
  final int monthlyRequestLimit;
  final double monthlyCostLimit;

  const AIUsageLimits({
    this.dailyRequestLimit = 1000,
    this.hourlyRequestLimit = 60,
    this.dailyTokenLimit = 100000,
    this.monthlyRequestLimit = 10000,
    this.monthlyCostLimit = 50.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyRequestLimit': dailyRequestLimit,
      'hourlyRequestLimit': hourlyRequestLimit,
      'dailyTokenLimit': dailyTokenLimit,
      'monthlyRequestLimit': monthlyRequestLimit,
      'monthlyCostLimit': monthlyCostLimit,
    };
  }

  factory AIUsageLimits.fromMap(Map<String, dynamic> map) {
    return AIUsageLimits(
      dailyRequestLimit: map['dailyRequestLimit'] ?? 1000,
      hourlyRequestLimit: map['hourlyRequestLimit'] ?? 60,
      dailyTokenLimit: map['dailyTokenLimit'] ?? 100000,
      monthlyRequestLimit: map['monthlyRequestLimit'] ?? 10000,
      monthlyCostLimit: (map['monthlyCostLimit'] ?? 50.0).toDouble(),
    );
  }
}

class AIUsageTracker {
  static final AIUsageTracker _instance = AIUsageTracker._internal();
  factory AIUsageTracker() => _instance;
  AIUsageTracker._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for local storage
  SharedPreferences? _prefs;

  // Current usage stats
  final Map<String, AIUsageStats> _todayStats = {};
  AIUsageLimits _limits = const AIUsageLimits();

  /// Initialize the usage tracker
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadTodayStats();
      await _loadUsageLimits();
      debugPrint('✅ AI Usage Tracker initialized');
    } catch (e) {
      debugPrint('❌ Error initializing AI Usage Tracker: $e');
    }
  }

  /// Track API usage
  Future<void> trackUsage({
    required String provider,
    required String model,
    required int promptTokens,
    required int completionTokens,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final totalTokens = promptTokens + completionTokens;
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final statsKey = '${provider}_${model}_$dateKey';

      // Update or create stats for today
      final existingStats = _todayStats[statsKey];
      final updatedStats = AIUsageStats(
        provider: provider,
        model: model,
        date: DateTime(now.year, now.month, now.day),
        requestCount: (existingStats?.requestCount ?? 0) + 1,
        totalTokens: (existingStats?.totalTokens ?? 0) + totalTokens,
        promptTokens: (existingStats?.promptTokens ?? 0) + promptTokens,
        completionTokens:
            (existingStats?.completionTokens ?? 0) + completionTokens,
        cost: (existingStats?.cost ?? 0.0) +
            _estimateCost(provider, model, totalTokens),
        metadata: {
          ...existingStats?.metadata ?? {},
          ...metadata ?? {},
          'lastUsed': now.toIso8601String(),
        },
      );

      _todayStats[statsKey] = updatedStats;

      // Save to local storage
      await _saveStatsLocally(statsKey, updatedStats);

      // Save to Firebase (global stats)
      await _saveStatsToFirebase(updatedStats);

      debugPrint('📊 Usage tracked: $provider/$model - $totalTokens tokens');
    } catch (e) {
      debugPrint('❌ Error tracking usage: $e');
    }
  }

  /// Get today's usage for a specific provider
  AIUsageStats? getTodayUsage(String provider, String model) {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final statsKey = '${provider}_${model}_$dateKey';
    return _todayStats[statsKey];
  }

  /// Get total usage for today (all providers)
  Map<String, dynamic> getTodayTotalUsage() {
    int totalRequests = 0;
    int totalTokens = 0;
    double totalCost = 0.0;
    Map<String, int> providerBreakdown = {};

    for (final stats in _todayStats.values) {
      final today = DateTime.now();
      if (stats.date.day == today.day &&
          stats.date.month == today.month &&
          stats.date.year == today.year) {
        totalRequests += stats.requestCount;
        totalTokens += stats.totalTokens;
        totalCost += stats.cost;

        final key = '${stats.provider}/${stats.model}';
        providerBreakdown[key] =
            (providerBreakdown[key] ?? 0) + stats.requestCount;
      }
    }

    return {
      'totalRequests': totalRequests,
      'totalTokens': totalTokens,
      'totalCost': totalCost,
      'providerBreakdown': providerBreakdown,
      'limits': _limits.toMap(),
      'percentages': {
        'requestsUsed': (_limits.dailyRequestLimit > 0)
            ? (totalRequests / _limits.dailyRequestLimit * 100)
            : 0,
        'tokensUsed': (_limits.dailyTokenLimit > 0)
            ? (totalTokens / _limits.dailyTokenLimit * 100)
            : 0,
      }
    };
  }

  /// Check if usage limits are exceeded
  Map<String, bool> checkUsageLimits() {
    final todayStats = getTodayTotalUsage();
    final totalRequests = todayStats['totalRequests'] as int;
    final totalTokens = todayStats['totalTokens'] as int;

    return {
      'dailyRequestsExceeded': totalRequests >= _limits.dailyRequestLimit,
      'dailyTokensExceeded': totalTokens >= _limits.dailyTokenLimit,
      'nearDailyRequestLimit':
          totalRequests >= (_limits.dailyRequestLimit * 0.8),
      'nearDailyTokenLimit': totalTokens >= (_limits.dailyTokenLimit * 0.8),
    };
  }

  /// Get hourly usage for rate limiting
  Future<int> getHourlyRequestCount(String provider, String model) async {
    try {
      final now = DateTime.now();
      final hourStart = DateTime(now.year, now.month, now.day, now.hour);

      // Check Firebase for accurate hourly count
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _database
            .ref('system/ai_usage/hourly/${user.uid}/${provider}_$model')
            .child('${hourStart.millisecondsSinceEpoch}')
            .get();

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          return data['requestCount'] ?? 0;
        }
      }

      return 0;
    } catch (e) {
      debugPrint('❌ Error getting hourly usage: $e');
      return 0;
    }
  }

  /// Update usage limits
  Future<void> updateLimits(AIUsageLimits newLimits) async {
    try {
      _limits = newLimits;

      // Save to local storage
      if (_prefs != null) {
        await _prefs!
            .setString('ai_usage_limits', jsonEncode(newLimits.toMap()));
      }

      // Save to Firebase (admin only)
      final user = _auth.currentUser;
      if (user != null) {
        await _database.ref('system/ai_usage/limits').set(newLimits.toMap());
      }

      debugPrint('✅ Usage limits updated');
    } catch (e) {
      debugPrint('❌ Error updating limits: $e');
    }
  }

  /// Get historical usage data
  Future<List<AIUsageStats>> getHistoricalUsage({
    String? provider,
    String? model,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final ref = _database.ref('system/ai_usage/daily/${user.uid}');
      final snapshot = await ref
          .orderByChild('date')
          .startAt(start.toIso8601String())
          .endAt(end.toIso8601String())
          .limitToLast(limit)
          .get();

      final stats = <AIUsageStats>[];
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          try {
            final statsData = Map<String, dynamic>.from(entry.value as Map);
            final stat = AIUsageStats.fromMap(statsData);

            // Filter by provider/model if specified
            if ((provider == null || stat.provider == provider) &&
                (model == null || stat.model == model)) {
              stats.add(stat);
            }
          } catch (e) {
            debugPrint('❌ Error parsing usage stat: $e');
          }
        }
      }

      return stats..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('❌ Error getting historical usage: $e');
      return [];
    }
  }

  /// Load today's stats from local storage
  Future<void> _loadTodayStats() async {
    try {
      if (_prefs == null) return;

      final todayKey = _getTodayKey();
      final statsJson = _prefs!.getString('ai_usage_$todayKey');

      if (statsJson != null) {
        final statsMap = jsonDecode(statsJson) as Map<String, dynamic>;
        for (final entry in statsMap.entries) {
          try {
            _todayStats[entry.key] = AIUsageStats.fromMap(
                Map<String, dynamic>.from(entry.value as Map));
          } catch (e) {
            debugPrint('❌ Error loading stat ${entry.key}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading today stats: $e');
    }
  }

  /// Load usage limits
  Future<void> _loadUsageLimits() async {
    try {
      // Try Firebase first (admin settings)
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _database.ref('system/ai_usage/limits').get();
        if (snapshot.exists) {
          _limits = AIUsageLimits.fromMap(
              Map<String, dynamic>.from(snapshot.value as Map));
          return;
        }
      }

      // Fallback to local storage
      if (_prefs != null) {
        final limitsJson = _prefs!.getString('ai_usage_limits');
        if (limitsJson != null) {
          _limits = AIUsageLimits.fromMap(jsonDecode(limitsJson));
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading usage limits: $e');
    }
  }

  /// Save stats to local storage
  Future<void> _saveStatsLocally(String statsKey, AIUsageStats stats) async {
    try {
      if (_prefs == null) return;

      final todayKey = _getTodayKey();
      final existingJson = _prefs!.getString('ai_usage_$todayKey') ?? '{}';
      final existingStats = jsonDecode(existingJson) as Map<String, dynamic>;

      existingStats[statsKey] = stats.toMap();
      await _prefs!.setString('ai_usage_$todayKey', jsonEncode(existingStats));
    } catch (e) {
      debugPrint('❌ Error saving stats locally: $e');
    }
  }

  /// Save stats to Firebase
  Future<void> _saveStatsToFirebase(AIUsageStats stats) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateKey = stats.date.toIso8601String().split('T')[0];
      // Clean model name for Firebase path (remove dots, spaces, special chars)
      final cleanModel = stats.model.replaceAll(RegExp(r'[.#\[\]\s]'), '_');
      final statsKey = '${stats.provider}_$cleanModel';

      // Save daily stats
      await _database
          .ref('system/ai_usage/daily/${user.uid}/$dateKey/$statsKey')
          .set(stats.toMap());

      // Save hourly stats for rate limiting
      final now = DateTime.now();
      final hourKey = DateTime(now.year, now.month, now.day, now.hour)
          .millisecondsSinceEpoch;
      await _database
          .ref('system/ai_usage/hourly/${user.uid}/$statsKey/$hourKey')
          .set({
        'requestCount': stats.requestCount,
        'timestamp': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error saving stats to Firebase: $e');
    }
  }

  /// Estimate cost based on provider and usage
  double _estimateCost(String provider, String model, int totalTokens) {
    // GitHub Models is free for now, but we can estimate based on equivalent costs
    switch (provider.toLowerCase()) {
      case 'github':
        return 0.0; // Currently free
      case 'openai':
        switch (model.toLowerCase()) {
          case 'gpt-3.5-turbo':
            return (totalTokens / 1000) * 0.002; // $0.002 per 1K tokens
          case 'gpt-4':
            return (totalTokens / 1000) * 0.03; // $0.03 per 1K tokens
          default:
            return (totalTokens / 1000) * 0.002;
        }
      case 'gemini':
        return (totalTokens / 1000) * 0.001; // Estimated
      default:
        return 0.0;
    }
  }

  /// Get today's date key
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get usage for a specific provider (for quota management)
  Future<Map<String, int>> getProviderUsage(String provider) async {
    int dailyRequests = 0;
    int dailyTokens = 0;
    
    for (final stats in _todayStats.values) {
      if (stats.provider.toLowerCase() == provider.toLowerCase()) {
        dailyRequests += stats.requestCount;
        dailyTokens += stats.totalTokens;
      }
    }
    
    return {
      'dailyRequests': dailyRequests,
      'dailyTokens': dailyTokens,
    };
  }

  /// Getters
  AIUsageLimits get limits => _limits;
}
