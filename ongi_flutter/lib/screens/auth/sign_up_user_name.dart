import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_phone_verification.dart';
import '../../styles/app_styles.dart';

class SignUpUserNamePage extends StatefulWidget {
  const SignUpUserNamePage({super.key});

  @override
  State<SignUpUserNamePage> createState() => _SignUpUserNamePageState();
}

class _SignUpUserNamePageState extends State<SignUpUserNamePage> {
  static const String _pageTitle = "회원가입";
  static const String _nameLabel = "이름";
  static const String _nextButtonText = "다음";
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;
  static const double _buttonRadius = 30;
  static const double _fieldRadius = 10;

  final TextEditingController _nameController = TextEditingController();
  bool _isNameValid = false;

  /// 이름 유효성 검사
  void _validateName(String name) {
    setState(() {
      _isNameValid = name.isNotEmpty;
    });
  }

  /// Provider에 사용자명 저장
  void _saveNameToProvider() {
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    signUpProvider.setUsername(_nameController.text);
  }

  /// 다음 페이지로 이동
  void _goToPhoneVerificationPage() {
    if (_isNameValid) {
      _saveNameToProvider();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpPhoneVerificationPage()),
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

  /// 이름 라벨
  Widget _buildNameLabel() {
    return const Text(
      _nameLabel,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 이름 입력 필드
  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      onChanged: _validateName,
      decoration: _inputDecoration(),
      keyboardType: TextInputType.text,
    );
  }

  /// 다음 버튼
  Widget _buildNextButton() {
    return Center(
      child: SizedBox(
        width: _buttonWidth,
        height: _buttonHeight,
        child: ElevatedButton(
          onPressed: _isNameValid ? _goToPhoneVerificationPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isNameValid ? Colors.white : Colors.grey,
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
            _buildNameLabel(),
            const SizedBox(height: 10),
            _buildNameField(),
            const SizedBox(height: 35),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}