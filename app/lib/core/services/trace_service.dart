import 'package:flutter/foundation.dart';

/// TraceId 管理服务
/// 用于生成和管理跨端追踪的 TraceId
class TraceService extends ChangeNotifier {
  static final TraceService _instance = TraceService._internal();
  factory TraceService() => _instance;
  TraceService._internal();

  /// 当前活跃的 TraceId
  String? _currentTraceId;

  /// 获取当前 TraceId
  String? get currentTraceId => _currentTraceId;

  /// 生成新的 TraceId（8位随机字符串）
  String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    final prefix = (timestamp % 100).toString().padLeft(2, '0');
    _currentTraceId = '$prefix$random';
    notifyListeners();
    return _currentTraceId!;
  }

  /// 设置 TraceId（从 HTTP Header 获取）
  void setTraceId(String? traceId) {
    _currentTraceId = traceId;
    notifyListeners();
  }

  /// 清除 TraceId
  void clear() {
    _currentTraceId = null;
    notifyListeners();
  }
}