import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.black;
  static const Color secondary = Color(0xFFFFC107);
  static const Color background = Colors.black;

  static const double _colorStrengthStep = 0.1;
  static const double _baseStrength = 0.05;
  static const double _neutralPoint = 0.5;
  static const int _strengthCount = 10;
  static const int _strengthMultiplier = 1000;

  /// MaterialColor 변환
  static MaterialColor get primarySwatch => _createMaterialColor(primary);

  /// Color를 MaterialColor로 변환
  static MaterialColor _createMaterialColor(Color color) {
    final swatch = _generateColorSwatch(color);
    return MaterialColor(color.value, swatch);
  }

  /// 색상 강도 목록 생성
  static List<double> _generateStrengths() {
    final strengths = <double>[_baseStrength];

    for (int i = 1; i < _strengthCount; i++) {
      strengths.add(_colorStrengthStep * i);
    }

    return strengths;
  }

  /// 색상 변형 계산
  static Color _calculateColorVariant(Color color, double strength) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;
    final ds = _neutralPoint - strength;

    return Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  /// 색상 스와치 생성
  static Map<int, Color> _generateColorSwatch(Color color) {
    final strengths = _generateStrengths();
    final swatch = <int, Color>{};

    for (var strength in strengths) {
      final key = (strength * _strengthMultiplier).round();
      swatch[key] = _calculateColorVariant(color, strength);
    }

    return swatch;
  }
}

class ButtonStyles {
  static const double _defaultHorizontalPadding = 20;
  static const double _defaultVerticalPadding = 10;
  static const double _defaultBorderRadius = 10;
  static const double _defaultButtonHeight = 50;
  static const double _screenWidthRatio = 0.85;

  /// 로그인 버튼 스타일
  static ButtonStyle loginButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(
        horizontal: _defaultHorizontalPadding,
        vertical: _defaultVerticalPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_defaultBorderRadius),
      ),
      shadowColor: Colors.transparent,
      fixedSize: Size(
        MediaQuery.of(context).size.width * _screenWidthRatio,
        _defaultButtonHeight,
      ),
    );
  }

  /// 기본 버튼 스타일 (재사용 가능)
  static ButtonStyle baseButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
    EdgeInsets? padding,
    Size? fixedSize,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: _defaultHorizontalPadding,
        vertical: _defaultVerticalPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? _defaultBorderRadius),
      ),
      shadowColor: Colors.transparent,
      fixedSize: fixedSize,
    );
  }

  /// 화면 너비에 맞는 버튼 크기 계산
  static Size getResponsiveButtonSize(BuildContext context, {
    double widthRatio = _screenWidthRatio,
    double height = _defaultButtonHeight,
  }) {
    return Size(
      MediaQuery.of(context).size.width * widthRatio,
      height,
    );
  }
}