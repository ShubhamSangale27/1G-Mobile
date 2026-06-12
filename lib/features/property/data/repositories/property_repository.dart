import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/memory_cache.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../shared/models/page_response.dart';
import '../../domain/entities/property.dart';

class PropertySearchParams {
  const PropertySearchParams({
    this.page = 0,
    this.size = 12,
    this.sort = 'createdAt',
    this.direction = 'desc',
    this.city,
    this.listingType,
    this.propertyType,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.minArea,
  });

  final int page;
  final int size;
  final String sort;
  final String direction;
  final String? city;
  final String? listingType;
  final String? propertyType;
  final num? minPrice;
  final num? maxPrice;
  final int? bedrooms;
  final num? minArea;

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': sort,
      'direction': direction,
    };
    if (city != null && city!.isNotEmpty) q['city'] = city;
    if (listingType != null && listingType!.isNotEmpty) q['listingType'] = listingType;
    if (propertyType != null && propertyType!.isNotEmpty) q['propertyType'] = propertyType;
    if (minPrice != null) q['minPrice'] = minPrice;
    if (maxPrice != null) q['maxPrice'] = maxPrice;
    if (bedrooms != null) q['bedrooms'] = bedrooms;
    if (minArea != null) q['minArea'] = minArea;
    return q;
  }

  String cacheKey() => toQuery().entries.map((e) => '${e.key}=${e.value}').join('&');
}

class PropertyRepository {
  PropertyRepository(this._dio);

  final Dio _dio;
  final _cache = MemoryCache.instance;

  Future<List<Property>> getFeatured({bool forceRefresh = false}) {
    return _cache.getOrFetch(
      key: 'properties:featured',
      forceRefresh: forceRefresh,
      ttl: const Duration(minutes: 5),
      fetch: _fetchFeatured,
    );
  }

  Future<List<Property>> _fetchFeatured() async {
    try {
      final res = await _dio.get<dynamic>('/properties/public/featured');
      final data = res.data;
      if (data is List) {
        return data.map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<PageResponse<Property>> search(PropertySearchParams params, {bool forceRefresh = false}) {
    final key = 'properties:search:${params.cacheKey()}';
    return _cache.getOrFetch(
      key: key,
      forceRefresh: forceRefresh,
      ttl: const Duration(minutes: 3),
      fetch: () => _fetchSearch(params),
    );
  }

  Future<PageResponse<Property>> _fetchSearch(PropertySearchParams params) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/properties/search',
        queryParameters: params.toQuery(),
      );
      return PageResponse.fromJson(res.data!, Property.fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<Property> getById(int id, {bool includeAnalytics = false}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/properties/$id',
        queryParameters: includeAnalytics ? {'includeAnalytics': true} : null,
      );
      return Property.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<PageResponse<Property>> getMyProperties({int page = 0, int size = 12}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/properties/my',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(res.data!, Property.fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<Property> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/properties', data: payload);
      return Property.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<Property> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/properties/$id', data: payload);
      return Property.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/properties/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<bool> isInWatchlist(int propertyId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/properties/$propertyId/watchlist');
      return res.data?['inWatchlist'] as bool? ?? false;
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> addToWatchlist(int propertyId) async {
    try {
      await _dio.post('/properties/$propertyId/watchlist', data: {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> removeFromWatchlist(int propertyId) async {
    try {
      await _dio.delete('/properties/$propertyId/watchlist');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<Property>> getWatchlist({bool forceRefresh = false}) {
    return _cache.getOrFetch(
      key: 'properties:watchlist',
      forceRefresh: forceRefresh,
      ttl: const Duration(minutes: 2),
      fetch: _fetchWatchlist,
    );
  }

  Future<List<Property>> _fetchWatchlist() async {
    try {
      final res = await _dio.get<dynamic>('/properties/watchlist');
      final data = res.data;
      if (data is Map && data['content'] is List) {
        return (data['content'] as List)
            .map((e) => Property.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is List) {
        return data.map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  void invalidatePropertyCaches() {
    _cache.invalidatePrefix('properties:');
    _cache.invalidate('carousel:slides');
  }

  Future<List<CarouselSlide>> getCarouselSlides({bool forceRefresh = false}) {
    return _cache.getOrFetch(
      key: 'carousel:slides',
      forceRefresh: forceRefresh,
      ttl: const Duration(minutes: 10),
      fetch: _fetchCarouselSlides,
    );
  }

  Future<List<CarouselSlide>> _fetchCarouselSlides() async {
    try {
      final res = await _dio.get<dynamic>('/carousel/slides');
      final data = res.data;
      if (data is List) {
        return data.map((e) => CarouselSlide.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SiteVisit> bookVisit({
    required int propertyId,
    required String scheduledAt,
    String? userNotes,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/sitevisits', data: {
        'propertyId': propertyId,
        'scheduledAt': scheduledAt,
        if (userNotes != null) 'userNotes': userNotes,
      });
      return SiteVisit.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SiteVisit?> getMyVisitForProperty(int propertyId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>?>('/sitevisits/my/for-property/$propertyId');
      if (res.statusCode == 204 || res.data == null) return null;
      return SiteVisit.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204 || e.response?.statusCode == 404) return null;
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SiteVisit> rescheduleVisit(int visitId, String scheduledAt) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/sitevisits/$visitId/reschedule', data: {
        'scheduledAt': scheduledAt,
      });
      return SiteVisit.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<String> getVisitOtp(int visitId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/sitevisits/$visitId/otp');
      return res.data?['otp'] as String? ?? '';
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<String> resendVisitOtp(int visitId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/sitevisits/$visitId/resend-otp');
      return res.data?['otp'] as String? ?? '';
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<SiteVisit>> getMyVisits({int page = 0, int size = 10}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/sitevisits/my',
        queryParameters: {'page': page, 'size': size},
      );
      final content = res.data?['content'];
      if (content is List) {
        return content.map((e) => SiteVisit.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<AlertItem>> getAlerts({int page = 0, int size = 10}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/alerts',
        queryParameters: {'page': page, 'size': size},
      );
      final content = res.data?['content'];
      if (content is List) {
        return content.map((e) => AlertItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<String> uploadProfileImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post<Map<String, dynamic>>('/upload', data: formData);
      return res.data?['url'] as String? ?? '';
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(dioProvider));
});

final mediaUrlResolverProvider = Provider<MediaUrlResolver>((ref) {
  return MediaUrlResolver(ref.watch(envConfigProvider).apiBaseUrl);
});
