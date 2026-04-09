import 'package:flutter/material.dart';

/// 2048 游戏数字颜色配置
class Game2048Colors {
  Game2048Colors._();

  /// 获取数字对应的背景色
  static Color getBackgroundColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFFF5F5F5);
      case 4:
        return const Color(0xFFE8F4F8);
      case 8:
        return const Color(0xFFD4E9F7);
      case 16:
        return const Color(0xFFBDD7EE);
      case 32:
        return const Color(0xFF9FC5E8);
      case 64:
        return const Color(0xFF5B9BD5);
      case 128:
        return const Color(0xFF2E5C8A);
      case 256:
        return const Color(0xFF1E3A5F);
      case 512:
        return const Color(0xFF4A3F8C);
      case 1024:
        return const Color(0xFF6B4C7A);
      case 2048:
        return const Color(0xFF8B4513);
      case 4096:
        return const Color(0xFFB8860B);
      case 8192:
        return const Color(0xFFDAA520);
      case 16384:
        return const Color(0xFFFFD700);
      default:
        // 更大的数字使用计算渐变色
        if (value > 16384) {
          return const Color(0xFFFFD700); // 金色
        }
        return const Color(0xFFF5F5F5);
    }
  }

  /// 获取数字对应的文字颜色
  static Color getTextColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFF666666);
      case 4:
        return const Color(0xFF5B9BD5);
      case 8:
        return const Color(0xFF2E5C8A);
      case 16:
      case 32:
      case 64:
      case 128:
      case 256:
      case 512:
      case 1024:
      case 2048:
      case 4096:
      case 8192:
        return Colors.white;
      case 16384:
      default:
        // 更大的数字使用深色文字
        if (value > 16384) {
          return const Color(0xFF333333);
        }
        return const Color(0xFF666666);
    }
  }

  /// 获取数字对应的字体大小
  static double getFontSize(int value) {
    if (value < 100) {
      return 32;
    } else if (value < 1000) {
      return 28;
    } else if (value < 10000) {
      return 24;
    } else {
      return 20;
    }
  }

  /// 棋盘背景色
  static const Color boardBackground = Color(0xFFBBADA0);

  /// 空格子背景色
  static const Color emptyTile = Color(0xFFCDC1B4);

  /// 分数卡片背景色
  static const Color scoreCardBackground = Color(0xFF5B9BD5);

  /// 分数卡片文字色
  static const Color scoreCardText = Colors.white;
}
