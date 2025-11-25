import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api/artifact_api.dart';

/// 유물 데이터와 상태 관리
class ArtifactProvider extends ChangeNotifier {
  static const String _defaultStatus = 'verified';
  static const String _noResponseError = '응답이 없습니다';
  static const String _invalidFormatError = '응답 형식이 올바르지 않습니다';
  static const String _unexpectedFormatError = '예상치 못한 응답 형식입니다';
  static const String _fetchArtifactsError = '유물을 불러오는 중 오류가 발생했습니다';
  static const String _fetchDetailError = '유물 상세 정보를 불러오는 중 오류가 발생했습니다';
  static const String _fetchFeedsError = '유물 관련 피드를 불러오는 중 오류가 발생했습니다';

  List<dynamic> _artifacts = [];
  List<dynamic> _filteredArtifacts = [];
  dynamic _currentArtifact;
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';

  List<dynamic> get artifacts => _artifacts;
  List<dynamic> get filteredArtifacts => _filteredArtifacts;
  dynamic get currentArtifact => _currentArtifact;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;

  /// 검색어 설정 및 결과 필터링
  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterArtifacts();
    notifyListeners();
  }

  /// 검색어로 유물 목록 필터링
  void _filterArtifacts() {
    if (_searchQuery.isEmpty) {
      _filteredArtifacts = List.from(_artifacts);
      return;
    }

    final lowercaseQuery = _searchQuery.toLowerCase();
    _filteredArtifacts = _artifacts.where((artifact) =>
        _matchesSearchQuery(artifact, lowercaseQuery)
    ).toList();
  }

  /// 검색어 일치 여부 확인
  bool _matchesSearchQuery(dynamic artifact, String query) {
    final searchFields = [
      artifact['name']?.toString().toLowerCase() ?? '',
      artifact['description']?.toString().toLowerCase() ?? '',
      artifact['time_period']?.toString().toLowerCase() ?? '',
      artifact['origin_location']?.toString().toLowerCase() ?? '',
    ];

    return searchFields.any((field) => field.contains(query));
  }

  /// API 응답 안전 처리
  void _processApiResult(dynamic result, Function(dynamic data) onSuccess) {
    if (result == null) {
      _error = _noResponseError;
      return;
    }

    final parsedResult = _parseJsonIfNeeded(result);
    if (parsedResult == null) return;

    if (_hasError(parsedResult)) return;

    onSuccess(parsedResult);
  }

  /// JSON 파싱 (필요한 경우)
  dynamic _parseJsonIfNeeded(dynamic result) {
    if (result is String) {
      try {
        return jsonDecode(result);
      } catch (e) {
        _error = '$_invalidFormatError: $e';
        return null;
      }
    }
    return result;
  }

  /// 응답 에러 확인
  bool _hasError(dynamic result) {
    if (result is Map && result.containsKey('error')) {
      _error = result['error'].toString();
      return true;
    }
    return false;
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = '';
    notifyListeners();
  }

  /// 전체 유물 목록 조회
  Future<void> fetchArtifacts({String status = _defaultStatus}) async {
    _setLoading(true);

    try {
      final result = await ArtifactApi.fetchArtifacts(status: status);

      _processApiResult(result, (data) {
        _artifacts = _extractArtifactsList(data);
        _filterArtifacts();
      });
    } catch (e) {
      _error = '$_fetchArtifactsError: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 응답에서 유물 목록 추출
  List<dynamic> _extractArtifactsList(dynamic data) {
    if (data is List) {
      return data;
    } else if (data is Map && data.containsKey('results') && data['results'] is List) {
      return data['results'];
    } else if (data is Map) {
      return [data];
    } else {
      _error = _unexpectedFormatError;
      return [];
    }
  }

  /// 유물 상세 정보 조회
  Future<void> fetchArtifactDetail(String artifactId) async {
    _setLoading(true);

    try {
      final result = await ArtifactApi.fetchArtifactDetail(artifactId);

      _processApiResult(result, (data) {
        _currentArtifact = data;
      });
    } catch (e) {
      _error = '$_fetchDetailError: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 유물 관련 피드 조회
  Future<List<dynamic>> fetchArtifactFeeds(String artifactId) async {
    _setLoading(true);

    try {
      final result = await ArtifactApi.fetchArtifactFeeds(artifactId);
      List<dynamic> feeds = [];

      _processApiResult(result, (data) {
        feeds = _extractFeedsList(data);
      });

      _setLoading(false);
      return feeds;
    } catch (e) {
      _error = '$_fetchFeedsError: $e';
      _setLoading(false);
      return [];
    }
  }

  /// 응답에서 피드 목록 추출
  List<dynamic> _extractFeedsList(dynamic data) {
    if (data is Map && data.containsKey('results') && data['results'] is List) {
      return data['results'];
    } else if (data is List) {
      return data;
    }
    return [];
  }

  /// 에러 상태 초기화
  void clearError() {
    _error = '';
    notifyListeners();
  }
}