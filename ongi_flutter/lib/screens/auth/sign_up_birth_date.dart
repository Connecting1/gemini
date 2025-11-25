import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_gender.dart';
import '../../styles/app_styles.dart';

class SignUpBirthDatePage extends StatefulWidget {
  const SignUpBirthDatePage({super.key});

  @override
  State<SignUpBirthDatePage> createState() => _SignUpBirthDatePageState();
}

class _SignUpBirthDatePageState extends State<SignUpBirthDatePage> {
  static const String _pageTitle = "회원가입";
  static const String _birthDateLabel = "생년월일";
  static const String _nextButtonText = "다음";
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;
  static const double _buttonRadius = 30;
  static const double _fieldRadius = 10;

  final TextEditingController _birthDateController = TextEditingController();
  bool _isBirthDateValid = false;

  /// 날짜를 YYYY-MM-DD 형식으로 포맷팅
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// 선택된 날짜로 상태 업데이트
  void _updateBirthDate(DateTime pickedDate) {
    final formattedDate = _formatDate(pickedDate);
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);

    setState(() {
      _birthDateController.text = formattedDate;
      _isBirthDateValid = true;
    });

    signUpProvider.setBirthDate(formattedDate);
  }

  /// 생년월일 선택 다이얼로그 표시
  Future<void> _selectBirthDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      _updateBirthDate(pickedDate);
    }
  }

  /// 다음 페이지로 이동
  void _goToGenderPage() {
    if (_isBirthDateValid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpGenderPage()),
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

  /// 생년월일 라벨
  Widget _buildBirthDateLabel() {
    return const Text(
      _birthDateLabel,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 생년월일 입력 필드
  Widget _buildBirthDateField() {
    return TextField(
      controller: _birthDateController,
      readOnly: true,
      onTap: _selectBirthDate,
      decoration: _inputDecoration(),
    );
  }

  /// 다음 버튼
  Widget _buildNextButton() {
    return Center(
      child: SizedBox(
        width: _buttonWidth,
        height: _buttonHeight,
        child: ElevatedButton(
          onPressed: _isBirthDateValid ? _goToGenderPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isBirthDateValid ? Colors.white : Colors.grey,
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
            _buildBirthDateLabel(),
            const SizedBox(height: 10),
            _buildBirthDateField(),
            const SizedBox(height: 30),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }
}