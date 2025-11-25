import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_birth_date.dart';
import '../../styles/app_styles.dart';

class SignUpPasswordPage extends StatefulWidget {
  const SignUpPasswordPage({super.key});

  @override
  State<SignUpPasswordPage> createState() => _SignUpPasswordPageState();
}

class _SignUpPasswordPageState extends State<SignUpPasswordPage> {
  static const String _pageTitle = "회원가입";
  static const String _passwordLabel = "비밀번호";
  static const String _nextButtonText = "다음";
  static const String _passwordHint = "• 10자 이상 영문 대 소문자, 숫자를 사용하세요";
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;
  static const double _buttonRadius = 30;
  static const double _fieldRadius = 10;

  static const String _passwordPattern = r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{10,}$";

  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordValid = false;
  bool _obscurePassword = true;

  /// 비밀번호 유효성 검사
  void _validatePassword(String password) {
    final passwordRegex = RegExp(_passwordPattern);
    setState(() {
      _isPasswordValid = passwordRegex.hasMatch(password);
    });
  }

  /// 비밀번호 표시/숨김 토글
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  /// Provider에 비밀번호 저장
  void _savePasswordToProvider() {
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    signUpProvider.setPassword(_passwordController.text);
  }

  /// 다음 페이지로 이동
  void _goToBirthDatePage() {
    if (_isPasswordValid) {
      _savePasswordToProvider();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpBirthDatePage()),
      );
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
      contentPadding: const EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 20.0,
      ),
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: _togglePasswordVisibility,
      ),
    );
  }

  /// 비밀번호 라벨
  Widget _buildPasswordLabel() {
    return const Text(
      _passwordLabel,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 비밀번호 입력 필드
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      onChanged: _validatePassword,
      obscureText: _obscurePassword,
      decoration: _inputDecoration(),
      keyboardType: TextInputType.text,
    );
  }

  /// 비밀번호 힌트 텍스트
  Widget _buildPasswordHint() {
    return const Text(
      _passwordHint,
      style: TextStyle(
        fontSize: 10,
        color: Colors.white,
      ),
    );
  }

  /// 다음 버튼
  Widget _buildNextButton() {
    return Center(
      child: SizedBox(
        width: _buttonWidth,
        height: _buttonHeight,
        child: ElevatedButton(
          onPressed: _isPasswordValid ? _goToBirthDatePage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPasswordValid ? Colors.white : Colors.grey,
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
          _pageTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 56,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasswordLabel(),
            const SizedBox(height: 10),
            _buildPasswordField(),
            const SizedBox(height: 5),
            _buildPasswordHint(),
            const SizedBox(height: 30),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}