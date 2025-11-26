import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'api/api_service.dart';

/// 가우시안 스플래팅 .ply 파일 다운로드 및 관리 서비스
class GaussianSplattingService {
  static const String _plyDirectory = 'gaussian_splatting_models';
  static const int _downloadTimeout = 300; // 5분

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: _downloadTimeout),
    ),
  );

  /// .ply 파일 저장용 디렉토리 가져오기
  Future<Directory> _getPlyDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final plyDir = Directory(path.join(appDir.path, _plyDirectory));

    if (!await plyDir.exists()) {
      await plyDir.create(recursive: true);
    }

    return plyDir;
  }

  /// 파일명을 안전한 형태로 변환
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s-]'), '_').replaceAll(' ', '_');
  }

  /// .ply 파일의 로컬 경로 가져오기
  Future<String> getLocalPlyPath(String modelId) async {
    final dir = await _getPlyDirectory();
    return path.join(dir.path, '${_sanitizeFileName(modelId)}.ply');
  }

  /// .ply 파일이 로컬에 존재하는지 확인
  Future<bool> isPlyFileExists(String modelId) async {
    final filePath = await getLocalPlyPath(modelId);
    return File(filePath).exists();
  }

  /// 로컬 .ply 파일 삭제
  Future<void> deletePlyFile(String modelId) async {
    try {
      final filePath = await getLocalPlyPath(modelId);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('파일 삭제 실패: $e');
    }
  }

  /// 모든 .ply 파일 삭제 (캐시 정리)
  Future<void> clearAllPlyFiles() async {
    try {
      final dir = await _getPlyDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    } catch (e) {
      throw Exception('캐시 정리 실패: $e');
    }
  }

  /// 저장된 .ply 파일 총 용량 계산
  Future<int> getTotalPlyFileSize() async {
    try {
      final dir = await _getPlyDirectory();
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (var entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.ply')) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// .ply 파일 다운로드
  ///
  /// [modelUrl]: 서버의 .ply 파일 URL
  /// [modelId]: 모델 고유 ID
  /// [onProgress]: 다운로드 진행률 콜백 (0.0 ~ 1.0)
  Future<String> downloadPlyFile({
    required String modelUrl,
    required String modelId,
    Function(double progress)? onProgress,
  }) async {
    try {
      // URL 검증
      if (modelUrl.isEmpty) {
        throw Exception('모델 URL이 비어있습니다');
      }

      // 전체 URL 구성
      final fullUrl = _buildFullUrl(modelUrl);

      // 로컬 저장 경로
      final savePath = await getLocalPlyPath(modelId);

      // 이미 파일이 존재하면 기존 파일 삭제
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 다운로드 실행
      await _dio.download(
        fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      // 파일 유효성 검증
      if (!await file.exists()) {
        throw Exception('다운로드한 파일을 찾을 수 없습니다');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        await file.delete();
        throw Exception('다운로드한 파일이 비어있습니다');
      }

      // PLY 파일 헤더 검증
      if (!await _validatePlyFile(savePath)) {
        await file.delete();
        throw Exception('유효하지 않은 PLY 파일입니다');
      }

      return savePath;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('다운로드 실패: $e');
    }
  }

  /// URL을 전체 URL로 변환
  String _buildFullUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final formattedUrl = url.startsWith('/') ? url : '/$url';
    return "${ApiService.baseUrl}$formattedUrl";
  }

  /// PLY 파일 유효성 검증 (헤더 확인)
  Future<bool> _validatePlyFile(String filePath) async {
    try {
      final file = File(filePath);
      final lines = await file.openRead().transform(const SystemEncoding().decoder).take(5).toList();

      if (lines.isEmpty) return false;

      // PLY 파일은 "ply"로 시작해야 함
      final firstLine = lines[0].trim().toLowerCase();
      return firstLine == 'ply';
    } catch (e) {
      return false;
    }
  }

  /// Dio 에러 처리
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('다운로드 시간이 초과되었습니다');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return Exception('파일을 찾을 수 없습니다 (404)');
        } else if (statusCode == 403) {
          return Exception('파일 접근 권한이 없습니다 (403)');
        }
        return Exception('서버 오류 ($statusCode)');

      case DioExceptionType.cancel:
        return Exception('다운로드가 취소되었습니다');

      case DioExceptionType.connectionError:
        return Exception('네트워크 연결을 확인해주세요');

      default:
        return Exception('다운로드 중 오류가 발생했습니다: ${e.message}');
    }
  }

  /// 파일 크기를 읽기 쉬운 형태로 변환
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 저장된 모든 .ply 파일 목록 가져오기
  Future<List<FileSystemEntity>> getAllPlyFiles() async {
    try {
      final dir = await _getPlyDirectory();
      if (!await dir.exists()) return [];

      return dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.ply'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 특정 .ply 파일 정보 가져오기
  Future<Map<String, dynamic>> getPlyFileInfo(String modelId) async {
    try {
      final filePath = await getLocalPlyPath(modelId);
      final file = File(filePath);

      if (!await file.exists()) {
        return {
          'exists': false,
          'path': filePath,
        };
      }

      final size = await file.length();
      final modified = await file.lastModified();

      return {
        'exists': true,
        'path': filePath,
        'size': size,
        'sizeFormatted': formatFileSize(size),
        'lastModified': modified.toIso8601String(),
      };
    } catch (e) {
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }
}
