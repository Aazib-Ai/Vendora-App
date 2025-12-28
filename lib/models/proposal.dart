class Proposal {
  final String id;
  final String title;
  final String subtitle;
  final String buttonText;
  final String imageUrl;
  final String bgColor;
  final String actionType;
  final String? actionValue;
  final bool isActive;
  final int priority;
  final DateTime createdAt;

  const Proposal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imageUrl,
    required this.bgColor,
    this.actionType = 'none',
    this.actionValue,
    this.isActive = true,
    this.priority = 0,
    required this.createdAt,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      buttonText: json['button_text'] as String,
      imageUrl: json['image_url'] as String,
      bgColor: json['bg_color'] as String,
      actionType: json['action_type'] as String? ?? 'none',
      actionValue: json['action_value'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'button_text': buttonText,
      'image_url': imageUrl,
      'bg_color': bgColor,
      'action_type': actionType,
      'action_value': actionValue,
      'is_active': isActive,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Proposal copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? buttonText,
    String? imageUrl,
    String? bgColor,
    String? actionType,
    String? actionValue,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
  }) {
    return Proposal(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      buttonText: buttonText ?? this.buttonText,
      imageUrl: imageUrl ?? this.imageUrl,
      bgColor: bgColor ?? this.bgColor,
      actionType: actionType ?? this.actionType,
      actionValue: actionValue ?? this.actionValue,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
