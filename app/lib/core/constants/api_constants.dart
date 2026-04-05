// app/lib/core/constants/api_constants.dart

class ApiConstants {
  // 基础配置 - 根据环境修改
  static const String baseUrl = 'http://localhost:8080';

  static const String apiPrefix = '/api';
  static const String appApiPrefix = '$apiPrefix/app';

  // 认证相关
  static const String register = '$appApiPrefix/auth/register';
  static const String login = '$appApiPrefix/auth/login';
  static const String logout = '$appApiPrefix/auth/logout';

  // 用户相关
  static const String userProfile = '$appApiPrefix/user/profile';

  // 超时配置
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
