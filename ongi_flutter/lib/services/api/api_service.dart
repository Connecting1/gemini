import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.219.102:8000";

  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = "user_id";
  static const String _contentType = "application/json; charset=UTF-8";
  static const String _authHeaderPrefix = "Token ";

  static const String _successMessage = "Success";
  static const String _invalidMethodError = "Invalid HTTP method";
  static const String _authExpiredError = "인증이 만료되었습니다. 다시 로그인해 주세요.";
  static const String _parseError = "응답을 파싱할 수 없습니다";
  static const String _serverError = "서버 오류";
  static const String _networkError = "네트워크 연결 실패";
  static const String _httpError = "HTTP 요청 실패";
  static const String _formatError = "응답 형식 오류";
  static const String _timeoutError = "요청 시간 초과";
  static const String _requestFailedError = "Request Failed";

  static const int _successStartCode = 200;
  static const int _successEndCode = 300;
  static const int _unauthorizedCode = 401;
  static const int _forbiddenCode = 403;
  static const int _maxLogLength = 1000;
  static const int _previewLength = 500;

  /// SharedPreferences에서 사용자 ID 가져오기
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// 인증 토큰 가져오기
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// HTTP 헤더 구성
  static Future<Map<String, String>> _buildHeaders({bool includeContentType = true}) async {
    final headers = <String, String>{};

    if (includeContentType) {
      headers["Content-Type"] = _contentType;
    }

    final authToken = await _getAuthToken();
    if (authToken != null && authToken.isNotEmpty) {
      headers["Authorization"] = "$_authHeaderPrefix$authToken";
    }

    return headers;
  }

  /// 응답 디코딩
  static String _decodeResponse(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  /// 인증 에러 확인
  static bool _isAuthError(int statusCode) {
    return statusCode == _unauthorizedCode || statusCode == _forbiddenCode;
  }

  /// 성공 상태 코드 확인
  static bool _isSuccessStatusCode(int statusCode) {
    return statusCode >= _successStartCode && statusCode < _successEndCode;
  }

  /// 응답 처리
  static dynamic _processResponse(http.Response response) {
    if (_isAuthError(response.statusCode)) {
      return {
        "error": _authExpiredError,
        "status": response.statusCode
      };
    }

    final decodedBody = _decodeResponse(response);

    if (_isSuccessStatusCode(response.statusCode)) {
      if (response.body.isEmpty) {
        return {"message": _successMessage};
      }

      try {
        return jsonDecode(decodedBody);
      } catch (e) {
        return {"error": "$_parseError: $decodedBody"};
      }
    } else {
      try {
        return jsonDecode(decodedBody);
      } catch (e) {
        return {
          "error": "$_serverError: ${response.statusCode}",
          "body": decodedBody
        };
      }
    }
  }

  /// 예외 처리
  static Map<String, dynamic> _handleException(dynamic e) {
    if (e is SocketException) {
      return {"error": "$_networkError: ${e.message}"};
    } else if (e is HttpException) {
      return {"error": "$_httpError: ${e.message}"};
    } else if (e is FormatException) {
      return {"error": "$_formatError: ${e.message}"};
    } else if (e is TimeoutException) {
      return {"error": _timeoutError};
    } else {
      return {"error": "$_requestFailedError: ${e.toString()}"};
    }
  }

  /// GET 요청 처리
  static Future<http.Response> _sendGetRequest(Uri url, Map<String, String> headers) {
    return http.get(url, headers: headers);
  }

  /// POST 요청 처리
  static Future<http.Response> _sendPostRequest(Uri url, Map<String, String> headers, Map<String, dynamic>? body) {
    return http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  /// DELETE 요청 처리
  static Future<http.Response> _sendDeleteRequest(Uri url, Map<String, String> headers, Map<String, dynamic>? body) {
    return http.delete(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PATCH 요청 처리
  static Future<http.Response> _sendPatchRequest(Uri url, Map<String, String> headers, Map<String, dynamic>? body, File? file) async {
    final request = http.MultipartRequest("PATCH", url);

    // 헤더 추가 (Content-Type 제외)
    headers.forEach((key, value) {
      if (key != "Content-Type") {
        request.headers[key] = value;
      }
    });

    // 필드 추가
    if (body != null) {
      body.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
    }

    // 파일 추가
    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
          filename: basename(file.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  /// HTTP 요청 실행
  static Future<http.Response> _executeRequest(String method, Uri url, Map<String, String> headers, Map<String, dynamic>? body, File? file) async {
    switch (method) {
      case "GET":
        return _sendGetRequest(url, headers);
      case "POST":
        return _sendPostRequest(url, headers, body);
      case "PATCH":
        return _sendPatchRequest(url, headers, body, file);
      case "DELETE":
        return _sendDeleteRequest(url, headers, body);
      default:
        throw ArgumentError(_invalidMethodError);
    }
  }

  /// 공통 HTTP 요청 핸들러
  static Future<dynamic> sendRequest({
    required String endpoint,
    String method = "GET",
    Map<String, dynamic>? body,
    File? file,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");

    try {
      final headers = await _buildHeaders();
      final response = await _executeRequest(method, url, headers, body, file);
      return _processResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Multipart 요청용 헤더 구성
  static Future<Map<String, String>> _buildMultipartHeaders() async {
    return await _buildHeaders(includeContentType: false);
  }

  /// Multipart 요청에 필드 추가
  static void _addFieldsToRequest(http.MultipartRequest request, Map<String, dynamic>? fields) {
    if (fields != null) {
      fields.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
    }
  }

  /// Multipart 요청에 파일들 추가
  static Future<void> _addFilesToRequest(http.MultipartRequest request, List<Map<String, dynamic>>? files) async {
    if (files != null) {
      for (var fileInfo in files) {
        final fieldName = fileInfo["name"] as String;
        final file = fileInfo["file"] as File;

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            filename: basename(file.path),
          ),
        );
      }
    }
  }

  /// 여러 파일이 있는 Multipart 요청 처리
  static Future<dynamic> sendMultipartRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? fields,
    List<Map<String, dynamic>>? files,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");

    try {
      final request = http.MultipartRequest(method, url);

      // 헤더 설정
      final headers = await _buildMultipartHeaders();
      request.headers.addAll(headers);

      // 필드 및 파일 추가
      _addFieldsToRequest(request, fields);
      await _addFilesToRequest(request, files);

      // 요청 전송 및 응답 처리
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }
}