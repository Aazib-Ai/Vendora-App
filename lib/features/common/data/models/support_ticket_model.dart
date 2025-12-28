enum TicketType {
  contact_us,
  report_problem,
}

enum TicketStatus {
  open,
  in_progress,
  resolved,
}

class SupportTicket {
  final String? id;
  final String userId;
  final TicketType type;
  final String subject;
  final String message;
  final TicketStatus status;
  final List<String>? images;
  final DateTime? createdAt;

  SupportTicket({
    this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.message,
    this.status = TicketStatus.open,
    this.images,
    this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      type: TicketType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TicketType.contact_us,
      ),
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: TicketStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TicketStatus.open,
      ),
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'subject': subject,
      'message': message,
      'status': status.toString().split('.').last,
      if (images != null) 'images': images,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    TicketType? type,
    String? subject,
    String? message,
    TicketStatus? status,
    List<String>? images,
    DateTime? createdAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
