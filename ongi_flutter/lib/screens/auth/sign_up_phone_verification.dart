import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/sign_up_provider.dart';
import '../../providers/user_provider.dart';
import 'package:ongi_flutter/services/api/user_api.dart';
import '../main/main_tab.dart';
import '../../styles/app_styles.dart';

class SignUpPhoneVerificationPage extends StatefulWidget {
  const SignUpPhoneVerificationPage({Key? key}) : super(key: key);

  @override
  State<SignUpPhoneVerificationPage> createState() => _SignUpPhoneVerificationPageState();
}

class _SignUpPhoneVerificationPageState extends State<SignUpPhoneVerificationPage> {
  static const String _pageTitle = "회원가입";
  static const String _phoneLabel = "전화번호";
  static const String _verificationCodeLabel = "인증번호";
  static const String _nextButtonText = "다음";
  static const String _codeSentMessage = "인증 코드가 전송되었습니다.";
  static const String _verificationCompleteMessage = "휴대폰 인증 완료!";
  static const String _verificationRequiredMessage = "휴대폰 인증을 완료해야 합니다.";
  static const String _signUpSuccessMessage = "회원가입 성공!";
  static const String _signUpFailedMessage = "회원가입 실패";
  static const String _authTokenKey = "auth_token";
  static const String _userIdKey = "user_id";
  static const String _isLoggedInKey = "is_logged_in";

  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;
  static const double _buttonRadius = 30;
  static const double _fieldRadius = 10;
  static const int _verificationCodeLength = 6;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  bool _isCodeSent = false;
  bool _isVerified = false;
  bool _isPhoneValid = false;
  bool _isLoading = false;

  /// 전화번호 변경 처리
  void _onPhoneChanged(String value) {
    setState(() {
      _isPhoneValid = value.isNotEmpty;
    });

    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    signUpProvider.setPhoneNumber(value);
  }

  /// 인증 코드 전송
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isCodeSent = true;
    });
    _showSnackBar(_codeSentMessage);
  }

  /// 인증 코드 변경 처리
  void _onCodeChanged(String value) {
    if (value.length == _verificationCodeLength) {
      _verifyCode(value);
    }
  }

  /// 인증 코드 검증
  Future<void> _verifyCode(String code) async {
    setState(() {
      _isVerified = true;
    });
    _showSnackBar(_verificationCompleteMessage);
  }

  /// 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    setState(() => _isLoading = loading);
  }

  /// SharedPreferences에 인증 데이터 저장
  Future<void> _saveAuthData(String? authToken, String? userId) async {
    final prefs = await SharedPreferences.getInstance();

    if (authToken != null && authToken.isNotEmpty) {
      await prefs.setString(_authTokenKey, authToken);
      await prefs.setBool(_isLoggedInKey, true);
    }

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }
  }

  /// 회원가입 응답에서 인증 토큰 처리
  Future<String?> _handleAuthToken(Map<String, dynamic> response, SignUpProvider signUpProvider) async {
    String? authToken = response[_authTokenKey];

    if (authToken != null && authToken.isNotEmpty) {
      await signUpProvider.setAuthToken(authToken);
      return authToken;
    }

    final loginResponse = await UserApi.loginUser(signUpProvider.email, signUpProvider.password!);
    if (loginResponse.containsKey(_authTokenKey)) {
      authToken = loginResponse[_authTokenKey];
      await signUpProvider.setAuthToken(authToken);
      return authToken;
    }

    return null;
  }

  /// 회원가입 응답에서 사용자 ID 추출
  String _extractUserId(Map<String, dynamic> response) {
    if (response.containsKey("id")) {
      return response["id"].toString();
    } else if (response.containsKey(_userIdKey)) {
      return response[_userIdKey].toString();
    }
    return "";
  }

  /// 회원가입 성공 처리
  Future<void> _handleSignUpSuccess(Map<String, dynamic> response) async {
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await signUpProvider.setLoggedIn(true);

    final authToken = await _handleAuthToken(response, signUpProvider);
    final userId = _extractUserId(response);

    await _saveAuthData(authToken, userId);

    await Future.delayed(const Duration(milliseconds: 500));
    await userProvider.loadUserInfo(forceRefresh: true);

    _showSnackBar(_signUpSuccessMessage);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainTabPage()),
      );
    }
  }

  /// 최종 회원가입 처리
  Future<void> _handleFinalSignUp() async {
    if (!_isVerified) {
      _showSnackBar(_verificationRequiredMessage);
      return;
    }

    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await userProvider.reset();
    _setLoading(true);

    try {
      final response = await UserApi.createUser(
        email: signUpProvider.email,
        password: signUpProvider.password,
        gender: signUpProvider.gender,
        username: signUpProvider.username,
        phoneNumber: signUpProvider.phoneNumber,
        provider: signUpProvider.provider,
      );

      if (response.containsKey("error")) {
        _showSnackBar("$_signUpFailedMessage: ${response["error"]}");
      } else {
        await _handleSignUpSuccess(response);
      }
    } catch (e) {
      _showSnackBar("회원가입 중 오류가 발생했습니다.");
    } finally {
      _setLoading(false);
    }
  }

  /// 입력 필드 데코레이션
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 전화번호 입력 섹션
  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _phoneLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          onChanged: _onPhoneChanged,
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 20),
        Center(child: _buildSendCodeButton()),
      ],
    );
  }

  /// 코드 전송 버튼
  Widget _buildSendCodeButton() {
    return SizedBox(
      width: _buttonWidth,
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: _isPhoneValid && !_isCodeSent ? _sendVerificationCode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPhoneValid && !_isCodeSent ? Colors.white : Colors.grey,
          disabledBackgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
        child: const Text(
          _nextButtonText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  /// 인증번호 입력 섹션
  Widget _buildVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          _verificationCodeLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _verificationCodeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: _verificationCodeLength,
          onChanged: _onCodeChanged,
          decoration: _inputDecoration().copyWith(counterText: ""),
        ),
      ],
    );
  }

  /// 최종 회원가입 버튼
  Widget _buildFinalSignUpButton() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: _buttonWidth,
            height: _buttonHeight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleFinalSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : Colors.white,
                disabledBackgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_buttonRadius),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                _nextButtonText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          _pageTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhoneSection(),
              if (_isCodeSent) _buildVerificationSection(),
              if (_isVerified) _buildFinalSignUpButton(),
            ],
          ),
        ),
      ),
    );
  }
}