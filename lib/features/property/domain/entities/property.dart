import 'package:equatable/equatable.dart';

enum ListingType { sale, rent }

enum PropertyType { house, apartment, land, commercial }

enum PropertyStatus { pendingApproval, approved, rejected }

enum MediaType { image, video }

class PropertyImage extends Equatable {
  const PropertyImage({
    required this.imageUrl,
    this.id,
    this.mediaType = MediaType.image,
    this.caption,
    this.displayOrder,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) => PropertyImage(
        id: json['id'] as int?,
        imageUrl: json['imageUrl'] as String? ?? '',
        mediaType: _parseMediaType(json['mediaType'] as String?),
        caption: json['caption'] as String?,
        displayOrder: json['displayOrder'] as int?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'imageUrl': imageUrl,
        'mediaType': mediaType == MediaType.video ? 'VIDEO' : 'IMAGE',
        if (caption != null) 'caption': caption,
        if (displayOrder != null) 'displayOrder': displayOrder,
      };

  final int? id;
  final String imageUrl;
  final MediaType mediaType;
  final String? caption;
  final int? displayOrder;

  @override
  List<Object?> get props => [id, imageUrl, mediaType];
}

class Property extends Equatable {
  const Property({
    required this.id,
    required this.title,
    required this.listingType,
    required this.propertyType,
    required this.price,
    required this.address,
    this.description,
    this.city,
    this.state,
    this.pincode,
    this.locality,
    this.latitude,
    this.longitude,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.amenities,
    this.status,
    this.ownerId,
    this.ownerName,
    this.isPremium,
    this.images,
    this.viewCount,
    this.featured,
    this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        listingType: _parseListingType(json['listingType'] as String?),
        propertyType: _parsePropertyType(json['propertyType'] as String?),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String? ?? '',
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
        locality: json['locality'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        bedrooms: json['bedrooms'] as int?,
        bathrooms: json['bathrooms'] as int?,
        areaSqft: (json['areaSqft'] as num?)?.toDouble(),
        amenities: json['amenities'] as String?,
        status: _parseStatus(json['status'] as String?),
        ownerId: json['ownerId'] as int?,
        ownerName: json['ownerName'] as String?,
        isPremium: json['isPremium'] as bool?,
        images: (json['images'] as List<dynamic>?)
            ?.map((e) => PropertyImage.fromJson(e as Map<String, dynamic>))
            .toList(),
        viewCount: json['viewCount'] as int?,
        featured: json['featured'] as bool?,
        createdAt: json['createdAt'] as String?,
      );

  final int id;
  final String title;
  final String? description;
  final ListingType listingType;
  final PropertyType propertyType;
  final double price;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? locality;
  final double? latitude;
  final double? longitude;
  final int? bedrooms;
  final int? bathrooms;
  final double? areaSqft;
  final String? amenities;
  final PropertyStatus? status;
  final int? ownerId;
  final String? ownerName;
  final bool? isPremium;
  final List<PropertyImage>? images;
  final int? viewCount;
  final bool? featured;
  final String? createdAt;

  List<String> get amenitiesList =>
      amenities?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];

  Map<String, dynamic> toCreateJson() => {
        'title': title,
        if (description != null) 'description': description,
        'listingType': listingType == ListingType.sale ? 'SALE' : 'RENT',
        'propertyType': _propertyTypeToApi(propertyType),
        'price': price,
        'address': address,
        if (locality != null) 'locality': locality,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (bathrooms != null) 'bathrooms': bathrooms,
        if (areaSqft != null) 'areaSqft': areaSqft,
        if (amenities != null) 'amenities': amenities,
        if (images != null) 'images': images!.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, title, price, status];
}

ListingType _parseListingType(String? v) => v == 'RENT' ? ListingType.rent : ListingType.sale;

PropertyType _parsePropertyType(String? v) => switch (v) {
      'APARTMENT' => PropertyType.apartment,
      'LAND' => PropertyType.land,
      'COMMERCIAL' => PropertyType.commercial,
      _ => PropertyType.house,
    };

String _propertyTypeToApi(PropertyType t) => switch (t) {
      PropertyType.apartment => 'APARTMENT',
      PropertyType.land => 'LAND',
      PropertyType.commercial => 'COMMERCIAL',
      PropertyType.house => 'HOUSE',
    };

PropertyStatus? _parseStatus(String? v) => switch (v) {
      'APPROVED' => PropertyStatus.approved,
      'REJECTED' => PropertyStatus.rejected,
      'PENDING_APPROVAL' => PropertyStatus.pendingApproval,
      _ => null,
    };

MediaType _parseMediaType(String? v) => v == 'VIDEO' ? MediaType.video : MediaType.image;

class CarouselSlide {
  const CarouselSlide({
    required this.id,
    required this.imageUrl,
    required this.displayOrder,
    required this.active,
    this.linkUrl,
    this.altText,
  });

  factory CarouselSlide.fromJson(Map<String, dynamic> json) => CarouselSlide(
        id: json['id'] as int,
        imageUrl: json['imageUrl'] as String? ?? '',
        linkUrl: json['linkUrl'] as String?,
        altText: json['altText'] as String?,
        displayOrder: json['displayOrder'] as int? ?? 0,
        active: json['active'] as bool? ?? true,
      );

  final int id;
  final String imageUrl;
  final String? linkUrl;
  final String? altText;
  final int displayOrder;
  final bool active;
}

class SiteVisit extends Equatable {
  const SiteVisit({
    required this.id,
    required this.propertyId,
    required this.scheduledAt,
    required this.status,
    this.propertyTitle,
    this.userNotes,
  });

  factory SiteVisit.fromJson(Map<String, dynamic> json) => SiteVisit(
        id: json['id'] as int,
        propertyId: json['propertyId'] as int? ?? 0,
        propertyTitle: json['propertyTitle'] as String?,
        scheduledAt: json['scheduledAt'] as String? ?? '',
        status: json['status'] as String? ?? '',
        userNotes: json['userNotes'] as String?,
      );

  final int id;
  final int propertyId;
  final String? propertyTitle;
  final String scheduledAt;
  final String status;
  final String? userNotes;

  bool get canReschedule => status == 'PENDING_ASSIGNMENT' || status == 'ASSIGNED';
  bool get isAssigned => status == 'ASSIGNED';

  @override
  List<Object?> get props => [id, status, scheduledAt];
}

class AlertItem extends Equatable {
  const AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        read: json['read'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
      );

  final int id;
  final String title;
  final String message;
  final bool read;
  final String createdAt;

  @override
  List<Object?> get props => [id, read];
}
