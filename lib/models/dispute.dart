import 'package:equatable/equatable.dart';

/// Dispute status enumeration
enum DisputeStatus {
  open,
  underReview,
  resolved,
  rejected;

  String toJson() => name;

  static DisputeStatus fromJson(String json) {
    return values.byName(json);
  }
}

/// Dispute model for order disputes
class Dispute extends Equatable {
  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final DisputeStatus status;
  final String reason;
  final String buyerDescription;
  final Map<String, dynamic> buyerEvidence;
  final String? sellerResponse;
  final Map<String, dynamic> sellerEvidence;
  final String? adminResolution;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const Dispute({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.reason,
    required this.buyerDescription,
    this.buyerEvidence = const {},
    this.sellerResponse,
    this.sellerEvidence = const {},
    this.adminResolution,
    this.resolvedAt,
    required this.createdAt,
  });

  /// Check if dispute is still open
  bool get isOpen => status == DisputeStatus.open;

  /// Check if dispute is resolved
  bool get isResolved => status == DisputeStatus.resolved;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'status': status.name,
      'reason': reason,
      'buyer_description': buyerDescription,
      'buyer_evidence': buyerEvidence,
      'seller_response': sellerResponse,
      'seller_evidence': sellerEvidence,
      'admin_resolution': adminResolution,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      status: DisputeStatus.values.byName(json['status'] as String),
      reason: json['reason'] as String,
      buyerDescription: json['buyer_description'] as String,
      buyerEvidence: json['buyer_evidence'] != null
          ? Map<String, dynamic>.from(json['buyer_evidence'] as Map)
          : {},
      sellerResponse: json['seller_response'] as String?,
      sellerEvidence: json['seller_evidence'] != null
          ? Map<String, dynamic>.from(json['seller_evidence'] as Map)
          : {},
      adminResolution: json['admin_resolution'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Dispute copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    DisputeStatus? status,
    String? reason,
    String? buyerDescription,
    Map<String, dynamic>? buyerEvidence,
    String? sellerResponse,
    Map<String, dynamic>? sellerEvidence,
    String? adminResolution,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return Dispute(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      buyerDescription: buyerDescription ?? this.buyerDescription,
      buyerEvidence: buyerEvidence ?? this.buyerEvidence,
      sellerResponse: sellerResponse ?? this.sellerResponse,
      sellerEvidence: sellerEvidence ?? this.sellerEvidence,
      adminResolution: adminResolution ?? this.adminResolution,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        buyerId,
        sellerId,
        status,
        reason,
        buyerDescription,
        buyerEvidence,
        sellerResponse,
        sellerEvidence,
        adminResolution,
        resolvedAt,
        createdAt,
      ];
}
