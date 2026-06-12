import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/agent_visit.dart';

class AgentRepository {
  AgentRepository(this._dio);

  final Dio _dio;

  Future<AgentVisitsPage> getSiteVisits({int page = 0, int size = 20}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/agent/sitevisits',
        queryParameters: {'page': page, 'size': size},
      );
      return AgentVisitsPage.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AgentVisitDetail> getVisitDetail(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/agent/sitevisits/$id');
      return AgentVisitDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> completeVisit(int visitId, String otp) async {
    try {
      await _dio.post<void>(
        '/agent/sitevisits/$visitId/complete',
        queryParameters: {'otp': otp},
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AgentVisitComment> addComment(int visitId, String commentText) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/agent/sitevisits/$visitId/comments',
        data: {'commentText': commentText},
      );
      return AgentVisitComment.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepository(ref.watch(dioProvider));
});
