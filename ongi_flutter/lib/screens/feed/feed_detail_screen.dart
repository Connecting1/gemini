import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api/api_service.dart';

class FeedDetailScreen extends StatefulWidget {
  final String feedId;

  const FeedDetailScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  static const String _headerImagePath = 'assets/images/eaves.png';
  static const String _defaultProfilePath = 'assets/images/default_profile.png';
  static const String _loadErrorMessage = "피드 정보를 불러오는 중 오류가 발생했습니다.";
  static const String _noFeedMessage = "피드 정보를 불러올 수 없습니다.";
  static const String _imageLoadErrorMessage = '이미지를 불러올 수 없습니다';
  static const String _editNotImplementedMessage = "피드 수정 기능은 아직 구현되지 않았습니다.";
  static const String _deleteConfirmMessage = '이 피드를 정말 삭제하시겠습니까?';
  static const String _deleteSuccessMessage = "피드가 삭제되었습니다.";
  static const String _deleteFailedMessage = "피드 삭제 실패";
  static const String _deleteErrorMessage = "피드 삭제 중 오류가 발생했습니다";

  static const String _deleteTitle = '피드 삭제';
  static const String _cancelText = '취소';
  static const String _deleteText = '삭제';
  static const String _editText = '수정';
  static const String _userText = "사용자";
  static const String _artifactNamePrefix = "유물명: ";
  static const String _justNowText = "방금 전";

  static const double _profileRadius = 24;
  static const double _maxImageHeight = 0.6;
  static const int _daysThreshold = 7;

  bool _isLoading = true;
  PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFeedDetail();
  }

  /// 피드 상세 정보 로드
  Future<void> _loadFeedDetail() async {
    setState(() => _isLoading = true);

    try {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      await feedProvider.fetchFeedDetail(widget.feedId);
    } catch (e) {
      _showSnackBar(_loadErrorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  /// 날짜 포맷팅
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > _daysThreshold) {
        return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
      } else if (difference.inDays > 0) {
        return "${difference.inDays}일 전";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}시간 전";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}분 전";
      } else {
        return _justNowText;
      }
    } catch (e) {
      return dateString;
    }
  }

  /// 피드 수정 처리
  void _editFeed(dynamic feed) {
    _showSnackBar(_editNotImplementedMessage);
  }

  /// 피드 삭제 확인 다이얼로그 표시
  Future<void> _showDeleteConfirmDialog(String feedId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: const Text(_deleteTitle, style: TextStyle(color: Colors.white)),
          content: const Text(_deleteConfirmMessage, style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              child: const Text(_cancelText, style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(_deleteText, style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFeed(feedId);
              },
            ),
          ],
        );
      },
    );
  }

  /// 피드 삭제 처리
  Future<void> _deleteFeed(String feedId) async {
    try {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final result = await feedProvider.deleteFeed(feedId);

      if (result) {
        _showSnackBar(_deleteSuccessMessage);
        Navigator.pop(context, true);
      } else {
        _showSnackBar("$_deleteFailedMessage: ${feedProvider.error}");
      }
    } catch (e) {
      _showSnackBar("$_deleteErrorMessage: $e");
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
    return const Center(child: CircularProgressIndicator());
  }

  /// 피드 없음 메시지
  Widget _buildNoFeedMessage() {
    return const Center(child: Text(_noFeedMessage));
  }

  /// 사용자 정보 섹션
  Widget _buildUserInfoSection(dynamic feed, UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildProfileImage(feed),
          const SizedBox(width: 12),
          _buildUserNameAndDate(feed),
          const Spacer(),
          _buildMenuButton(feed, userProvider),
        ],
      ),
    );
  }

  /// 프로필 이미지
  Widget _buildProfileImage(dynamic feed) {
    return CircleAvatar(
      radius: _profileRadius,
      backgroundImage: feed['user'] != null && feed['user']['profile_image'] != null
          ? NetworkImage(_getFullImageUrl(feed['user']['profile_image']))
          : const AssetImage(_defaultProfilePath) as ImageProvider,
    );
  }

  /// 사용자명과 날짜
  Widget _buildUserNameAndDate(dynamic feed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feed['user'] != null ? feed['user']['username'] ?? _userText : _userText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          feed['created_at'] != null ? _formatDate(feed['created_at']) : "",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 메뉴 버튼 (수정/삭제)
  Widget _buildMenuButton(dynamic feed, UserProvider userProvider) {
    if (feed['user'] == null || feed['user']['id'] != userProvider.userId) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      color: Colors.grey[800],
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        if (value == 'edit') {
          _editFeed(feed);
        } else if (value == 'delete') {
          _showDeleteConfirmDialog(feed['id']);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.white),
              SizedBox(width: 8),
              Text(_editText, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(_deleteText, style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }

  /// 이미지 슬라이더
  Widget _buildImageSlider(dynamic feed) {
    if (feed['images'] == null || feed['images'] is! List || feed['images'].isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        _buildImagePageView(feed),
        _buildImageIndicator(feed),
      ],
    );
  }

  /// 이미지 페이지뷰
  Widget _buildImagePageView(dynamic feed) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * _maxImageHeight,
      ),
      child: PageView.builder(
        controller: _imagePageController,
        itemCount: feed['images'].length,
        onPageChanged: (index) {
          setState(() => _currentImageIndex = index);
        },
        itemBuilder: (context, index) {
          final imageUrl = _getFullImageUrl(feed['images'][index]['image_url']);
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey, size: 50),
                    SizedBox(height: 8),
                    Text(_imageLoadErrorMessage, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 이미지 인디케이터
  Widget _buildImageIndicator(dynamic feed) {
    if (feed['images'].length <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${_currentImageIndex + 1}/${feed['images'].length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 유물명 섹션
  Widget _buildArtifactNameSection(dynamic feed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.category, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            "$_artifactNamePrefix${feed['artifact_name'] ?? ''}",
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 뒤로가기 버튼
  Widget _buildBackButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.pop(context),
      backgroundColor: Colors.white.withOpacity(0.3),
      mini: true,
      child: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);
    final feed = feedProvider.currentFeed;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeaderImage(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : feed == null
                ? _buildNoFeedMessage()
                : RefreshIndicator(
              onRefresh: _loadFeedDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoSection(feed, userProvider),
                    _buildImageSlider(feed),
                    _buildArtifactNameSection(feed),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildBackButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }
}