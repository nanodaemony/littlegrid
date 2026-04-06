import 'package:http/http.dart' as http;
import '../services/trace_service.dart';

/// HTTP TraceId 拦截器
/// 自动在请求头中注入 TraceId
class TraceInterceptor {
  /// 拦截请求，添加 TraceId Header
  static http.BaseRequest intercept(http.BaseRequest request) {
    final traceService = TraceService();
    String traceId = traceService.currentTraceId ?? traceService.generate();

    request.headers['X-Trace-Id'] = traceId;
    return request;
  }

  /// 包装 HTTP Client，自动注入 TraceId
  static http.Client wrapClient(http.Client client) {
    return _TraceClient(client);
  }
}

/// 带 TraceId 的 HTTP Client 包装
class _TraceClient extends http.BaseClient {
  final http.Client _inner;

  _TraceClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    TraceInterceptor.intercept(request);
    return _inner.send(request);
  }
}