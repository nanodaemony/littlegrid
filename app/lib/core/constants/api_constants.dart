// app/lib/core/constants/api_constants.dart

class ApiConstants {
  // 基础配置 - 根据环境修改
  // 开发环境使用本地地址，生产环境修改为服务器地址
  static const String baseUrl = 'http://192.168.74.11:8000';

  static const String apiPrefix = '/api';
  static const String appApiPrefix = '$apiPrefix/app';

  // 认证相关
  static const String register = '$appApiPrefix/auth/register';
  static const String login = '$appApiPrefix/auth/login';
  static const String logout = '$appApiPrefix/auth/logout';

  // 用户相关
  static const String userProfile = '$appApiPrefix/user/profile';

  // 树洞相关
  static const String treeholePosts = '$appApiPrefix/treehole/posts';
  static const String treeholeRandomPost = '$appApiPrefix/treehole/posts/random';
  static const String treeholeMyPosts = '$appApiPrefix/treehole/posts/mine';
  static String treeholePostDetail(int id) => '$appApiPrefix/treehole/posts/$id';
  static String treeholePostReplies(int id) => '$appApiPrefix/treehole/posts/$id/replies';
  static String treeholeReplyLike(int id) => '$appApiPrefix/treehole/replies/$id/like';

  // 超时配置
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
