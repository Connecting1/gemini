import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/artifact_provider.dart';
import '../../providers/model3d_provider.dart';
import '../../services/api/api_service.dart';
import '../feed/feed_detail_screen.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ArtifactDetailScreen extends StatefulWidget {
  final String artifactId;

  const ArtifactDetailScreen({Key? key, required this.artifactId}) : super(key: key);

  @override
  _ArtifactDetailScreenState createState() => _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends State<ArtifactDetailScreen> {
  static const String _headerImagePath = 'assets/images/eaves.png';
  static const String _errorMessage = '유물 정보를 찾을 수 없습니다.';
  static const String _retryButtonText = '다시 시도';
  static const String _noNameText = '이름 없음';
  static const String _unknownText = '알 수 없음';
  static const String _noTitleText = '제목 없음';
  static const String _authorPrefix = '작성자: ';
  static const String _noFeedsMessage = '관련 피드가 없습니다.';
  static const String _moreButtonText = '더 보기';

  static const String _basicInfoTitle = '기본 정보';
  static const String _descriptionTitle = '설명';
  static const String _relatedFeedsTitle = '관련 피드';
  static const String _model3DTitle = '3D 모델';
  static const String _model3DPreviewTitle = '3D 모델 미리보기';
  static const String _model3DLoadingTitle = '3D 모델 로딩 중...';
  static const String _model3DProvideTitle = '3D 모델 제공';
  static const String _model3DAvailableMessage = '이 유물은 3D 모델을 제공합니다. 메인 화면에서 확인할 수 있습니다.';
  static const String _model3DErrorMessage = '3D 모델 데이터를 불러오는 중 문제가 발생했습니다. 메인 화면에서 확인해 보세요.';

  static const String _timePeriodLabel = '시대';
  static const String _estimatedYearLabel = '추정 연도';
  static const String _originLocationLabel = '출토 위치';
  static const String _imageCountLabel = '이미지 수';
  static const String _feedCountLabel = '피드 수';
  static const String _createdAtLabel = '등록일';
  static const String _countSuffix = '개';

  static const String _completedStatus = 'completed';
  static const String _model3DAlt = "3D 모델";

  static const double _modelViewerHeight = 300;
  static const double _feedCardWidth = 160;
  static const double _feedCardHeight = 220;
  static const double _feedImageHeight = 120;
  static const double _labelWidth = 100;

  bool _loadingFeeds = false;
  bool _loading3DModel = false;
  List<dynamic> _relatedFeeds = [];
  dynamic _model3D;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 모든 데이터 로드
  Future<void> _loadData() async {
    await _loadArtifactDetail();
    await _loadRelatedFeeds();
    await _load3DModelInfo();
  }

  /// 유물 상세 정보 로드
  Future<void> _loadArtifactDetail() async {
    final artifactProvider = Provider.of<ArtifactProvider>(context, listen: false);
    await artifactProvider.fetchArtifactDetail(widget.artifactId);
  }

  /// 관련 피드 로드
  Future<void> _loadRelatedFeeds() async {
    setState(() => _loadingFeeds = true);

    try {
      final artifactProvider = Provider.of<ArtifactProvider>(context, listen: false);
      _relatedFeeds = await artifactProvider.fetchArtifactFeeds(widget.artifactId);
    } catch (e) {
      // 에러 처리는 필요시 추가
    } finally {
      if (mounted) {
        setState(() => _loadingFeeds = false);
      }
    }
  }

  /// 3D 모델 정보 로드
  Future<void> _load3DModelInfo() async {
    setState(() => _loading3DModel = true);

    try {
      final model3dProvider = Provider.of<Model3DProvider>(context, listen: false);
      await model3dProvider.fetchArtifactModels(widget.artifactId);

      _findCompletedModel(model3dProvider.models);
    } catch (e) {
      // 에러 처리는 필요시 추가
    } finally {
      if (mounted) {
        setState(() => _loading3DModel = false);
      }
    }
  }

  /// 완료된 3D 모델 찾기
  void _findCompletedModel(List<dynamic> models) {
    for (var model in models) {
      if (_isCompletedModelForArtifact(model)) {
        setState(() => _model3D = model);
        break;
      }
    }
  }

  /// 모델이 현재 유물의 완료된 모델인지 확인
  bool _isCompletedModelForArtifact(dynamic model) {
    return model is Map &&
        model.containsKey('artifact') &&
        model['artifact'].toString() == widget.artifactId &&
        model.containsKey('status') &&
        model['status'] == _completedStatus;
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

    return '${ApiService.baseUrl}/$url';
  }

  /// 날짜 포맷팅
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return _unknownText;

    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}년 ${date.month}월 ${date.day}일';
    } catch (e) {
      return dateStr;
    }
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

  /// 헤더 이미지와 뒤로가기 버튼
  Widget _buildHeader() {
    return Stack(
      children: [
        Image.asset(
          _headerImagePath,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        SafeArea(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
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
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text(_retryButtonText),
            ),
          ],
        ),
      ),
    );
  }

  /// 유물 없음 메시지
  Widget _buildNoArtifactMessage() {
    return const Center(
      child: Text(
        _errorMessage,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  /// 유물 이름과 상태
  Widget _buildArtifactHeader(dynamic artifact) {
    return Row(
      children: [
        Expanded(
          child: Text(
            artifact['name'] ?? _noNameText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
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
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 기본 정보 섹션 빌드
  Widget _buildBasicInfoSection(dynamic artifact) {
    final infoItems = <Widget>[];

    if (_hasValue(artifact['time_period'])) {
      infoItems.add(_buildInfoItem(_timePeriodLabel, artifact['time_period']));
    }
    if (_hasValue(artifact['estimated_year'])) {
      infoItems.add(_buildInfoItem(_estimatedYearLabel, artifact['estimated_year']));
    }
    if (_hasValue(artifact['origin_location'])) {
      infoItems.add(_buildInfoItem(_originLocationLabel, artifact['origin_location']));
    }

    infoItems.addAll([
      _buildInfoItem(_imageCountLabel, '${artifact['image_count'] ?? 0}$_countSuffix'),
      _buildInfoItem(_feedCountLabel, '${artifact['feed_count'] ?? 0}$_countSuffix'),
      _buildInfoItem(_createdAtLabel, _formatDate(artifact['created_at'])),
    ]);

    return _buildInfoSection(_basicInfoTitle, infoItems);
  }

  /// 값이 있는지 확인
  bool _hasValue(dynamic value) {
    return value != null && value.toString().isNotEmpty;
  }

  /// 설명 섹션 빌드
  Widget _buildDescriptionSection(dynamic artifact) {
    if (!_hasValue(artifact['description'])) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildInfoSection(_descriptionTitle, [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              artifact['description'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ]),
      ],
    );
  }

  /// 3D 모델 섹션 빌드
  Widget _build3DModelSection(dynamic artifact) {
    if (_model3D == null && !_loading3DModel && artifact['has_3d_model'] != true) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _build3DModelContent(),
      ],
    );
  }

  /// 3D 모델 컨텐츠
  Widget _build3DModelContent() {
    if (_loading3DModel) {
      return _build3DModelContainer(
        _model3DLoadingTitle,
        child: const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_model3D == null) {
      return _build3DModelContainer(
        _model3DProvideTitle,
        child: const Text(
          _model3DAvailableMessage,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return _build3DModelWithViewer();
  }

  /// 3D 모델 컨테이너
  Widget _build3DModelContainer(String title, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_in_ar, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// 3D 모델 뷰어와 함께 빌드
  Widget _build3DModelWithViewer() {
    final modelUrl = _buildModelUrl();

    if (modelUrl.isEmpty) {
      return _build3DModelContainer(
        _model3DProvideTitle,
        child: const Text(
          _model3DErrorMessage,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.view_in_ar, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              _model3DPreviewTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildModelViewer(modelUrl),
        _buildModelDescription(),
      ],
    );
  }

  /// 모델 URL 생성
  String _buildModelUrl() {
    if (_model3D is! Map || !_model3D.containsKey('model_url')) {
      return '';
    }

    String modelPath = _model3D['model_url'].toString();
    if (modelPath.startsWith('http')) {
      return modelPath;
    }

    if (modelPath.startsWith('/')) {
      modelPath = modelPath.substring(1);
    }

    return '${ApiService.baseUrl}/$modelPath';
  }

  /// 모델 뷰어
  Widget _buildModelViewer(String modelUrl) {
    return Container(
      height: _modelViewerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: ModelViewer(
          backgroundColor: const Color.fromARGB(0xFF, 0x00, 0x00, 0x00),
          src: modelUrl,
          alt: _model3DAlt,
          ar: false,
          autoRotate: true,
          cameraControls: true,
          disableZoom: false,
        ),
      ),
    );
  }

  /// 모델 설명
  Widget _buildModelDescription() {
    if (_model3D is! Map || !_model3D.containsKey('description') || _model3D['description'] == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _model3D['description'],
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 정보 섹션
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// 정보 항목
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// 관련 피드 섹션
  Widget _buildRelatedFeedsSection() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRelatedFeedsHeader(),
            const SizedBox(height: 8),
            _buildRelatedFeedsContent(),
          ],
        ),
      ],
    );
  }

  /// 관련 피드 헤더
  Widget _buildRelatedFeedsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          _relatedFeedsTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: () {
            // 모든 관련 피드 보기 화면으로 이동
          },
          child: const Text(_moreButtonText),
        ),
      ],
    );
  }

  /// 관련 피드 컨텐츠
  Widget _buildRelatedFeedsContent() {
    if (_loadingFeeds) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_relatedFeeds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              _noFeedsMessage,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _feedCardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _relatedFeeds.length,
        itemBuilder: (context, index) => _buildFeedCard(_relatedFeeds[index]),
      ),
    );
  }

  /// 피드 카드
  Widget _buildFeedCard(dynamic feed) {
    final imageUrl = _extractFeedImageUrl(feed);

    return GestureDetector(
      onTap: () => _navigateToFeedDetail(feed),
      child: Container(
        width: _feedCardWidth,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeedImage(imageUrl),
            _buildFeedInfo(feed),
          ],
        ),
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

  /// 피드 상세로 이동
  void _navigateToFeedDetail(dynamic feed) {
    if (feed is Map && feed.containsKey('id')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedDetailScreen(feedId: feed['id'].toString()),
        ),
      );
    }
  }

  /// 피드 이미지
  Widget _buildFeedImage(String imageUrl) {
    return Container(
      height: _feedImageHeight,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        image: imageUrl.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        )
            : null,
        color: Colors.grey.shade700,
      ),
      child: imageUrl.isEmpty
          ? const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      )
          : null,
    );
  }

  /// 피드 정보
  Widget _buildFeedInfo(dynamic feed) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feed['artifact_name'] ?? _noTitleText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          _buildFeedAuthor(feed),
          const SizedBox(height: 4),
          _buildFeedImageCount(feed),
        ],
      ),
    );
  }

  /// 피드 작성자
  Widget _buildFeedAuthor(dynamic feed) {
    if (feed['user'] == null || !feed['user'].containsKey('username')) {
      return const SizedBox.shrink();
    }

    return Text(
      '$_authorPrefix${feed['user']['username']}',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade300,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 피드 이미지 개수
  Widget _buildFeedImageCount(dynamic feed) {
    final imageCount = feed.containsKey('images') && feed['images'] is List
        ? feed['images'].length
        : 0;

    return Row(
      children: [
        const Icon(Icons.image, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$imageCount',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 메인 컨텐츠
  Widget _buildMainContent(dynamic artifact) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArtifactHeader(artifact),
              const SizedBox(height: 16),
              _buildBasicInfoSection(artifact),
              _buildDescriptionSection(artifact),
              _build3DModelSection(artifact),
              _buildRelatedFeedsSection(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer<ArtifactProvider>(
              builder: (context, artifactProvider, child) {
                if (artifactProvider.isLoading) {
                  return _buildLoadingIndicator();
                }

                if (artifactProvider.error.isNotEmpty) {
                  return _buildErrorScreen(artifactProvider.error);
                }

                final artifact = artifactProvider.currentArtifact;
                if (artifact == null) {
                  return _buildNoArtifactMessage();
                }

                // 3D 모델 정보 동기화
                if (_model3D == null && artifact['has_3d_model'] == true) {
                  _load3DModelInfo();
                }

                return _buildMainContent(artifact);
              },
            ),
          ),
        ],
      ),
    );
  }
}