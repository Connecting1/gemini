import 'package:flutter/material.dart';
import '../services/api/model3d_api.dart';

/// 3D 모델 데이터와 상태 관리
class Model3DProvider extends ChangeNotifier {
  static const String _completedStatus = 'completed';
  static const String _unexpectedFormatError = '예상치 못한 응답 형식입니다';
  static const String _fetchModelsError = '3D 모델을 불러오는 중 오류가 발생했습니다';
  static const String _fetchArtifactModelsError = '유물의 3D 모델을 불러오는 중 오류가 발생했습니다';

  List<dynamic> _models = [];
  dynamic _currentModel;
  bool _isLoading = false;
  String _error = '';
  int _currentIndex = 0;

  List<dynamic> get models => _models;
  dynamic get currentModel => _currentModel;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get currentIndex => _currentIndex;

  /// 현재 인덱스 설정
  void setCurrentIndex(int index) {
    if (_isValidIndex(index)) {
      _currentIndex = index;
      _currentModel = _models[index];
      notifyListeners();
    }
  }

  /// 다음 모델로 이동
  void nextModel() {
    if (_models.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _models.length;
      _updateCurrentModel();
    }
  }

  /// 이전 모델로 이동
  void previousModel() {
    if (_models.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _models.length) % _models.length;
      _updateCurrentModel();
    }
  }

  /// 인덱스 유효성 검사
  bool _isValidIndex(int index) {
    return index >= 0 && index < _models.length;
  }

  /// 현재 모델 업데이트
  void _updateCurrentModel() {
    _currentModel = _models[_currentIndex];
    notifyListeners();
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = '';
    notifyListeners();
  }

  /// API 응답에서 모델 목록 추출
  List<dynamic> _extractModelsList(dynamic result) {
    if (result is List) {
      return List.from(result);
    } else if (result is Map && result.containsKey('results') && result['results'] is List) {
      return List.from(result['results']);
    } else if (result is Map && result.containsKey('error')) {
      _error = result['error'].toString();
      return [];
    } else {
      _error = _unexpectedFormatError;
      return [];
    }
  }

  /// 완료된 모델만 필터링
  List<dynamic> _filterCompletedModels(List<dynamic> models) {
    return models.where((model) =>
    model is Map &&
        model.containsKey('status') &&
        model['status'] == _completedStatus
    ).toList();
  }

  /// 첫 번째 모델을 현재 모델로 설정
  void _setFirstModelAsCurrent() {
    if (_models.isNotEmpty) {
      _currentModel = _models[0];
      _currentIndex = 0;
    }
  }

  /// 완료된 3D 모델 목록 조회
  Future<void> fetchCompletedModels() async {
    _setLoading(true);

    try {
      final result = await Model3DApi.fetchModels(status: _completedStatus);
      _models = _extractModelsList(result);
      _setFirstModelAsCurrent();
    } catch (e) {
      _error = '$_fetchModelsError: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 특정 유물의 3D 모델 목록 조회
  Future<void> fetchArtifactModels(String artifactId) async {
    _setLoading(true);

    try {
      final result = await Model3DApi.fetchArtifactModels(artifactId);

      if (result is List) {
        final completedModels = _filterCompletedModels(result);
        if (completedModels.isNotEmpty) {
          _handleArtifactModels(artifactId, completedModels);
        }
      } else if (result is Map && result.containsKey('error')) {
        _error = result['error'].toString();
      }
    } catch (e) {
      _error = '$_fetchArtifactModelsError: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 유물 모델 처리
  void _handleArtifactModels(String artifactId, List<dynamic> completedModels) {
    final existingIndex = _findExistingModelIndex(artifactId);

    if (existingIndex != -1) {
      setCurrentIndex(existingIndex);
    } else {
      _addNewModelIfNotDuplicate(completedModels[0]);
    }
  }

  /// 기존 모델 인덱스 찾기
  int _findExistingModelIndex(String artifactId) {
    for (int i = 0; i < _models.length; i++) {
      if (_isModelForArtifact(_models[i], artifactId)) {
        return i;
      }
    }
    return -1;
  }

  /// 모델이 특정 유물에 속하는지 확인
  bool _isModelForArtifact(dynamic model, String artifactId) {
    return model is Map &&
        model.containsKey('artifact') &&
        model['artifact'].toString() == artifactId;
  }

  /// 중복이 아닌 경우 새 모델 추가
  void _addNewModelIfNotDuplicate(dynamic modelToAdd) {
    if (!_isDuplicateModel(modelToAdd)) {
      _models.add(modelToAdd);
      _currentModel = modelToAdd;
      _currentIndex = _models.length - 1;
      notifyListeners();
    }
  }

  /// 중복 모델 확인
  bool _isDuplicateModel(dynamic modelToAdd) {
    if (!modelToAdd.containsKey('id')) return false;

    return _models.any((existingModel) =>
    existingModel is Map &&
        existingModel.containsKey('id') &&
        existingModel['id'] == modelToAdd['id']
    );
  }

  /// 에러 상태 초기화
  void clearError() {
    _error = '';
    notifyListeners();
  }
}