import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/secure_storage.dart';
import '../../core/constants/api_constants.dart';

class FeedbackService {
  static const _baseUrl = '${ApiConstants.baseUrl}/api/feedback';

  static Future<void> submitFeedback({
    required String type,
    required String description,
    List<String>? screenshots,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('请先登录');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({
        'type': type,
        'description': description,
        if (screenshots != null && screenshots.isNotEmpty) 'screenshots': screenshots,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('登录已过期，请重新登录');
    } else {
      throw Exception('提交失败: ${response.body}');
    }
  }
}
