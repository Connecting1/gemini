import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' show basename;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../providers/feed_provider.dart';
import '../../screens/main/main_tab.dart';

class UploadScreenPage extends StatefulWidget {
  const UploadScreenPage({Key? key}) : super(key: key);

  @override
  _UploadScreenPageState createState() => _UploadScreenPageState();
}

class _UploadScreenPageState extends State<UploadScreenPage> {
  static const String _headerImagePath = 'assets/images/eaves.png';
  static const String _pageTitle = '유물 업로드';
  static const String _selectedImagesTitle = '선택한 이미지';
  static const String _galleryButtonText = '갤러리에서 선택';
  static const String _cameraButtonText = '카메라로 촬영';
  static const String _artifactNameLabel = '유물 이름';
  static const String _artifactNameHint = '사진 속 유물의 이름을 입력하세요';
  static const String _submitButtonText = '등록';

  static const String _artifactNameRequiredMessage = '유물 이름을 입력해 주세요';
  static const String _minImagesRequiredMessage = '최소 한 장 이상의 이미지를 업로드해 주세요';
  static const String _imageSelectionErrorMessage = '이미지 선택 중 오류가 발생했습니다';
  static const String _cameraErrorMessage = '사진 촬영 중 오류가 발생했습니다';
  static const String _uploadSuccessMessage = '피드가 성공적으로 업로드되었습니다';
  static const String _uploadFailedMessage = '업로드 실패';
  static const String _uploadErrorMessage = '업로드 중 오류 발생';
  static const String _tempFileDeleteErrorMessage = '임시 파일 삭제 중 오류 발생';
  static const String _imageCompressErrorMessage = '이미지 압축 중 오류 발생';

  static const String _preparingCompressionStatus = '이미지 압축 준비 중...';
  static const String _compressingImageStatus = '이미지 압축 중';
  static const String _uploadingFeedStatus = '피드 업로드 중...';
  static const String _uploadingImageStatus = '이미지 업로드 중';

  static const double _pageTitleFontSize = 24;
  static const double _sectionTitleFontSize = 16;
  static const double _submitButtonFontSize = 18;
  static const double _imagePreviewSize = 120;
  static const double _removeIconSize = 18;
  static const double _buttonBorderRadius = 12;
  static const double _imagePreviewBorderRadius = 8;

  static const int _imageCompressQuality = 70;
  static const int _maxImageWidth = 1024;
  static const int _maxImageHeight = 1024;

  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _navigationDelay = Duration(milliseconds: 100);
  static const Duration _uiUpdateDelay = Duration(milliseconds: 100);
  static const Duration _progressUpdateDelay = Duration(milliseconds: 50);

  final _formKey = GlobalKey<FormState>();
  final _artifactNameController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final List<File> _tempFiles = [];

  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _artifactNameController.dispose();
    _cleanupTempFiles();
    super.dispose();
  }

  /// 임시 파일 정리
  Future<void> _cleanupTempFiles() async {
    for (var file in _tempFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // 에러 로깅은 필요시 추가
      }
    }
  }

  /// 이미지 압축
  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = basename(file.path);
      final compressedFile = File('${tempDir.path}/compressed_$fileName');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        compressedFile.absolute.path,
        quality: _imageCompressQuality,
        minWidth: _maxImageWidth,
        minHeight: _maxImageHeight,
      );

      if (result != null) {
        final compressedPath = File(result.path);
        _tempFiles.add(compressedPath);
        return compressedPath;
      }
      return file;
    } catch (e) {
      return file;
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var pickedFile in pickedFiles) {
            _selectedImages.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('$_imageSelectionErrorMessage: $e');
    }
  }

  /// 카메라로 사진 촬영
  Future<void> _takePicture() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('$_cameraErrorMessage: $e');
    }
  }

  /// 선택한 이미지 제거
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 성공 스낵바 표시
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 업로드 상태 업데이트
  void _updateUploadStatus(String status, double progress) {
    if (mounted) {
      setState(() {
        _uploadStatus = status;
        _uploadProgress = progress;
      });
    }
  }

  /// 업로드 상태 초기화
  void _resetUploadState() {
    setState(() {
      _isUploading = false;
      _uploadStatus = '';
      _uploadProgress = 0.0;
    });
  }

  /// 폼 유효성 검사
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedImages.isEmpty) {
      _showErrorSnackBar(_minImagesRequiredMessage);
      return false;
    }

    return true;
  }

  /// 업로드 시작
  Future<void> _startUpload() async {
    await Future.microtask(() {
      if (mounted) {
        setState(() {
          _isUploading = true;
          _uploadStatus = _preparingCompressionStatus;
          _uploadProgress = 0.0;
        });
      }
    });

    await Future.delayed(_uiUpdateDelay);
  }

  /// 이미지들 압축 처리
  Future<List<File>?> _compressImages() async {
    final compressedImages = <File>[];

    for (int i = 0; i < _selectedImages.length; i++) {
      if (!mounted) return null;

      _updateUploadStatus(
        '$_compressingImageStatus (${i + 1}/${_selectedImages.length})...',
        (i + 1) / _selectedImages.length * 0.5,
      );

      final compressedImage = await _compressImage(_selectedImages[i]);
      compressedImages.add(compressedImage);

      await Future.delayed(_progressUpdateDelay);
    }

    return compressedImages;
  }

  /// 피드 업로드 처리
  Future<bool> _uploadFeed(List<File> compressedImages) async {
    if (!mounted) return false;

    _updateUploadStatus(_uploadingFeedStatus, 0.5);

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);

    return await feedProvider.createFeed(
      artifactName: _artifactNameController.text,
      images: compressedImages,
      onProgress: (progress) {
        if (mounted) {
          final totalProgress = 0.5 + (progress * 0.5);
          final percentage = (progress * 100).toInt();
          _updateUploadStatus('$_uploadingImageStatus ($percentage%)...', totalProgress);
        }
      },
    );
  }

  /// 업로드 성공 처리
  Future<void> _handleUploadSuccess() async {
    _showSuccessSnackBar(_uploadSuccessMessage);

    await Future.delayed(_uiUpdateDelay);

    if (mounted) {
      _resetUploadState();

      Future.delayed(_navigationDelay, () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => MainTabPage(),
              transitionDuration: Duration.zero,
            ),
          );
        }
      });
    }
  }

  /// 업로드 실패 처리
  void _handleUploadFailure(String error) {
    if (mounted) {
      _showErrorSnackBar('$_uploadFailedMessage: $error');
      _resetUploadState();
    }
  }

  /// 폼 제출 및 피드 업로드
  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    try {
      await _startUpload();

      final compressedImages = await _compressImages();
      if (compressedImages == null || !mounted) return;

      final success = await _uploadFeed(compressedImages);

      if (success) {
        await _handleUploadSuccess();
      } else {
        final feedProvider = Provider.of<FeedProvider>(context, listen: false);
        _handleUploadFailure(feedProvider.error);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('$_uploadErrorMessage: $e');
        _resetUploadState();
      }
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

  /// 페이지 제목
  Widget _buildPageTitle() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            _pageTitle,
            style: TextStyle(
              fontSize: _pageTitleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 화면
  Widget _buildLoadingScreen() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _uploadProgress > 0 ? _uploadProgress : null,
          ),
          const SizedBox(height: 16),
          Text(
            _uploadStatus,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 이미지 미리보기 제거 버튼
  Widget _buildRemoveButton(int index) {
    return Positioned(
      top: 5,
      right: 13,
      child: GestureDetector(
        onTap: () => _removeImage(index),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            size: _removeIconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 이미지 미리보기 항목
  Widget _buildImagePreviewItem(int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: _imagePreviewSize,
          height: _imagePreviewSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_imagePreviewBorderRadius),
            image: DecorationImage(
              image: FileImage(_selectedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        _buildRemoveButton(index),
      ],
    );
  }

  /// 선택한 이미지 미리보기 섹션
  Widget _buildImagePreviewSection() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _selectedImagesTitle,
          style: TextStyle(
            fontSize: _sectionTitleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _imagePreviewSize,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (ctx, index) => _buildImagePreviewItem(index),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 버튼 스타일
  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_buttonBorderRadius),
      ),
    );
  }

  /// 이미지 선택 버튼들
  Widget _buildImageSelectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo_library, color: Colors.black),
          label: const Text(_galleryButtonText),
          style: _buildButtonStyle(),
        ),
        ElevatedButton.icon(
          onPressed: _takePicture,
          icon: const Icon(Icons.camera_alt, color: Colors.black),
          label: const Text(_cameraButtonText),
          style: _buildButtonStyle(),
        ),
      ],
    );
  }

  /// 유물 이름 입력 필드
  Widget _buildArtifactNameField() {
    return TextFormField(
      controller: _artifactNameController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: _artifactNameLabel,
        hintText: _artifactNameHint,
        labelStyle: TextStyle(color: Colors.white),
        hintStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _artifactNameRequiredMessage;
        }
        return null;
      },
    );
  }

  /// 제출 버튼
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _submitForm,
        style: _buildButtonStyle().copyWith(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        child: const Text(
          _submitButtonText,
          style: TextStyle(
            fontSize: _submitButtonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 폼 화면
  Widget _buildFormScreen() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreviewSection(),
            _buildImageSelectionButtons(),
            const SizedBox(height: 24),
            _buildArtifactNameField(),
            const SizedBox(height: 16),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  /// 메인 컨텐츠
  Widget _buildMainContent() {
    return Expanded(
      child: AnimatedSwitcher(
        duration: _animationDuration,
        child: _isUploading ? _buildLoadingScreen() : _buildFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isUploading,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeaderImage(),
            _buildPageTitle(),
            _buildMainContent(),
          ],
        ),
      ),
    );
  }
}