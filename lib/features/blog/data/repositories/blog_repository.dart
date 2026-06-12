import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/memory_cache.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/blog_post.dart';

class BlogRepository {
  BlogRepository(this._dio);

  final Dio _dio;
  final _cache = MemoryCache.instance;

  Future<List<BlogPost>> getPublished({
    int page = 0,
    int size = 24,
    String? category,
    String? tag,
    bool forceRefresh = false,
  }) {
    final key = 'blogs:published:$page:$size:${category ?? ''}:${tag ?? ''}';
    return _cache.getOrFetch(
      key: key,
      forceRefresh: forceRefresh,
      ttl: const Duration(minutes: 5),
      fetch: () => _fetchPublished(page: page, size: size, category: category, tag: tag),
    );
  }

  Future<List<BlogPost>> _fetchPublished({
    required int page,
    required int size,
    String? category,
    String? tag,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (category != null && category.isNotEmpty) params['category'] = category;
      if (tag != null && tag.isNotEmpty) params['tag'] = tag;
      final res = await _dio.get<dynamic>('/blogs/published', queryParameters: params);
      return _parseList(res.data);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BlogPost> getBySlug(String slug) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/blogs/published/${Uri.encodeComponent(slug)}',
      );
      return BlogPost.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BlogFilters> getFilters() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/blogs/published/filters');
      return BlogFilters.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  List<BlogPost> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => BlogPost.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic>) {
      final content = data['content'] as List<dynamic>? ?? [];
      return content.map((e) => BlogPost.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(ref.watch(dioProvider));
});
