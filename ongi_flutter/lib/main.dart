import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/sign_up_provider.dart';
import 'providers/user_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/artifact_provider.dart';
import 'providers/model3d_provider.dart';
import 'screens/auth/sign_up_start.dart';
import 'screens/main/main_tab.dart';
import '../../styles/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await _checkLoginStatus();
  runApp(OnGiApp(isLoggedIn: isLoggedIn));
}

/// 로그인 상태 확인
Future<bool> _checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_logged_in') ?? false;
}

class OnGiApp extends StatelessWidget {
  final bool isLoggedIn;

  const OnGiApp({Key? key, required this.isLoggedIn}) : super(key: key);

  // 상수 정의
  static const String _loginStatusKey = 'is_logged_in';
  static const String _startupLoginMessage = '앱 시작 시 로그인된 상태 감지: 사용자 정보 로드 예약';
  static const String _startupSuccessMessage = '앱 시작 시 사용자 정보 로드 완료';
  static const String _startupErrorMessage = '앱 시작 시 사용자 정보 로드 실패';
  static const String _startupNotLoggedMessage = '앱 시작 시 로그인되지 않은 상태 감지';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: MaterialApp(
        theme: _buildTheme(),
        home: _buildHomePage(),
      ),
    );
  }

  /// Provider 목록 생성
  List<ChangeNotifierProvider> _buildProviders() {
    return [
      _buildSignUpProvider(),
      _buildUserProvider(),
      _buildFeedProvider(),
      _buildArtifactProvider(),
      _buildModel3DProvider(),
    ];
  }

  /// SignUpProvider 생성
  ChangeNotifierProvider<SignUpProvider> _buildSignUpProvider() {
    return ChangeNotifierProvider(
      create: (_) {
        final signUpProvider = SignUpProvider();
        signUpProvider.loadAuthToken();
        return signUpProvider;
      },
    );
  }

  /// UserProvider 생성
  ChangeNotifierProvider<UserProvider> _buildUserProvider() {
    return ChangeNotifierProvider(
      create: (_) {
        final userProvider = UserProvider();

        if (isLoggedIn) {
          _loadUserInfoOnStartup(userProvider);
        } else {
          _logNotLoggedInStatus();
        }

        return userProvider;
      },
    );
  }

  /// FeedProvider 생성
  ChangeNotifierProvider<FeedProvider> _buildFeedProvider() {
    return ChangeNotifierProvider(
      create: (_) => FeedProvider(),
    );
  }

  /// ArtifactProvider 생성
  ChangeNotifierProvider<ArtifactProvider> _buildArtifactProvider() {
    return ChangeNotifierProvider(
      create: (_) => ArtifactProvider(),
    );
  }

  /// Model3DProvider 생성
  ChangeNotifierProvider<Model3DProvider> _buildModel3DProvider() {
    return ChangeNotifierProvider(
      create: (_) => Model3DProvider(),
    );
  }

  /// 앱 시작 시 사용자 정보 로드
  void _loadUserInfoOnStartup(UserProvider userProvider) {
    print(_startupLoginMessage);

    // UI 렌더링 후 사용자 정보 로드
    Future.microtask(() async {
      try {
        await userProvider.loadUserInfo(forceRefresh: true);
        print(_startupSuccessMessage);
      } catch (e) {
        print('$_startupErrorMessage: $e');
      }
    });
  }

  /// 로그인되지 않은 상태 로그
  void _logNotLoggedInStatus() {
    print(_startupNotLoggedMessage);
  }

  /// 앱 테마 생성
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: AppColors.primarySwatch,
      colorScheme: _buildColorScheme(),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: _buildAppBarTheme(),
      useMaterial3: true,
    );
  }

  /// 컬러 스킴 생성
  ColorScheme _buildColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primarySwatch,
      brightness: Brightness.light,
    );
  }

  /// AppBar 테마 생성
  AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: Colors.white,
    );
  }

  /// 홈 페이지 결정
  Widget _buildHomePage() {
    return isLoggedIn ? MainTabPage() : SignUpStartPage();
  }
}