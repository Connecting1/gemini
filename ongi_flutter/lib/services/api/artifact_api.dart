import 'api_service.dart';

class ArtifactApi {
  static const String _artifactsEndpoint = "/api/artifacts/";
  static const String _statusParam = "status";
  static const String _feedsPath = "feeds/";
  static const String _updatePath = "update/";
  static const String _defaultStatus = 'verified';

  static const String _nameField = "name";
  static const String _descriptionField = "description";
  static const String _timePeriodField = "time_period";
  static const String _estimatedYearField = "estimated_year";
  static const String _originLocationField = "origin_location";
  static const String _statusField = "status";
  static const String _errorField = "error";

  /// 에러 응답 생성
  static Map<String, dynamic> _createErrorResponse(dynamic error) {
    return {_errorField: error.toString()};
  }

  /// 유물 목록 가져오기
  static Future<dynamic> fetchArtifacts({String status = _defaultStatus}) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "$_artifactsEndpoint?$_statusParam=$status",
        method: "GET",
      );
    } catch (e) {
      return _createErrorResponse(e);
    }
  }

  /// 유물 상세 정보 가져오기
  static Future<dynamic> fetchArtifactDetail(String artifactId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "$_artifactsEndpoint$artifactId/",
        method: "GET",
      );
    } catch (e) {
      return _createErrorResponse(e);
    }
  }

  /// 유물 관련 피드 가져오기
  static Future<dynamic> fetchArtifactFeeds(String artifactId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "$_artifactsEndpoint$artifactId/$_feedsPath",
        method: "GET",
      );
    } catch (e) {
      return _createErrorResponse(e);
    }
  }

  /// 업데이트할 필드들을 body에 추가
  static void _addFieldToBody(Map<String, dynamic> body, String key, String? value) {
    if (value != null) {
      body[key] = value;
    }
  }

  /// 유물 업데이트용 body 구성
  static Map<String, dynamic> _buildUpdateBody({
    String? name,
    String? description,
    String? timePeriod,
    String? estimatedYear,
    String? originLocation,
    String? status,
  }) {
    final body = <String, dynamic>{};

    _addFieldToBody(body, _nameField, name);
    _addFieldToBody(body, _descriptionField, description);
    _addFieldToBody(body, _timePeriodField, timePeriod);
    _addFieldToBody(body, _estimatedYearField, estimatedYear);
    _addFieldToBody(body, _originLocationField, originLocation);
    _addFieldToBody(body, _statusField, status);

    return body;
  }

  /// 유물 상태 업데이트 (관리자만 가능)
  static Future<dynamic> updateArtifact({
    required String artifactId,
    String? name,
    String? description,
    String? timePeriod,
    String? estimatedYear,
    String? originLocation,
    String? status,
  }) async {
    try {
      final body = _buildUpdateBody(
        name: name,
        description: description,
        timePeriod: timePeriod,
        estimatedYear: estimatedYear,
        originLocation: originLocation,
        status: status,
      );

      return await ApiService.sendRequest(
        endpoint: "$_artifactsEndpoint$artifactId/$_updatePath",
        method: "PATCH",
        body: body,
      );
    } catch (e) {
      return _createErrorResponse(e);
    }
  }
}