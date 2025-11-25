import 'dart:io';
import 'dart:async';
import 'api_service.dart';

class FeedApi {
  static const String _feedsEndpoint = "/api/feeds/";
  static const String _myFeedsEndpoint = "/api/feeds/my-feeds/";
  static const String _uploadImagesPath = "upload-images/";
  static const String _updatePath = "update/";
  static const String _deletePath = "delete/";

  static const String _artifactNameField = "artifact_name";
  static const String _statusField = "status";
  static const String _publishedStatus = "published";
  static const String _imagesField = "images";
  static const String _idField = "id";
  static const String _errorField = "error";
  static const String _messageField = "message";

  static const String _noImagesMessage = "No images to upload";
  static const String _feedIdNotFoundError = "피드 생성 응답에서 ID를 찾을 수 없습니다";
  static const String _feedCreationError = "피드 생성 중 오류 발생";
  static const String _imageUploadError = "이미지 업로드 중 오류 발생";
  static const String _feedUpdateError = "피드 업데이트 중 오류 발생";
  static const String _feedDeleteError = "피드 삭제 중 오류 발생";

  static const double _createFeedWeight = 0.2;
  static const double _uploadImagesWeight = 0.8;
  static const int _batchSize = 2;
  static const int _batchDelayMs = 100;
  static const int _serverResponseDelayMs = 200;
  static const int _finalDelayMs = 300;

  /// 에러 응답 생성
  static Map<String, dynamic> _createErrorResponse(String message, [dynamic error]) {
    final errorMessage = error != null ? "$message: ${error.toString()}" : message;
    return {_errorField: errorMessage};
  }

  /// 피드 목록 가져오기
  static Future<dynamic> fetchFeeds() async {
    try {
      return await ApiService.sendRequest(
        endpoint: _feedsEndpoint,
        method: "GET",
      );
    } catch (e) {
      return _createErrorResponse(_errorField, e);
    }
  }

  /// 내 피드 목록 가져오기
  static Future<dynamic> fetchMyFeeds() async {
    try {
      return await ApiService.sendRequest(
        endpoint: _myFeedsEndpoint,
        method: "GET",
      );
    } catch (e) {
      return _createErrorResponse(_errorField, e);
    }
  }

  /// 피드 상세 정보 가져오기
  static Future<dynamic> fetchFeedDetail(String feedId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "$_feedsEndpoint$feedId/",
        method: "GET",
      );
    } catch (e) {
      return _createErrorResponse(_errorField, e);
    }
  }

  /// 피드 기본 정보 생성
  static Future<dynamic> _createBasicFeed(String artifactName) async {
    return await ApiService.sendRequest(
      endpoint: _feedsEndpoint,
      method: "POST",
      body: {
        _artifactNameField: artifactName,
        _statusField: _publishedStatus,
      },
    );
  }

  /// 피드 생성 응답에서 ID 추출
  static String? _extractFeedId(dynamic feedResult) {
    if (feedResult is Map && feedResult.containsKey(_idField)) {
      return feedResult[_idField].toString();
    }
    return null;
  }

  /// 이미지 배치 업로드
  static Future<void> _uploadImageBatches(
      String feedId,
      List<File> images,
      Function(double)? onProgress,
      double currentProgress,
      ) async {
    final progressPerBatch = _uploadImagesWeight / ((images.length / _batchSize).ceil());
    double totalProgress = currentProgress;

    for (int i = 0; i < images.length; i += _batchSize) {
      final end = (i + _batchSize < images.length) ? i + _batchSize : images.length;
      final batch = images.sublist(i, end);

      await Future.delayed(const Duration(milliseconds: _batchDelayMs));

      final result = await uploadFeedImages(feedId, batch);
      if (result is Map && result.containsKey(_errorField)) {
        throw Exception(result[_errorField]);
      }

      totalProgress += progressPerBatch;
      onProgress?.call(totalProgress > 1.0 ? 1.0 : totalProgress);

      await Future.delayed(const Duration(milliseconds: _serverResponseDelayMs));
    }
  }

  /// 피드 생성하기
  static Future<dynamic> createFeed({
    required String artifactName,
    required List<File> images,
    Function(double progress)? onProgress,
  }) async {
    try {
      double totalProgress = 0.0;

      // 피드 기본 정보 생성
      final feedResult = await _createBasicFeed(artifactName);

      totalProgress += _createFeedWeight;
      onProgress?.call(totalProgress);

      // 에러 확인
      if (feedResult is Map && feedResult.containsKey(_errorField)) {
        return feedResult;
      }

      // 피드 ID 추출
      final feedId = _extractFeedId(feedResult);
      if (feedId == null) {
        return _createErrorResponse(_feedIdNotFoundError);
      }

      // 이미지 업로드
      if (images.isNotEmpty) {
        await _uploadImageBatches(feedId, images, onProgress, totalProgress);
      }

      // 서버 처리 시간 대기
      await Future.delayed(const Duration(milliseconds: _finalDelayMs));

      // 최종 피드 정보 반환
      return await fetchFeedDetail(feedId);
    } catch (e) {
      return _createErrorResponse(_feedCreationError, e);
    }
  }

  /// 피드 이미지 업로드
  static Future<dynamic> uploadFeedImages(String feedId, List<File> images) async {
    try {
      if (images.isEmpty) {
        return {_messageField: _noImagesMessage};
      }

      return await ApiService.sendMultipartRequest(
        endpoint: "$_feedsEndpoint$feedId/$_uploadImagesPath",
        method: "POST",
        files: images.map((file) => {"name": _imagesField, "file": file}).toList(),
      );
    } catch (e) {
      return _createErrorResponse(_imageUploadError, e);
    }
  }

  /// 업데이트할 필드들을 body에 추가
  static void _addFieldToBody(Map<String, dynamic> body, String key, String? value) {
    if (value != null) {
      body[key] = value;
    }
  }

  /// 피드 업데이트용 body 구성
  static Map<String, dynamic> _buildUpdateBody({
    String? artifactName,
    String? status,
  }) {
    final body = <String, dynamic>{};
    _addFieldToBody(body, _artifactNameField, artifactName);
    _addFieldToBody(body, _statusField, status);
    return body;
  }

  /// 피드 업데이트
  static Future<dynamic> updateFeed({
    required String feedId,
    String? artifactName,
    String? status,
  }) async {
    try {
      final body = _buildUpdateBody(
        artifactName: artifactName,
        status: status,
      );

      return await ApiService.sendRequest(
        endpoint: "$_feedsEndpoint$feedId/$_updatePath",
        method: "PATCH",
        body: body,
      );
    } catch (e) {
      return _createErrorResponse(_feedUpdateError, e);
    }
  }

  /// 피드 삭제
  static Future<dynamic> deleteFeed(String feedId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "$_feedsEndpoint$feedId/$_deletePath",
        method: "DELETE",
      );
    } catch (e) {
      return _createErrorResponse(_feedDeleteError, e);
    }
  }
}