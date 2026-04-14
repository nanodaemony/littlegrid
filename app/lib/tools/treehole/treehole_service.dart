import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/services/http_client.dart';
import '../../core/utils/logger.dart';
import 'treehole_models.dart';

/// 树洞 API 服务
class TreeholeService {
  static const String module = 'Treehole';

  /// 随机获取一条树洞
  static Future<TreeholePost?> getRandomPost({String? tag}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholeRandomPost}')
          .replace(queryParameters: tag != null && tag != TreeholeTags.all ? {'tag': tag} : null);
      final response = await HttpClient.get(uri, module: module);

      if (response.statusCode == 204) {
        return null;
      }
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return TreeholePost.fromJson(json);
      }
      throw Exception('获取树洞失败: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('getRandomPost error: $e', module: module);
      rethrow;
    }
  }

  /// 发布树洞
  static Future<TreeholePost> createPost(String content, String tag) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholePosts}');
      final response = await HttpClient.post(
        uri,
        body: {'content': content, 'tag': tag},
        module: module,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return TreeholePost.fromJson(json);
      }
      throw Exception('发布失败: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('createPost error: $e', module: module);
      rethrow;
    }
  }

  /// 获取我的树洞列表
  static Future<List<TreeholePost>> getMyPosts({int page = 0, int size = 20}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholeMyPosts}')
          .replace(queryParameters: {'page': '$page', 'size': '$size'});
      final response = await HttpClient.get(uri, module: module);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final content = json['content'] as List?;
        return content
                ?.map((e) => TreeholePost.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      }
      throw Exception('获取失败: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('getMyPosts error: $e', module: module);
      rethrow;
    }
  }

  /// 获取树洞详情
  static Future<PostDetail> getPostDetail(int id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholePostDetail(id)}');
      final response = await HttpClient.get(uri, module: module);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PostDetail.fromJson(json);
      }
      throw Exception('获取详情失败: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('getPostDetail error: $e', module: module);
      rethrow;
    }
  }

  /// 删除树洞
  static Future<void> deletePost(int id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholePostDetail(id)}');
      final response = await HttpClient.delete(uri, module: module);

      if (response.statusCode != 200) {
        throw Exception('删除失败: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('deletePost error: $e', module: module);
      rethrow;
    }
  }

  /// 发表回复
  static Future<TreeholeReply> createReply(int postId, String content, {int? parentId}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholePostReplies(postId)}');
      final body = <String, dynamic>{'content': content};
      if (parentId != null) {
        body['parentId'] = parentId;
      }
      final response = await HttpClient.post(uri, body: body, module: module);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return TreeholeReply.fromJson(json);
      }
      throw Exception('回复失败: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('createReply error: $e', module: module);
      rethrow;
    }
  }

  /// 点赞回复
  static Future<LikeResult> likeReply(int id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholeReplyLike(id)}');
      final response = await HttpClient.post(uri, module: module);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LikeResult.fromJson(json);
      }
      throw Exception('点赞失败: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('likeReply error: $e', module: module);
      rethrow;
    }
  }

  /// 取消点赞
  static Future<LikeResult> unlikeReply(int id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.treeholeReplyLike(id)}');
      final response = await HttpClient.delete(uri, module: module);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LikeResult.fromJson(json);
      }
      throw Exception('取消点赞失败: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('unlikeReply error: $e', module: module);
      rethrow;
    }
  }
}
