import 'package:flutter/material.dart';
import 'sign_up_password.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import '../../styles/app_styles.dart';

class SignUpEmailPage extends StatefulWidget {
  const SignUpEmailPage({super.key});

  @override
  State<SignUpEmailPage> createState() => _SignUpEmailPageState();
}

class _SignUpEmailPageState extends State<SignUpEmailPage> {
  static const String _pageTitle = "회원가입";
  static const String _emailLabel = "이메일";
  static const String _nextButtonText = "다음";
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;
  static const double _buttonRadius = 30;
  static const double _fieldRadius = 10;

  static const String _emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";

  final TextEditingController _emailController = TextEditingController();
  bool _isEmailValid = false;

  /// 이메일 유효성 검사
  void _validateEmail(String email) {
    final emailRegex = RegExp(_emailPattern);
    setState(() {
      _isEmailValid = emailRegex.hasMatch(email);
    });
  }

  /// Provider에 이메일 저장
  void _saveEmailToProvider() {
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    signUpProvider.setEmail(_emailController.text);
  }

  /// 다음 페이지로 이동
  void _goToPasswordPage() {
    if (_isEmailValid) {
      _saveEmailToProvider();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignUpPasswordPage()),
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
    );
  }

  /// 이메일 라벨
  Widget _buildEmailLabel() {
    return const Text(
      _emailLabel,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 이메일 입력 필드
  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      onChanged: _validateEmail,
      decoration: _inputDecoration(),
      keyboardType: TextInputType.emailAddress,
    );
  }

  /// 다음 버튼
  Widget _buildNextButton() {
    return Center(
      child: SizedBox(
        width: _buttonWidth,
        height: _buttonHeight,
        child: ElevatedButton(
          onPressed: _isEmailValid ? _goToPasswordPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEmailValid ? Colors.white : Colors.grey,
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
            _buildEmailLabel(),
            const SizedBox(height: 10),
            _buildEmailField(),
            const SizedBox(height: 30),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}