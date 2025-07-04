// lib/src/features/announcements/models/announcement_model.dart

import 'package:flutter/material.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // 'text' or 'image'
  final String imageUrl;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? expiresAt;

  // ✅ NEW: Customization options
  final String? textColor;
  final String? backgroundColor;
  final String? backgroundGradient;
  final String? textStyle; // 'normal', 'bold', 'italic', 'bold-italic'
  final double? fontSize;
  final String? selectedIcon;
  final String? iconColor;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.imageUrl,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    required this.createdBy,
    this.expiresAt,
    // ✅ NEW: Customization fields
    this.textColor,
    this.backgroundColor,
    this.backgroundGradient,
    this.textStyle,
    this.fontSize,
    this.selectedIcon,
    this.iconColor,
  });

  /// Create Announcement from Firebase data
  factory Announcement.fromJson(Map<String, dynamic> json, String id) {
    return Announcement(
      id: id,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isActive: json['isActive'] == true,
      priority: json['priority'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      createdBy: json['createdBy']?.toString() ?? 'Unknown',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'].toString())
          : null,
      // ✅ NEW: Parse customization fields
      textColor: json['textColor']?.toString(),
      backgroundColor: json['backgroundColor']?.toString(),
      backgroundGradient: json['backgroundGradient']?.toString(),
      textStyle: json['textStyle']?.toString(),
      fontSize: json['fontSize']?.toDouble(),
      selectedIcon: json['selectedIcon']?.toString(),
      iconColor: json['iconColor']?.toString(),
    );
  }

  /// Convert Announcement to Firebase data
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      // ✅ NEW: Include customization fields
      if (textColor != null) 'textColor': textColor,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (backgroundGradient != null) 'backgroundGradient': backgroundGradient,
      if (textStyle != null) 'textStyle': textStyle,
      if (fontSize != null) 'fontSize': fontSize,
      if (selectedIcon != null) 'selectedIcon': selectedIcon,
      if (iconColor != null) 'iconColor': iconColor,
    };
  }

  /// Create a copy with updated fields
  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? imageUrl,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
    String? createdBy,
    DateTime? expiresAt,
    String? textColor,
    String? backgroundColor,
    String? backgroundGradient,
    String? textStyle,
    double? fontSize,
    String? selectedIcon,
    String? iconColor,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      textStyle: textStyle ?? this.textStyle,
      fontSize: fontSize ?? this.fontSize,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  /// Check if announcement is currently valid (not expired)
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Check if announcement is text-based
  bool get isText => type == 'text';

  /// Check if announcement is image-based
  bool get isImage => type == 'image';

  /// Get display text for the announcement
  String get displayText {
    if (isText && content.isNotEmpty) {
      return content;
    } else if (isImage && title.isNotEmpty) {
      return title;
    }
    return title;
  }

  /// Get formatted creation date
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted expiration date
  String? get formattedExpirationDate {
    if (expiresAt == null) return null;
    return '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  /// Check if announcement expires soon (within 7 days)
  bool get expiresSoon {
    if (expiresAt == null) return false;
    final daysUntilExpiration = expiresAt!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration >= 0;
  }

  /// Check if announcement is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// ✅ NEW: Get text style as FontWeight and FontStyle
  FontWeight get fontWeight {
    if (textStyle?.contains('bold') == true) return FontWeight.bold;
    return FontWeight.normal;
  }

  FontStyle get fontStyle {
    if (textStyle?.contains('italic') == true) return FontStyle.italic;
    return FontStyle.normal;
  }

  /// ✅ NEW: Get effective font size
  double get effectiveFontSize => fontSize ?? 14.0;

  @override
  String toString() {
    return 'Announcement{id: $id, title: $title, type: $type, isActive: $isActive, priority: $priority}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Announcement &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.type == type &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive &&
        other.priority == priority &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.expiresAt == expiresAt &&
        other.textColor == textColor &&
        other.backgroundColor == backgroundColor &&
        other.backgroundGradient == backgroundGradient &&
        other.textStyle == textStyle &&
        other.fontSize == fontSize &&
        other.selectedIcon == selectedIcon &&
        other.iconColor == iconColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      type,
      imageUrl,
      isActive,
      priority,
      createdAt,
      createdBy,
      expiresAt,
      textColor,
      backgroundColor,
      backgroundGradient,
      textStyle,
      fontSize,
      selectedIcon,
      iconColor,
    );
  }
}

/// ✅ NEW: Helper class for customization options
class AnnouncementTheme {
  static const Map<String, Color> textColors = {
    'white': Color(0xFFFFFFFF),
    'black': Color(0xFF000000),
    'blue': Color(0xFF2196F3),
    'green': Color(0xFF4CAF50),
    'red': Color(0xFFF44336),
    'orange': Color(0xFFFF9800),
    'purple': Color(0xFF9C27B0),
    'indigo': Color(0xFF3F51B5),
    'teal': Color(0xFF009688),
    'amber': Color(0xFFFFC107),
  };

  static const Map<String, Color> backgroundColors = {
    'light_blue': Color(0xFFE3F2FD),
    'light_green': Color(0xFFE8F5E8),
    'light_red': Color(0xFFFFEBEE),
    'light_orange': Color(0xFFFFF3E0),
    'light_purple': Color(0xFFF3E5F5),
    'light_indigo': Color(0xFFE8EAF6),
    'light_teal': Color(0xFFE0F2F1),
    'light_amber': Color(0xFFFFF8E1),
    'dark_blue': Color(0xFF1976D2),
    'dark_green': Color(0xFF388E3C),
    'dark_red': Color(0xFFD32F2F),
    'dark_orange': Color(0xFFF57C00),
    'dark_purple': Color(0xFF7B1FA2),
    'dark_indigo': Color(0xFF303F9F),
    'dark_teal': Color(0xFF00796B),
    'dark_amber': Color(0xFFFF8F00),
  };

  static const Map<String, List<Color>> backgroundGradients = {
    'blue_gradient': [Color(0xFF2196F3), Color(0xFF64B5F6)],
    'green_gradient': [Color(0xFF4CAF50), Color(0xFF81C784)],
    'red_gradient': [Color(0xFFF44336), Color(0xFFEF5350)],
    'orange_gradient': [Color(0xFFFF9800), Color(0xFFFFB74D)],
    'purple_gradient': [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    'indigo_gradient': [Color(0xFF3F51B5), Color(0xFF7986CB)],
    'teal_gradient': [Color(0xFF009688), Color(0xFF4DB6AC)],
    'amber_gradient': [Color(0xFFFFC107), Color(0xFFFFD54F)],
    'sunset_gradient': [Color(0xFFFF7043), Color(0xFFFFAB40)],
    'ocean_gradient': [Color(0xFF00BCD4), Color(0xFF4FC3F7)],
    'forest_gradient': [Color(0xFF66BB6A), Color(0xFF81C784)],
    'royal_gradient': [Color(0xFF5E35B1), Color(0xFF7E57C2)],
  };

  static const Map<String, IconData> iconCollection = {
    // General
    'campaign': Icons.campaign,
    'announcement': Icons.announcement,
    'info': Icons.info,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'thumb_up': Icons.thumb_up,
    'celebration': Icons.celebration,

    // Events
    'event': Icons.event,
    'calendar': Icons.calendar_today,
    'schedule': Icons.schedule,
    'alarm': Icons.alarm,
    'access_time': Icons.access_time,

    // Business
    'business': Icons.business,
    'trending_up': Icons.trending_up,
    'analytics': Icons.analytics,
    'money': Icons.attach_money,
    'shopping': Icons.shopping_cart,
    'local_offer': Icons.local_offer,

    // Social
    'people': Icons.people,
    'group': Icons.group,
    'forum': Icons.forum,
    'chat': Icons.chat,
    'message': Icons.message,

    // Technology
    'computer': Icons.computer,
    'phone': Icons.phone,
    'wifi': Icons.wifi,
    'cloud': Icons.cloud,
    'security': Icons.security,
    'update': Icons.update,

    // Weather
    'wb_sunny': Icons.wb_sunny,
    'wb_cloudy': Icons.wb_cloudy,
    'umbrella': Icons.umbrella,
    'ac_unit': Icons.ac_unit,

    // Food & Drink
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'cake': Icons.cake,
    'local_pizza': Icons.local_pizza,

    // Transportation
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'train': Icons.train,
    'directions_bus': Icons.directions_bus,

    // Health
    'health_and_safety': Icons.health_and_safety,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center,
    'spa': Icons.spa,

    // Education
    'school': Icons.school,
    'menu_book': Icons.menu_book,
    'quiz': Icons.quiz,
    'psychology': Icons.psychology,

    // Entertainment
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'games': Icons.games,
    'sports_soccer': Icons.sports_soccer,

    // Location
    'location_on': Icons.location_on,
    'map': Icons.map,
    'home': Icons.home,
    'work': Icons.work,
  };

  static Color getTextColor(String? colorName) {
    if (colorName == null) return textColors['black']!;
    return textColors[colorName] ?? textColors['black']!;
  }

  static Color getBackgroundColor(String? colorName) {
    if (colorName == null) return backgroundColors['light_blue']!;
    return backgroundColors[colorName] ?? backgroundColors['light_blue']!;
  }

  static List<Color> getGradientColors(String? gradientName) {
    if (gradientName == null) return backgroundGradients['blue_gradient']!;
    return backgroundGradients[gradientName] ??
        backgroundGradients['blue_gradient']!;
  }

  static IconData getIcon(String? iconName) {
    if (iconName == null) return iconCollection['campaign']!;
    return iconCollection[iconName] ?? iconCollection['campaign']!;
  }

  static Color getIconColor(String? colorName) {
    if (colorName == null) return textColors['indigo']!;
    return textColors[colorName] ?? textColors['indigo']!;
  }
}
