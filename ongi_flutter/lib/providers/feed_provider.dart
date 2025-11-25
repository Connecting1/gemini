import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api/feed_api.dart';

/// 피드 데이터와 상태 관리
class FeedProvider extends ChangeNotifier {
  static const String _noResponseError = '응답이 없습니다';
  static const String _invalidFormatError = '응답 형식이 올바르지 않습니다';
  static const String _unexpectedFormatError = '예상치 못한 응답 형식입니다';
  static const String _fetchFeedsError = '피드를 불러오는 중 오류가 발생했습니다';
  static const String _fetchMyFeedsError = '내 피드를 불러오는 중 오류가 발생했습니다';
  static const String _fetchDetailError = '피드 상세 정보를 불러오는 중 오류가 발생했습니다';
  static const String _createFeedError = '피드 생성 중 오류가 발생했습니다';
  static const String _updateFeedError = '피드 업데이트 중 오류가 발생했습니다';
  static const String _deleteFeedError = '피드 삭제 중 오류가 발생했습니다';

  List<dynamic> _feeds = [];
  List<dynamic> _myFeeds = [];
  dynamic _currentFeed;
  bool _isLoading = false;
  String _error = '';

  List<dynamic> get feeds => _feeds;
  List<dynamic> get myFeeds => _myFeeds;
  dynamic get currentFeed => _currentFeed;
  bool get isLoading => _isLoading;
  String get error => _error;

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

  /// 응답에서 피드 목록 추출
  List<dynamic> _extractFeedsList(dynamic data) {
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

  /// 피드 목록 조회 (공통 로직)
  Future<void> _fetchFeedsList(Future<dynamic> Function() apiCall, Function(List<dynamic>) onSuccess, String errorMessage) async {
    _setLoading(true);

    try {
      final result = await apiCall();

      _processApiResult(result, (data) {
        final feeds = _extractFeedsList(data);
        onSuccess(feeds);
      });
    } catch (e) {
      _error = '$errorMessage: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 전체 피드 목록 조회
  Future<void> fetchFeeds() async {
    await _fetchFeedsList(
      FeedApi.fetchFeeds,
          (feeds) => _feeds = feeds,
      _fetchFeedsError,
    );
  }

  /// 내 피드 목록 조회
  Future<void> fetchMyFeeds() async {
    await _fetchFeedsList(
      FeedApi.fetchMyFeeds,
          (feeds) => _myFeeds = feeds,
      _fetchMyFeedsError,
    );
  }

  /// 피드 상세 정보 조회
  Future<void> fetchFeedDetail(String feedId) async {
    _setLoading(true);

    try {
      final result = await FeedApi.fetchFeedDetail(feedId);

      _processApiResult(result, (data) {
        _currentFeed = data;
      });
    } catch (e) {
      _error = '$_fetchDetailError: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 피드 생성
  Future<bool> createFeed({
    required String artifactName,
    required List<File> images,
    Function(double progress)? onProgress,
  }) async {
    _setLoading(true);

    try {
      final result = await FeedApi.createFeed(
        artifactName: artifactName,
        images: images,
        onProgress: onProgress,
      );

      bool success = false;

      _processApiResult(result, (data) {
        _currentFeed = data;
        success = true;
      });

      if (success) {
        await Future.delayed(Duration(milliseconds: 500));
        await fetchMyFeeds();
        return true;
      }

      return false;
    } catch (e) {
      _error = '$_createFeedError: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 피드 업데이트
  Future<bool> updateFeed({
    required String feedId,
    String? artifactName,
    String? status,
  }) async {
    _setLoading(true);

    try {
      final result = await FeedApi.updateFeed(
        feedId: feedId,
        artifactName: artifactName,
        status: status,
      );

      bool success = false;

      _processApiResult(result, (data) {
        _updateCurrentFeedIfMatches(feedId, data);
        success = true;
      });

      if (success) {
        await _refreshAllFeeds();
        return true;
      }

      return false;
    } catch (e) {
      _error = '$_updateFeedError: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 피드 삭제
  Future<bool> deleteFeed(String feedId) async {
    _setLoading(true);

    try {
      final result = await FeedApi.deleteFeed(feedId);

      bool success = false;

      _processApiResult(result, (data) {
        success = true;
      });

      if (success) {
        _removeFeedFromLists(feedId);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = '$_deleteFeedError: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 현재 피드 업데이트 (일치하는 경우)
  void _updateCurrentFeedIfMatches(String feedId, dynamic newData) {
    if (_currentFeed != null && _getIdFromFeed(_currentFeed) == feedId) {
      _currentFeed = newData;
    }
  }

  /// 모든 피드 목록 새로고침
  Future<void> _refreshAllFeeds() async {
    await fetchFeeds();
    await fetchMyFeeds();
  }

  /// 목록에서 피드 제거
  void _removeFeedFromLists(String feedId) {
    if (_currentFeed != null && _getIdFromFeed(_currentFeed) == feedId) {
      _currentFeed = null;
    }

    _feeds = _removeItemById(_feeds, feedId);
    _myFeeds = _removeItemById(_myFeeds, feedId);
  }

  /// 피드에서 ID 추출
  String? _getIdFromFeed(dynamic feed) {
    if (feed is Map && feed.containsKey('id')) {
      return feed['id'].toString();
    }
    return null;
  }

  /// ID로 항목 제거
  List<dynamic> _removeItemById(List<dynamic> items, String id) {
    return items.where((item) {
      String? itemId = _getIdFromFeed(item);
      return itemId != id;
    }).toList();
  }

  /// 에러 상태 초기화
  void clearError() {
    _error = '';
    notifyListeners();
  }
}