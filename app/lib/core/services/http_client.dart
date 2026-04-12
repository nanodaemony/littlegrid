import 'dart:convert';
import 'package:http/http.dart' as http;
import 'trace_service.dart';
import 'secure_storage.dart';
import '../utils/logger.dart';

/// 统一 HTTP 客户端
/// 自动添加 TraceId、打印请求/响应日志、敏感信息脱敏
class HttpClient {
  static const Set<String> _sensitiveFields = {
    'password', 'pwd', 'token', 'accessToken', 'refreshToken',
    'secret', 'apiKey', 'Authorization'
  };

  /// 脱敏敏感数据
  static String _maskSensitive(String? body) {
    if (body == null || body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final masked = Map<String, dynamic>.from(decoded);
        for (final field in _sensitiveFields) {
          if (masked.containsKey(field)) {
            masked[field] = '******';
          }
        }
        return jsonEncode(masked);
      }
    } catch (_) {
      // 非 JSON，直接返回
    }
    return body;
  }

  /// 发送 POST 请求
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    String module = 'HTTP',
  }) async {
    final traceService = TraceService();
    final traceId = traceService.currentTraceId ?? traceService.generate();

    final allHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...?headers,
    };

    // 自动添加 Authorization header（仅当用户未传入时）
    if (!allHeaders.containsKey('Authorization')) {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        allHeaders['Authorization'] = 'Bearer $token';
      }
    } else {
      // 如果用户已传入 Authorization header，确保有 Bearer 前缀
      final authValue = allHeaders['Authorization'];
      if (authValue != null && !authValue.startsWith('Bearer ')) {
        allHeaders['Authorization'] = 'Bearer $authValue';
      }
    }

    final bodyStr = body != null ? jsonEncode(body) : null;

    // 打印请求日志
    AppLogger.i('>>> POST ${url.path}', module: module, traceId: traceId);
    AppLogger.d('Headers: $allHeaders, Body: ${_maskSensitive(bodyStr)}', module: module, traceId: traceId);

    final stopwatch = Stopwatch()..start();
    final response = await http.post(url, headers: allHeaders, body: bodyStr);
    stopwatch.stop();

    // 打印响应日志
    AppLogger.i('<<< ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)', module: module, traceId: traceId);
    if (response.statusCode >= 400) {
      AppLogger.e('Response: ${_maskSensitive(response.body)}', module: module, traceId: traceId);
    } else {
      AppLogger.d('Response: ${_maskSensitive(response.body)}', module: module, traceId: traceId);
    }

    return response;
  }

  /// 发送 GET 请求
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    String module = 'HTTP',
  }) async {
    final traceService = TraceService();
    final traceId = traceService.currentTraceId ?? traceService.generate();

    final allHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...?headers,
    };

    // 自动添加 Authorization header（仅当用户未传入时）
    if (!allHeaders.containsKey('Authorization')) {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        allHeaders['Authorization'] = 'Bearer $token';
      }
    } else {
      // 如果用户已传入 Authorization header，确保有 Bearer 前缀
      final authValue = allHeaders['Authorization'];
      if (authValue != null && !authValue.startsWith('Bearer ')) {
        allHeaders['Authorization'] = 'Bearer $authValue';
      }
    }

    // 打印请求日志
    AppLogger.i('>>> GET ${url.path}', module: module, traceId: traceId);

    final stopwatch = Stopwatch()..start();
    final response = await http.get(url, headers: allHeaders);
    stopwatch.stop();

    // 打印响应日志
    AppLogger.i('<<< ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)', module: module, traceId: traceId);
    AppLogger.d('Response: ${_maskSensitive(response.body)}', module: module, traceId: traceId);

    return response;
  }

  /// 发送 DELETE 请求
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    String module = 'HTTP',
  }) async {
    final traceService = TraceService();
    final traceId = traceService.currentTraceId ?? traceService.generate();

    final allHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...?headers,
    };

    // 自动添加 Authorization header（仅当用户未传入时）
    if (!allHeaders.containsKey('Authorization')) {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        allHeaders['Authorization'] = 'Bearer $token';
      }
    } else {
      // 如果用户已传入 Authorization header，确保有 Bearer 前缀
      final authValue = allHeaders['Authorization'];
      if (authValue != null && !authValue.startsWith('Bearer ')) {
        allHeaders['Authorization'] = 'Bearer $authValue';
      }
    }

    // 打印请求日志
    AppLogger.i('>>> DELETE ${url.path}', module: module, traceId: traceId);

    final stopwatch = Stopwatch()..start();
    final response = await http.delete(url, headers: allHeaders);
    stopwatch.stop();

    // 打印响应日志
    AppLogger.i('<<< ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)', module: module, traceId: traceId);

    return response;
  }
}