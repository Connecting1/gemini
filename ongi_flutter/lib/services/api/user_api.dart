import 'dart:io';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserApi {
  static const String _usersEndpoint = "/api/users/";
  static const String _createPath = "create/";
  static const String _loginPath = "login/";
  static const String _updatePath = "update/";
  static const String _updateProfileImagePath = "update-profile-image/";

  static const String _emailField = "email";
  static const String _passwordField = "password";
  static const String _genderField = "gender";
  static const String _usernameField = "username";
  static const String _phoneNumberField = "phone_number";
  static const String _providerField = "provider";
  static const String _profileImageField = "profile_image";
  static const String _authTokenField = "auth_token";
  static const String _idField = "id";
  static const String _userIdField = "user_id";
  static const String _rankField = "rank";
  static const String _statusField = "status";
  static const String _errorField = "error";
  static const String _isLoggedInField = "is_logged_in";

  static const String _createUserError = "회원가입 요청 중 오류가 발생했습니다";
  static const String _loginUserError = "로그인 요청 중 오류가 발생했습니다";
  static const String _fetchUserInfoError = "유저 정보 요청 중 오류가 발생했습니다";
  static const String _invalidUserIdError = "유효한 사용자 ID가 없습니다";
  static const String _reLoginRequiredError = "유효한 사용자 ID가 없습니다. 다시 로그인해 주세요.";

  static const int _unauthorizedCode = 401;
  static const int _forbiddenCode = 403;
  static const int _defaultRank = 1;

  /// 에러 응답 생성
  static Map<String, dynamic> _createErrorResponse(String message, [dynamic error]) {
    final errorMessage = error != null ? "$message: ${error.toString()}" : message;
    return {_errorField: errorMessage};
  }

  /// SharedPreferences 인스턴스 가져오기
  static Future<SharedPreferences> _getPreferences() async {
    return await SharedPreferences.getInstance();
  }

  /// 인증 토큰 저장
  static Future<void> _saveAuthToken(String authToken) async {
    final prefs = await _getPreferences();
    await prefs.setString(_authTokenField, authToken);
    await prefs.setBool(_isLoggedInField, true);
  }

  /// 사용자 ID 저장
  static Future<void> _saveUserId(String userId) async {
    final prefs = await _getPreferences();
    await prefs.setString(_userIdField, userId);
  }

  /// 응답에서 사용자 ID 추출
  static String? _extractUserId(Map<String, dynamic> response) {
    if (response.containsKey(_idField) && response[_idField] != null) {
      return response[_idField].toString();
    } else if (response.containsKey(_userIdField) && response[_userIdField] != null) {
      return response[_userIdField].toString();
    }
    return null;
  }

  /// 회원가입 응답 처리
  static Future<void> _handleSignUpResponse(Map<String, dynamic> response) async {
    // 인증 토큰 저장
    if (response.containsKey(_authTokenField) && response[_authTokenField] != null) {
      await _saveAuthToken(response[_authTokenField]);
    }

    // 사용자 ID 저장
    final userId = _extractUserId(response);
    if (userId != null) {
      await _saveUserId(userId);
    }
  }

  /// 로그인 응답 처리
  static Future<void> _handleLoginResponse(Map<String, dynamic> response) async {
    if (response.containsKey(_authTokenField)) {
      await _saveAuthToken(response[_authTokenField]);
    }
  }

  /// 인증 에러 확인
  static bool _isAuthError(Map<String, dynamic> response) {
    if (!response.containsKey(_statusField)) return false;

    final status = response[_statusField];
    return status == _unauthorizedCode || status == _forbiddenCode;
  }

  /// 로그아웃 처리
  static Future<void> _handleLogout() async {
    final prefs = await _getPreferences();
    await prefs.remove(_authTokenField);
    await prefs.remove(_userIdField);
    await prefs.setBool(_isLoggedInField, false);
  }

  /// rank 필드 파싱
  static void _parseRankField(Map<String, dynamic> response) {
    if (!response.containsKey(_rankField)) return;

    try {
      response[_rankField] = int.parse(response[_rankField].toString());
    } catch (e) {
      response[_rankField] = _defaultRank;
    }
  }

  /// 사용자 정보 응답 처리
  static Future<Map<String, dynamic>> _handleUserInfoResponse(Map<String, dynamic> response) async {
    if (response.containsKey(_errorField)) {
      if (_isAuthError(response)) {
        await _handleLogout();
      }
      return response;
    }

    _parseRankField(response);
    return response;
  }

  /// 회원가입
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String? password,
    required String gender,
    required String username,
    required String phoneNumber,
    required String provider,
    String? profileImage,
  }) async {
    try {
      final response = await ApiService.sendRequest(
        endpoint: "$_usersEndpoint$_createPath",
        method: "POST",
        body: {
          _emailField: email,
          _passwordField: password,
          _genderField: gender.toLowerCase(),
          _usernameField: username,
          _phoneNumberField: phoneNumber,
          _providerField: provider,
          _profileImageField: profileImage,
        },
      );

      if (response is Map<String, dynamic>) {
        await _handleSignUpResponse(response);
        return response;
      }

      return response;
    } catch (e) {
      return _createErrorResponse(_createUserError, e);
    }
  }

  /// 로그인
  static Future<Map<String, dynamic>> loginUser(String email, String? password) async {
    try {
      final response = await ApiService.sendRequest(
        endpoint: "$_usersEndpoint$_loginPath",
        method: "POST",
        body: {
          _emailField: email,
          _passwordField: password,
        },
      );

      if (response is Map<String, dynamic>) {
        await _handleLoginResponse(response);
        return response;
      }

      return response;
    } catch (e) {
      return _createErrorResponse(_loginUserError, e);
    }
  }

  /// 유저 정보 가져오기
  static Future<Map<String, dynamic>> fetchUserInfo() async {
    try {
      final userId = await ApiService.getUserId();

      if (userId == null || userId.isEmpty) {
        return _createErrorResponse(_reLoginRequiredError);
      }

      final response = await ApiService.sendRequest(
        endpoint: "$_usersEndpoint$userId/",
      );

      if (response is Map<String, dynamic>) {
        return await _handleUserInfoResponse(response);
      }

      return response;
    } catch (e) {
      return _createErrorResponse(_fetchUserInfoError, e);
    }
  }

  /// 업데이트할 필드들을 body에 추가
  static void _addFieldToBody(Map<String, dynamic> body, String key, String? value) {
    if (value != null) {
      body[key] = value;
    }
  }

  /// 유저 정보 업데이트용 body 구성
  static Map<String, dynamic> _buildUpdateBody({
    String? username,
    String? email,
    String? gender,
    String? phoneNumber,
  }) {
    final body = <String, dynamic>{};
    _addFieldToBody(body, _usernameField, username);
    _addFieldToBody(body, _emailField, email);
    _addFieldToBody(body, _genderField, gender);
    _addFieldToBody(body, _phoneNumberField, phoneNumber);
    return body;
  }

  /// 유저 정보 수정
  static Future<Map<String, dynamic>> updateUserInfo({
    required String userId,
    String? username,
    String? email,
    String? gender,
    String? phoneNumber,
    File? profileImage,
  }) async {
    if (userId.isEmpty) {
      return _createErrorResponse(_invalidUserIdError);
    }

    final body = _buildUpdateBody(
      username: username,
      email: email,
      gender: gender,
      phoneNumber: phoneNumber,
    );

    return await ApiService.sendRequest(
      endpoint: "$_usersEndpoint$userId/$_updatePath",
      method: "PATCH",
      body: body,
      file: profileImage,
    );
  }

  /// 프로필 이미지만 업데이트
  static Future<Map<String, dynamic>> updateProfileImage({
    required String userId,
    required File profileImage,
  }) async {
    if (userId.isEmpty) {
      return _createErrorResponse(_invalidUserIdError);
    }

    return await ApiService.sendRequest(
      endpoint: "$_usersEndpoint$userId/$_updateProfileImagePath",
      method: "PATCH",
      file: profileImage,
    );
  }
}