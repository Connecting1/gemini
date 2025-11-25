import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_user_name.dart';
import '../../styles/app_styles.dart';

class SignUpGenderPage extends StatefulWidget {
  const SignUpGenderPage({super.key});

  @override
  State<SignUpGenderPage> createState() => _SignUpGenderPageState();
}

class _SignUpGenderPageState extends State<SignUpGenderPage> {
  static const String _pageTitle = "회원가입";
  static const String _genderLabel = "성별";
  static const String _nextButtonText = "다음";
  static const double _buttonWidth = 100;
  static const double _buttonHeight = 50;
  static const double _buttonRadius = 30;
  static const double _dropdownHeight = 60;
  static const double _dropdownRadius = 10;

  static const List<String> _genderOptions = [
    "남자", "여자", "정의되지 않음", "기타", "말하고 싶지 않음"
  ];

  String? _selectedGender;
  bool _isGenderSelected = false;

  /// 성별 선택 처리
  void _onGenderSelected(String? gender) {
    setState(() {
      _selectedGender = gender;
      _isGenderSelected = gender != null;
    });
  }

  /// 한글 성별을 영어로 변환
  String _convertGender(String koreanGender) {
    switch (koreanGender) {
      case "남자": return "male";
      case "여자": return "female";
      case "정의되지 않음": return "non-binary";
      case "기타": return "other";
      case "말하고 싶지 않음": return "prefer not to say";
      default: return "prefer not to say";
    }
  }

  /// Provider에 성별 저장
  void _saveGenderToProvider() {
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    signUpProvider.setGender(_convertGender(_selectedGender!));
  }

  /// 다음 페이지로 이동
  void _goToUserNamePage() {
    if (_isGenderSelected) {
      _saveGenderToProvider();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpUserNamePage()),
      );
    }
  }

  /// 성별 라벨
  Widget _buildGenderLabel() {
    return const Text(
      _genderLabel,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 성별 드롭다운 메뉴
  Widget _buildGenderDropdown() {
    return Container(
      height: _dropdownHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_dropdownRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGender,
            items: _genderOptions.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(
                  gender,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: _onGenderSelected,
            isExpanded: true,
          ),
        ),
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
          onPressed: _isGenderSelected ? _goToUserNamePage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isGenderSelected ? Colors.white : Colors.grey,
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
            _buildGenderLabel(),
            const SizedBox(height: 10),
            _buildGenderDropdown(),
            const SizedBox(height: 30),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }
}