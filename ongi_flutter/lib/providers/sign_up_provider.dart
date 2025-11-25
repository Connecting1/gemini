import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 회원가입 및 로그인 상태 관리
class SignUpProvider extends ChangeNotifier {
  static const String _authTokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  String _email = '';
  String? _password = '';
  String _birthDate = '';
  String _gender = '';
  String _username = '';
  String _phoneNumber = '';
  String _provider = '';
  String _authToken = '';
  bool _isLoggedIn = false;

  String get email => _email;
  String? get password => _password;
  String get birthDate => _birthDate;
  String get gender => _gender;
  String get username => _username;
  String get phoneNumber => _phoneNumber;
  String get provider => _provider;
  String get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;

  /// 이메일 설정
  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  /// 비밀번호 설정
  void setPassword(String? password) {
    _password = password;
    notifyListeners();
  }

  /// 생년월일 설정
  void setBirthDate(String birthDate) {
    _birthDate = birthDate;
    notifyListeners();
  }

  /// 성별 설정
  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  /// 사용자명 설정
  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  /// 전화번호 설정
  void setPhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    notifyListeners();
  }

  /// 로그인 제공자 설정
  void setProvider(String provider) {
    _provider = provider;
    notifyListeners();
  }

  /// 인증 토큰 설정 및 저장
  Future<void> setAuthToken(String? token) async {
    _authToken = token ?? '';
    _isLoggedIn = true;
    notifyListeners();

    await _saveAuthData(token ?? '', true);
  }

  /// 저장된 인증 토큰 로드
  Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_authTokenKey) ?? '';
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    notifyListeners();
  }

  /// 로그인 상태 설정
  Future<void> setLoggedIn(bool status) async {
    _isLoggedIn = status;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, status);
  }

  /// 로그아웃 처리
  Future<void> logout() async {
    await _clearAuthData();
    _authToken = '';
    _isLoggedIn = false;
    notifyListeners();
  }

  /// 인증 데이터 저장
  Future<void> _saveAuthData(String token, bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  /// 인증 데이터 삭제
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_isLoggedInKey);
  }
}