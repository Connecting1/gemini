import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/artifact_provider.dart';
import '../../services/api/api_service.dart';
import 'artifact_detail_screen.dart';

class SearchScreenPage extends StatefulWidget {
  @override
  _SearchScreenPageState createState() => _SearchScreenPageState();
}

class _SearchScreenPageState extends State<SearchScreenPage> {
  static const String _headerImagePath = 'assets/images/eaves.png';
  static const String _searchTitle = '유물 검색';
  static const String _searchHint = '유물 이름, 시대, 출토지 검색';
  static const String _noNameText = '이름 없음';
  static const String _unknownText = '알 수 없음';
  static const String _retryButtonText = '다시 시도';
  static const String _noArtifactsMessage = '등록된 유물이 없습니다.';
  static const String _noResultsMessage = '검색 결과가 없습니다.';
  static const String _model3DText = '3D 모델';
  static const String _allStatus = 'all';

  static const double _titleFontSize = 24;
  static const double _artifactNameFontSize = 18;
  static const double _artifactInfoFontSize = 14;
  static const double _descriptionFontSize = 14;
  static const double _statusFontSize = 12;
  static const double _model3DFontSize = 12;
  static const double _imageSize = 80;
  static const double _iconSize = 40;
  static const double _statusIconSize = 16;
  static const double _model3DIconSize = 14;
  static const double _errorIconSize = 48;
  static const double _searchIconSize = 48;

  static const int _descriptionMaxLines = 2;
  static const int _nameMaxLines = 1;
  static const int _infoMaxLines = 1;

  final TextEditingController _searchController = TextEditingController();
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    if (_isFirstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final artifactProvider = Provider.of<ArtifactProvider>(context, listen: false);
        artifactProvider.fetchArtifacts(status: _allStatus);
      });
      _isFirstLoad = false;
    }
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

  /// 상태에 따른 색상 반환
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified': return Colors.green;
      case 'featured': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'auto_generated':
      default: return Colors.orange;
    }
  }

  /// 상태에 따른 텍스트 반환
  String _getStatusText(String? status) {
    switch (status) {
      case 'verified': return '검증됨';
      case 'featured': return '주목할 만한';
      case 'rejected': return '거부됨';
      case 'auto_generated': return '자동 생성됨';
      default: return _unknownText;
    }
  }

  /// 유물 상세 페이지로 이동
  void _navigateToArtifactDetail(dynamic artifact) {
    if (artifact != null && artifact['id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArtifactDetailScreen(artifactId: artifact['id'].toString()),
        ),
      );
    }
  }

  /// 새로고침
  Future<void> _refreshArtifacts() async {
    final artifactProvider = Provider.of<ArtifactProvider>(context, listen: false);
    await artifactProvider.fetchArtifacts(status: _allStatus);
  }

  /// 헤더 이미지
  Widget _buildHeaderImage() {
    return Image.asset(
      _headerImagePath,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  /// 검색 제목
  Widget _buildSearchTitle() {
    return const Text(
      _searchTitle,
      style: TextStyle(
        fontSize: _titleFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// 검색 바
  Widget _buildSearchBar() {
    return Consumer<ArtifactProvider>(
      builder: (context, artifactProvider, child) {
        _searchController.text = artifactProvider.searchQuery;

        return TextField(
          controller: _searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: _searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: artifactProvider.searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                artifactProvider.setSearchQuery('');
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            artifactProvider.setSearchQuery(value);
          },
        );
      },
    );
  }

  /// 검색 영역
  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchTitle(),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  /// 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 에러 화면
  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: _errorIconSize),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshArtifacts,
              child: const Text(_retryButtonText),
            ),
          ],
        ),
      ),
    );
  }

  /// 유물 없음 메시지
  Widget _buildNoArtifactsMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, color: Colors.grey, size: _searchIconSize),
          SizedBox(height: 16),
          Text(
            _noArtifactsMessage,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 검색 결과 없음 메시지
  Widget _buildNoResultsMessage(String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.grey, size: _searchIconSize),
          const SizedBox(height: 16),
          const Text(
            _noResultsMessage,
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            '"$searchQuery"에 대한 검색 결과가 없습니다.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 유물 이미지
  Widget _buildArtifactImage(dynamic artifact) {
    String imageUrl = _extractImageUrl(artifact);

    return Container(
      width: _imageSize,
      height: _imageSize,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _getFullImageUrl(imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.museum, size: _iconSize, color: Colors.grey.shade600);
          },
        ),
      )
          : Icon(Icons.museum, size: _iconSize, color: Colors.grey.shade600),
    );
  }

  /// 이미지 URL 추출
  String _extractImageUrl(dynamic artifact) {
    if (artifact is! Map) return '';

    if (artifact.containsKey('thumbnail_url') && artifact['thumbnail_url'] != null) {
      return artifact['thumbnail_url'].toString();
    }

    if (artifact.containsKey('feeds') && artifact['feeds'] is List) {
      for (var feed in artifact['feeds']) {
        if (feed is Map && feed.containsKey('images') && feed['images'] is List) {
          for (var image in feed['images']) {
            if (image is Map && image.containsKey('image_url')) {
              return image['image_url'].toString();
            }
          }
        }
      }
    }

    return '';
  }

  /// 3D 모델 배지
  Widget _buildModel3DBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.view_in_ar, color: Colors.blue, size: _model3DIconSize),
          SizedBox(width: 4),
          Text(
            _model3DText,
            style: TextStyle(
              fontSize: _model3DFontSize,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// 유물 정보 섹션
  Widget _buildArtifactInfo(dynamic artifact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          artifact['name'] ?? _noNameText,
          style: const TextStyle(
            fontSize: _artifactNameFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: _nameMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (_hasValue(artifact['time_period']))
          Text(
            artifact['time_period'],
            style: const TextStyle(
              fontSize: _artifactInfoFontSize,
              color: Colors.black54,
            ),
            maxLines: _infoMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        if (_hasValue(artifact['origin_location']))
          Text(
            artifact['origin_location'],
            style: const TextStyle(
              fontSize: _artifactInfoFontSize,
              color: Colors.black54,
            ),
            maxLines: _infoMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        if (artifact['has_3d_model'] == true) _buildModel3DBadge(),
      ],
    );
  }

  /// 값이 있는지 확인
  bool _hasValue(dynamic value) {
    return value != null && value.toString().isNotEmpty;
  }

  /// 유물 설명
  Widget _buildArtifactDescription(dynamic artifact) {
    if (!_hasValue(artifact['description'])) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          artifact['description'],
          style: const TextStyle(
            fontSize: _descriptionFontSize,
            color: Colors.black87,
          ),
          maxLines: _descriptionMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 통계 정보
  Widget _buildStatsInfo(dynamic artifact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.image, size: _statusIconSize, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${artifact['image_count'] ?? 0}',
              style: const TextStyle(
                fontSize: _artifactInfoFontSize,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.feed, size: _statusIconSize, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${artifact['feed_count'] ?? 0}',
              style: const TextStyle(
                fontSize: _artifactInfoFontSize,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(artifact['status']),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getStatusText(artifact['status']),
            style: const TextStyle(
              fontSize: _statusFontSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 유물 카드
  Widget _buildArtifactCard(dynamic artifact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToArtifactDetail(artifact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildArtifactImage(artifact),
                  const SizedBox(width: 16),
                  Expanded(child: _buildArtifactInfo(artifact)),
                ],
              ),
              _buildArtifactDescription(artifact),
              const SizedBox(height: 12),
              _buildStatsInfo(artifact),
            ],
          ),
        ),
      ),
    );
  }

  /// 유물 목록
  Widget _buildArtifactList(List<dynamic> artifacts) {
    return RefreshIndicator(
      onRefresh: _refreshArtifacts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: artifacts.length,
        itemBuilder: (context, index) => _buildArtifactCard(artifacts[index]),
      ),
    );
  }

  /// 검색 결과 영역
  Widget _buildSearchResults() {
    return Expanded(
      child: Consumer<ArtifactProvider>(
        builder: (context, artifactProvider, child) {
          if (artifactProvider.isLoading) {
            return _buildLoadingIndicator();
          }

          if (artifactProvider.error.isNotEmpty) {
            return _buildErrorScreen(artifactProvider.error);
          }

          final artifacts = artifactProvider.filteredArtifacts;

          if (artifacts.isEmpty) {
            if (artifactProvider.searchQuery.isEmpty) {
              return _buildNoArtifactsMessage();
            } else {
              return _buildNoResultsMessage(artifactProvider.searchQuery);
            }
          }

          return _buildArtifactList(artifacts);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildHeaderImage(),
          _buildSearchSection(),
          _buildSearchResults(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}