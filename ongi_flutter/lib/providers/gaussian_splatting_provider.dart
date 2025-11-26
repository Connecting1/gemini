import 'package:flutter/material.dart';
import '../services/gaussian_splatting_service.dart';

/// 가우시안 스플래팅 상태 관리 Provider
class GaussianSplattingProvider extends ChangeNotifier {
  final GaussianSplattingService _service = GaussianSplattingService();

  // 다운로드 상태
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadError = '';
  String? _currentModelId;
  String? _currentFilePath;

  // 뷰어 상태
  bool _isViewerReady = false;
  String _viewerError = '';

  // Getters
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get downloadError => _downloadError;
  String? get currentModelId => _currentModelId;
  String? get currentFilePath => _currentFilePath;
  bool get isViewerReady => _isViewerReady;
  String get viewerError => _viewerError;

  /// 모델 파일이 로컬에 존재하는지 확인
  Future<bool> isModelAvailable(String modelId) async {
    return await _service.isPlyFileExists(modelId);
  }

  /// 모델 파일 경로 가져오기 (존재하는 경우)
  Future<String?> getModelPath(String modelId) async {
    final exists = await _service.isPlyFileExists(modelId);
    if (exists) {
      return await _service.getLocalPlyPath(modelId);
    }
    return null;
  }

  /// 모델 다운로드 및 준비
  ///
  /// [modelUrl]: 서버의 .ply 파일 URL
  /// [modelId]: 모델 고유 ID
  Future<String?> prepareModel({
    required String modelUrl,
    required String modelId,
  }) async {
    try {
      _resetDownloadState();
      _currentModelId = modelId;

      // 이미 파일이 존재하는지 확인
      final exists = await _service.isPlyFileExists(modelId);
      if (exists) {
        _currentFilePath = await _service.getLocalPlyPath(modelId);
        notifyListeners();
        return _currentFilePath;
      }

      // 파일 다운로드
      _isDownloading = true;
      notifyListeners();

      final filePath = await _service.downloadPlyFile(
        modelUrl: modelUrl,
        modelId: modelId,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      _currentFilePath = filePath;
      _isDownloading = false;
      _downloadProgress = 1.0;
      notifyListeners();

      return filePath;
    } catch (e) {
      _downloadError = e.toString();
      _isDownloading = false;
      _currentFilePath = null;
      notifyListeners();
      return null;
    }
  }

  /// 다운로드 상태 초기화
  void _resetDownloadState() {
    _isDownloading = false;
    _downloadProgress = 0.0;
    _downloadError = '';
    notifyListeners();
  }

  /// 뷰어 준비 완료 상태 설정
  void setViewerReady(bool ready) {
    _isViewerReady = ready;
    notifyListeners();
  }

  /// 뷰어 에러 설정
  void setViewerError(String error) {
    _viewerError = error;
    _isViewerReady = false;
    notifyListeners();
  }

  /// 뷰어 에러 초기화
  void clearViewerError() {
    _viewerError = '';
    notifyListeners();
  }

  /// 현재 모델 초기화
  void clearCurrentModel() {
    _currentModelId = null;
    _currentFilePath = null;
    _isViewerReady = false;
    _viewerError = '';
    notifyListeners();
  }

  /// 특정 모델 파일 삭제
  Future<bool> deleteModel(String modelId) async {
    try {
      await _service.deletePlyFile(modelId);

      // 현재 모델이 삭제된 경우 상태 초기화
      if (_currentModelId == modelId) {
        clearCurrentModel();
      }

      return true;
    } catch (e) {
      _downloadError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 모든 모델 파일 삭제 (캐시 정리)
  Future<bool> clearAllModels() async {
    try {
      await _service.clearAllPlyFiles();
      clearCurrentModel();
      _resetDownloadState();
      return true;
    } catch (e) {
      _downloadError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 저장된 모든 모델 파일 총 용량
  Future<int> getTotalStorageUsed() async {
    return await _service.getTotalPlyFileSize();
  }

  /// 저장된 모든 모델 파일 총 용량 (포맷된 문자열)
  Future<String> getFormattedStorageUsed() async {
    final bytes = await getTotalStorageUsed();
    return GaussianSplattingService.formatFileSize(bytes);
  }

  /// 모델 파일 정보 가져오기
  Future<Map<String, dynamic>> getModelInfo(String modelId) async {
    return await _service.getPlyFileInfo(modelId);
  }

  /// 다운로드 진행률 (백분율)
  int get downloadProgressPercent => (downloadProgress * 100).toInt();

  /// 다운로드 진행 중 여부
  bool get isDownloadInProgress => _isDownloading && _downloadProgress < 1.0;

  /// 다운로드 완료 여부
  bool get isDownloadCompleted => _downloadProgress >= 1.0 && !_isDownloading;

  /// 에러 발생 여부
  bool get hasError => _downloadError.isNotEmpty || _viewerError.isNotEmpty;

  /// 통합 에러 메시지
  String get errorMessage {
    if (_downloadError.isNotEmpty) return _downloadError;
    if (_viewerError.isNotEmpty) return _viewerError;
    return '';
  }
}
