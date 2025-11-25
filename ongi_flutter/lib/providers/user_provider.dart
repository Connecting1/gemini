import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ongi_flutter/services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api/api_service.dart';

/// 사용자 정보 및 인증 상태 관리
class UserProvider extends ChangeNotifier {
  static const String _authTokenKey = "auth_token";
  static const String _userIdKey = "user_id";
  static const String _isLoggedInKey = "is_logged_in";
  static const String _sampleToken = "sample_token_12345";

  static const String _defaultUsername = "Loading...";
  static const String _guestUsername = "Guest";
  static const String _defaultRank = "입문자";
  static const int _defaultRankNumber = 1;

  String _username = _defaultUsername;
  String _email = "";
  String _gender = "";
  String _phoneNumber = "";
  String _profileImage = "";
  String _userId = "";
  String _rank = _defaultRank;
  int _rankNumber = _defaultRankNumber;
  bool _isLoaded = false;
  String _error = "";

  String get username => _username;
  String get email => _email;
  String get gender => _gender;
  String get phoneNumber => _phoneNumber;
  String get profileImage => _profileImage;
  String get userId => _userId;
  String get rank => _rank;
  int get rankNumber => _rankNumber;
  bool get isLoaded => _isLoaded;
  String get error => _error;

  /// 등급 숫자를 텍스트로 변환
  String _getRankText(int rank) {
    switch (rank) {
      case 1: return '입문자';
      case 2: return '관찰자';
      case 3: return '탐험가';
      case 4: return '지킴이';
      case 5: return '고고학자';
      case 6: return '도굴꾼';
      default: return '입문자';
    }
  }

  /// 이미지 URL 형식화
  String _formatImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return "";

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    if (imageUrl.startsWith('file:///')) {
      return imageUrl;
    }

    String formattedUrl = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    return "${ApiService.baseUrl}$formattedUrl";
  }

  /// 캐시 방지 타임스탬프 추가
  String _addCacheTimestamp(String url) {
    if (url.isEmpty) return url;
    return "$url?t=${DateTime.now().millisecondsSinceEpoch}";
  }

  /// 인증 정보 유효성 검사
  bool _isValidAuth(String? authToken, String? userId) {
    return authToken != null &&
        authToken.isNotEmpty &&
        authToken != _sampleToken &&
        userId != null &&
        userId.isNotEmpty;
  }

  /// 인증 정보 초기화
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// 게스트 모드로 설정
  void _setGuestMode(String errorMessage) {
    _error = errorMessage;
    _username = _guestUsername;
    _isLoaded = true;
    notifyListeners();
  }

  /// 사용자 상태 초기화 (forceRefresh용)
  void _resetUserState() {
    _isLoaded = false;
    _username = _defaultUsername;
    _email = "";
    _gender = "";
    _phoneNumber = "";
    _profileImage = "";
    _rankNumber = _defaultRankNumber;
    _rank = _defaultRank;
  }

  /// 서버 응답으로 사용자 정보 업데이트
  Future<void> _updateUserFromServer(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();

    if (userInfo.containsKey("id")) {
      _userId = userInfo["id"]?.toString() ?? "";

      if (_userId != prefs.getString(_userIdKey)) {
        await prefs.setString(_userIdKey, _userId);
      }
    }

    _username = userInfo["username"] ?? _guestUsername;
    _email = userInfo["email"] ?? "";
    _gender = userInfo["gender"] ?? "";
    _phoneNumber = userInfo["phone_number"] ?? "";
    _rankNumber = userInfo["rank"] ?? _defaultRankNumber;
    _rank = _getRankText(_rankNumber);

    String originalImageUrl = userInfo["profile_image"] ?? "";
    _profileImage = _formatImageUrl(originalImageUrl);
    if (_profileImage.isNotEmpty) {
      _profileImage = _addCacheTimestamp(_profileImage);
    }
  }

  /// 인증 에러 처리
  Future<void> _handleAuthError(String error) async {
    if (error.contains("403") || error.contains("401") ||
        error.contains("authentication") || error.contains("token")) {
      _error = "인증이 만료되었습니다. 다시 로그인해 주세요.";
      await _clearAuthData();
    } else {
      _error = error;
    }
  }

  /// 인증 상태 확인 및 리셋
  Future<bool> checkAndResetAuth() async {
    final prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString(_authTokenKey);
    String? userId = prefs.getString(_userIdKey);

    if (!_isValidAuth(authToken, userId)) {
      await _clearAuthData();
      await reset();
      return false;
    }
    return true;
  }

  /// 사용자 정보 로드
  Future<void> loadUserInfo({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _resetUserState();
    }

    if (!forceRefresh && _isLoaded) {
      return;
    }

    _error = "";

    try {
      final prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString(_authTokenKey);
      _userId = prefs.getString(_userIdKey) ?? "";

      if (!_isValidAuth(authToken, _userId)) {
        _setGuestMode("인증 정보가 유효하지 않습니다. 다시 로그인해 주세요.");
        return;
      }

      Map<String, dynamic> userInfo = await UserApi.fetchUserInfo();

      if (userInfo.containsKey("error")) {
        await _handleAuthError(userInfo["error"].toString());
        _username = _guestUsername;
      } else {
        await _updateUserFromServer(userInfo);
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _error = "사용자 정보를 불러오는 중 오류가 발생했습니다: $e";
      _username = _guestUsername;
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// 사용자 정보 업데이트
  Future<void> updateUserInfo({
    String? username,
    String? email,
    String? gender,
    String? phoneNumber,
  }) async {
    if (_userId.isEmpty) {
      _error = "사용자 ID가 없어 업데이트할 수 없습니다";
      notifyListeners();
      return;
    }

    try {
      Map<String, dynamic> result = await UserApi.updateUserInfo(
        userId: _userId,
        username: username,
        email: email,
        gender: gender,
        phoneNumber: phoneNumber,
      );

      if (result.containsKey("error")) {
        await _handleAuthError(result["error"].toString());
        notifyListeners();
        return;
      }

      _username = username ?? _username;
      _email = email ?? _email;
      _gender = gender ?? _gender;
      _phoneNumber = phoneNumber ?? _phoneNumber;
      _error = "";

      notifyListeners();
    } catch (e) {
      _error = "사용자 정보 업데이트 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }

  /// 프로필 이미지 업데이트
  Future<void> updateProfileImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_userIdKey) ?? "";

    if (_userId.isEmpty) {
      _error = "사용자 ID가 없어 프로필 이미지를 변경할 수 없습니다.";
      notifyListeners();
      return;
    }

    try {
      Map<String, dynamic> result = await UserApi.updateProfileImage(
        userId: _userId,
        profileImage: imageFile,
      );

      if (result.containsKey("error")) {
        await _handleAuthError(result["error"].toString());
        notifyListeners();
        return;
      }

      String originalImageUrl = result["profile_image"] ?? "";
      _profileImage = _formatImageUrl(originalImageUrl);
      if (_profileImage.isNotEmpty) {
        _profileImage = _addCacheTimestamp(_profileImage);
      }

      _error = "";
      notifyListeners();
    } catch (e) {
      _error = "프로필 이미지 업데이트 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }

  /// 로그아웃 시 상태 초기화
  Future<void> reset() async {
    _username = _defaultUsername;
    _email = "";
    _gender = "";
    _phoneNumber = "";
    _profileImage = "";
    _userId = "";
    _rankNumber = _defaultRankNumber;
    _rank = _defaultRank;
    _isLoaded = false;
    _error = "";

    await _clearAuthData();
    notifyListeners();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = "";
    notifyListeners();
  }
}