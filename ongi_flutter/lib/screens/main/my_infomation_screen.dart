import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/api/api_service.dart';
import '../feed/feed_detail_screen.dart';

class MyInformationScreenPage extends StatefulWidget {
  @override
  State<MyInformationScreenPage> createState() => _MyInformationScreenPageState();
}

class _MyInformationScreenPageState extends State<MyInformationScreenPage> {
  static const String _headerImagePath = 'assets/images/eaves.png';
  static const String _defaultProfilePath = 'assets/images/default_profile.png';
  static const String _editInfoButtonText = '정보 수정';
  static const String _myFeedsTitle = '내 피드';
  static const String _rankPrefix = "랭크: ";
  static const String _feedCountPrefix = "내 피드 수: ";
  static const String _noFeedsMessage = '아직 게시한 피드가 없습니다';
  static const String _imageErrorText = '이미지 오류';
  static const String _noImageText = '이미지 없음';
  static const String _uploadErrorMessage = "이미지 업로드 중 오류가 발생했습니다.";

  static const int _imageQuality = 80;
  static const double _profileRadius = 60;
  static const double _cameraIconSize = 20;
  static const double _usernameFontSize = 24;
  static const double _rankFontSize = 16;
  static const double _feedCountFontSize = 18;
  static const double _myFeedsTitleFontSize = 18;
  static const double _noFeedsMessageFontSize = 16;
  static const double _errorImageIconSize = 50;

  static const int _gridCrossAxisCount = 3;
  static const double _gridSpacing = 2;
  static const double _gridAspectRatio = 1;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingFeeds = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 초기 데이터 로드
  void _initializeData() {
    _refreshUserInfo();
    _loadMyFeeds();
  }

  /// 사용자 정보 새로고침
  Future<void> _refreshUserInfo() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserInfo(forceRefresh: true);
    } catch (e) {
      // 에러 처리는 필요시 추가
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 내 피드 로드
  Future<void> _loadMyFeeds() async {
    setState(() => _isLoadingFeeds = true);

    try {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      await feedProvider.fetchMyFeeds();
    } catch (e) {
      // 에러 처리는 필요시 추가
    } finally {
      if (mounted) {
        setState(() => _isLoadingFeeds = false);
      }
    }
  }

  /// 데이터 새로고침
  Future<void> _refreshData() async {
    await _refreshUserInfo();
    await _loadMyFeeds();
  }

  /// 이미지 URL을 전체 URL로 변환
  String _getFullImageUrl(String url) {
    if (url.isEmpty) return '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    url = url.replaceAll(r'\\', '/');
    if (url.startsWith('/')) {
      url = url.substring(1);
    }

    return "${ApiService.baseUrl}/$url";
  }

  /// 갤러리에서 이미지 선택 및 업로드
  Future<void> _pickImage(UserProvider userProvider) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _imageQuality,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);

        final imageFile = File(pickedFile.path);
        await userProvider.updateProfileImage(imageFile);

        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(_uploadErrorMessage);
    }
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 피드 상세 페이지로 이동
  Future<void> _navigateToFeedDetail(String feedId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedDetailScreen(feedId: feedId),
      ),
    );

    if (result == true) {
      _loadMyFeeds();
    }
  }

  /// 헤더 이미지
  Widget _buildHeaderImage() {
    return Image.asset(
      _headerImagePath,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  /// 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 100.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 프로필 이미지
  Widget _buildProfileImage(UserProvider userProvider) {
    return GestureDetector(
      onTap: () => _pickImage(userProvider),
      child: Stack(
        children: [
          CircleAvatar(
            radius: _profileRadius,
            backgroundImage: userProvider.profileImage.isNotEmpty
                ? NetworkImage(_getFullImageUrl(userProvider.profileImage))
                : const AssetImage(_defaultProfilePath) as ImageProvider,
            child: userProvider.profileImage.isNotEmpty
                ? null
                : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
            ),
          ),
          _buildCameraIcon(),
        ],
      ),
    );
  }

  /// 카메라 아이콘
  Widget _buildCameraIcon() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Icon(
          Icons.camera_alt,
          size: _cameraIconSize,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// 사용자 정보 섹션
  Widget _buildUserInfoSection(UserProvider userProvider, FeedProvider feedProvider) {
    return Column(
      children: [
        const SizedBox(height: 30),
        _buildProfileImage(userProvider),
        const SizedBox(height: 16),
        _buildUsername(userProvider),
        const SizedBox(height: 8),
        _buildRank(userProvider),
        const SizedBox(height: 20),
        _buildFeedCount(feedProvider),
        const SizedBox(height: 24),
        _buildEditButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  /// 사용자명
  Widget _buildUsername(UserProvider userProvider) {
    return Text(
      userProvider.username,
      style: const TextStyle(
        fontSize: _usernameFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 랭크 정보
  Widget _buildRank(UserProvider userProvider) {
    return Text(
      "$_rankPrefix${userProvider.rank}",
      style: TextStyle(
        fontSize: _rankFontSize,
        color: Colors.grey.shade300,
      ),
    );
  }

  /// 피드 개수
  Widget _buildFeedCount(FeedProvider feedProvider) {
    return Text(
      "$_feedCountPrefix${feedProvider.myFeeds.length}",
      style: const TextStyle(
        fontSize: _feedCountFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 정보 수정 버튼
  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: () {
        // 정보 수정 화면으로 이동 (구현 필요)
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(_editInfoButtonText),
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade700, thickness: 1);
  }

  /// 내 피드 헤더
  Widget _buildMyFeedsHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.grid_on, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            _myFeedsTitle,
            style: TextStyle(
              fontSize: _myFeedsTitleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 피드 그리드
  Widget _buildFeedGrid(List<dynamic> feeds) {
    if (_isLoadingFeeds) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (feeds.isEmpty) {
      return _buildNoFeedsMessage();
    }

    return _buildFeedGridView(feeds);
  }

  /// 피드 없음 메시지
  Widget _buildNoFeedsMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              size: _errorImageIconSize,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _noFeedsMessage,
              style: TextStyle(
                fontSize: _noFeedsMessageFontSize,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 피드 그리드 뷰
  Widget _buildFeedGridView(List<dynamic> feeds) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: _gridSpacing),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        crossAxisSpacing: _gridSpacing,
        mainAxisSpacing: _gridSpacing,
        childAspectRatio: _gridAspectRatio,
      ),
      itemCount: feeds.length,
      itemBuilder: (context, index) => _buildFeedGridItem(feeds[index]),
    );
  }

  /// 피드 그리드 항목
  Widget _buildFeedGridItem(dynamic feed) {
    final imageUrl = _extractFeedImageUrl(feed);

    return GestureDetector(
      onTap: () => _onFeedTap(feed),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
        ),
        child: imageUrl.isNotEmpty
            ? _buildFeedImage(imageUrl)
            : _buildNoImagePlaceholder(),
      ),
    );
  }

  /// 피드 이미지 URL 추출
  String _extractFeedImageUrl(dynamic feed) {
    if (feed is! Map || !feed.containsKey('images')) return '';

    final images = feed['images'];
    if (images is! List || images.isEmpty) return '';

    final firstImage = images[0];
    if (firstImage is! Map || !firstImage.containsKey('image_url')) return '';

    return _getFullImageUrl(firstImage['image_url']);
  }

  /// 피드 탭 처리
  void _onFeedTap(dynamic feed) {
    if (feed is Map && feed.containsKey('id')) {
      _navigateToFeedDetail(feed['id'].toString());
    }
  }

  /// 피드 이미지
  Widget _buildFeedImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                _imageErrorText,
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 이미지 없음 플레이스홀더
  Widget _buildNoImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            _noImageText,
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// 에러 메시지
  Widget _buildErrorMessage(UserProvider userProvider, FeedProvider feedProvider) {
    final hasError = userProvider.error.isNotEmpty || feedProvider.error.isNotEmpty;
    if (!hasError) return const SizedBox.shrink();

    final errorMessage = userProvider.error.isNotEmpty
        ? userProvider.error
        : feedProvider.error;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        errorMessage,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
    );
  }

  /// 메인 컨텐츠
  Widget _buildMainContent(UserProvider userProvider, FeedProvider feedProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildUserInfoSection(userProvider, feedProvider),
        _buildDivider(),
        _buildMyFeedsHeader(),
        _buildFeedGrid(feedProvider.myFeeds),
        _buildErrorMessage(userProvider, feedProvider),
      ],
    );
  }

  /// 스크롤 가능한 컨텐츠
  Widget _buildScrollableContent(UserProvider userProvider, FeedProvider feedProvider) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _buildMainContent(userProvider, feedProvider),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final feedProvider = Provider.of<FeedProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeaderImage(),
          Expanded(
            child: SafeArea(
              child: _buildScrollableContent(userProvider, feedProvider),
            ),
          ),
        ],
      ),
    );
  }
}