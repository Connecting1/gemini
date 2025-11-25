import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/sign_up_provider.dart';
import '../../providers/user_provider.dart';
import 'package:ongi_flutter/services/api/user_api.dart';
import '../main/main_tab.dart';
import '../../styles/app_styles.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  static const String _userIdKey = "user_id";
  static const String _loginFailedMessage = "잘못된 이메일 또는 비밀번호입니다.";
  static const String _networkErrorMessage = "네트워크 오류: 로그인할 수 없습니다.";
  static const String _loginTitle = "로그인";
  static const String _emailLabel = "이메일";
  static const String _passwordLabel = "비밀번호";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    setState(() => _isLoading = loading);
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ $message")),
    );
  }

  /// 사용자 ID 저장
  Future<void> _saveUserId(Map<String, dynamic> response) async {
    if (response.containsKey("user_id")) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, response["user_id"]);
    }
  }

  /// 로그인 성공 처리
  Future<void> _handleLoginSuccess(Map<String, dynamic> response) async {
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await signUpProvider.setAuthToken(response["auth_token"]);
    await signUpProvider.setLoggedIn(true);
    await _saveUserId(response);
    await userProvider.loadUserInfo(forceRefresh: true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainTabPage()),
      );
    }
  }

  /// 로그인 실패 처리
  void _handleLoginFailure(Map<String, dynamic> response) {
    final errorMessage = response["error"] ?? _loginFailedMessage;
    _showErrorSnackBar("로그인 실패: $errorMessage");
  }

  /// 로그인 요청 처리
  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("이메일과 비밀번호를 입력해주세요.");
      return;
    }

    _setLoading(true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.reset();

      final response = await UserApi.loginUser(email, password);

      if (response.containsKey("auth_token")) {
        await _handleLoginSuccess(response);
      } else {
        _handleLoginFailure(response);
      }
    } catch (e) {
      _showErrorSnackBar(_networkErrorMessage);
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
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 이메일 입력 필드
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _emailLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  /// 비밀번호 입력 필드
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _passwordLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  /// 로그인 버튼
  Widget _buildLoginButton() {
    return Center(
      child: SizedBox(
        width: 100,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text(
            _loginTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      ),
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
          _loginTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmailField(),
            const SizedBox(height: 15),
            _buildPasswordField(),
            const SizedBox(height: 30),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }
}