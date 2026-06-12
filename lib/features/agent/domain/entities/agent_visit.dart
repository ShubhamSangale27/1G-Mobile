import 'package:equatable/equatable.dart';

class AgentVisitRow extends Equatable {
  const AgentVisitRow({
    required this.id,
    required this.userId,
    required this.userName,
    required this.propertyId,
    required this.propertyTitle,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    this.agentId,
    this.agentName,
    this.userNotes,
  });

  factory AgentVisitRow.fromJson(Map<String, dynamic> json) => AgentVisitRow(
        id: json['id'] as int,
        userId: json['userId'] as int? ?? 0,
        userName: json['userName'] as String? ?? '',
        propertyId: json['propertyId'] as int? ?? 0,
        propertyTitle: json['propertyTitle'] as String? ?? '',
        agentId: json['agentId'] as int?,
        agentName: json['agentName'] as String?,
        scheduledAt: json['scheduledAt'] as String? ?? '',
        userNotes: json['userNotes'] as String?,
        status: json['status'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );

  final int id;
  final int userId;
  final String userName;
  final int propertyId;
  final String propertyTitle;
  final int? agentId;
  final String? agentName;
  final String scheduledAt;
  final String? userNotes;
  final String status;
  final String createdAt;

  bool get isAssigned => status == 'ASSIGNED';
  bool get isCompleted => status == 'COMPLETED';

  AgentVisitRow copyWith({String? status}) => AgentVisitRow(
        id: id,
        userId: userId,
        userName: userName,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        agentId: agentId,
        agentName: agentName,
        scheduledAt: scheduledAt,
        userNotes: userNotes,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, status, scheduledAt];
}

class AgentVisitsPage extends Equatable {
  const AgentVisitsPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.dueTodayCount,
  });

  factory AgentVisitsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    return AgentVisitsPage(
      content: raw is List
          ? raw.map((e) => AgentVisitRow.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      dueTodayCount: json['dueTodayCount'] as int? ?? 0,
    );
  }

  final List<AgentVisitRow> content;
  final int totalElements;
  final int totalPages;
  final int dueTodayCount;

  @override
  List<Object?> get props => [content.length, totalPages, dueTodayCount];
}

class AgentPropertySummary {
  const AgentPropertySummary({
    required this.id,
    required this.title,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.listingType,
    this.propertyType,
    this.price,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.amenities,
    this.firstImageUrl,
  });

  factory AgentPropertySummary.fromJson(Map<String, dynamic> json) => AgentPropertySummary(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
        listingType: json['listingType'] as String?,
        propertyType: json['propertyType'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        bedrooms: json['bedrooms'] as int?,
        bathrooms: json['bathrooms'] as int?,
        areaSqft: (json['areaSqft'] as num?)?.toDouble(),
        amenities: json['amenities'] as String?,
        firstImageUrl: json['firstImageUrl'] as String?,
      );

  final int id;
  final String title;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? listingType;
  final String? propertyType;
  final double? price;
  final int? bedrooms;
  final int? bathrooms;
  final double? areaSqft;
  final String? amenities;
  final String? firstImageUrl;
}

class AgentVisitComment extends Equatable {
  const AgentVisitComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.commentText,
    required this.createdAt,
  });

  factory AgentVisitComment.fromJson(Map<String, dynamic> json) => AgentVisitComment(
        id: json['id'] as int,
        userId: json['userId'] as int? ?? 0,
        userName: json['userName'] as String? ?? '',
        commentText: json['commentText'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );

  final int id;
  final int userId;
  final String userName;
  final String commentText;
  final String createdAt;

  @override
  List<Object?> get props => [id];
}

class AgentVisitDetail extends Equatable {
  const AgentVisitDetail({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    required this.propertyId,
    required this.property,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    required this.comments,
    this.agentId,
    this.agentName,
    this.userNotes,
  });

  factory AgentVisitDetail.fromJson(Map<String, dynamic> json) => AgentVisitDetail(
        id: json['id'] as int,
        userId: json['userId'] as int? ?? 0,
        userName: json['userName'] as String? ?? '',
        userEmail: json['userEmail'] as String? ?? '',
        userMobile: json['userMobile'] as String? ?? '',
        propertyId: json['propertyId'] as int? ?? 0,
        property: AgentPropertySummary.fromJson(
          json['property'] as Map<String, dynamic>? ?? {},
        ),
        agentId: json['agentId'] as int?,
        agentName: json['agentName'] as String?,
        scheduledAt: json['scheduledAt'] as String? ?? '',
        userNotes: json['userNotes'] as String?,
        status: json['status'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        comments: (json['comments'] as List<dynamic>?)
                ?.map((e) => AgentVisitComment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String userMobile;
  final int propertyId;
  final AgentPropertySummary property;
  final int? agentId;
  final String? agentName;
  final String scheduledAt;
  final String? userNotes;
  final String status;
  final String createdAt;
  final List<AgentVisitComment> comments;

  AgentVisitDetail copyWith({String? status, List<AgentVisitComment>? comments}) =>
      AgentVisitDetail(
        id: id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userMobile: userMobile,
        propertyId: propertyId,
        property: property,
        agentId: agentId,
        agentName: agentName,
        scheduledAt: scheduledAt,
        userNotes: userNotes,
        status: status ?? this.status,
        createdAt: createdAt,
        comments: comments ?? this.comments,
      );

  @override
  List<Object?> get props => [id, status, comments.length];
}
