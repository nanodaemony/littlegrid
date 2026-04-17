import 'package:flutter/material.dart';
import '../models/card_background.dart';

class CardThemeConstants {
  CardThemeConstants._();

  // 默认主题
  static const CardBackground defaultBackground = CardBackground(
    type: CardBackgroundType.solidColor,
    colorKey: 'default_blue',
  );

  // 纯色渐变主题（12种）
  static const Map<String, List<Color>> solidColors = {
    // 彩色系（8种）
    'default_blue': [Color(0xFF5B9BD5), Color(0xFF2E5C8A)],
    'sage_green': [Color(0xFF6B9F6B), Color(0xFF4A7A4A)],
    'caramel': [Color(0xFFD4956A), Color(0xFFA66B3D)],
    'lavender': [Color(0xFF9B7BB8), Color(0xFF6F4E91)],
    'rose_red': [Color(0xFFC97B7B), Color(0xFF9A4F4F)],
    'slate_blue': [Color(0xFF7094A8), Color(0xFF4A6F83)],
    'khaki': [Color(0xFFB5A87C), Color(0xFF8A7D4E)],
    'dark_purple': [Color(0xFF8B8BAE), Color(0xFF5F5F87)],

    // 淡色/灰色系（4种）
    'cream_white': [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
    'light_gray': [Color(0xFFDEE2E6), Color(0xFFADB5BD)],
    'medium_gray': [Color(0xFFADB5BD), Color(0xFF6C757D)],
    'dark_gray': [Color(0xFF495057), Color(0xFF212529)],
  };

  // 判断是否是浅色背景（需要深色文字）
  static bool isLightBackground(String colorKey) {
    return colorKey == 'cream_white' || colorKey == 'light_gray';
  }

  // 渐变背景（4种，代码生成）
  static const Map<String, List<Color>> gradientColors = {
    'sunset': [Color(0xFF667eea), Color(0xFF764ba2)],
    'pink_sky': [Color(0xFFf093fb), Color(0xFFf5576c)],
    'ocean': [Color(0xFF4facfe), Color(0xFF00f2fe)],
    'mint': [Color(0xFF43e97b), Color(0xFF38f9d7)],
  };

  // 实景图片背景（4种，资源文件）
  static const List<String> imageAssets = [
    'assets/images/card_themes/mountain.jpg',
    'assets/images/card_themes/ocean.jpg',
    'assets/images/card_themes/starry.jpg',
    'assets/images/card_themes/forest.jpg',
  ];

  // 获取所有纯色选项
  static List<CardBackground> get allSolidColors {
    return solidColors.entries.map((entry) {
      return CardBackground(
        type: CardBackgroundType.solidColor,
        colorKey: entry.key,
        colors: entry.value,
      );
    }).toList();
  }

  // 获取所有渐变选项
  static List<CardBackground> get allGradients {
    return gradientColors.entries.map((entry) {
      return CardBackground(
        type: CardBackgroundType.gradient,
        colorKey: entry.key,
        colors: entry.value,
      );
    }).toList();
  }

  // 获取所有图片选项
  static List<CardBackground> get allImages {
    return imageAssets.map((path) {
      return CardBackground(
        type: CardBackgroundType.image,
        assetPath: path,
      );
    }).toList();
  }

  // 获取渐变颜色
  static List<Color> getColors(CardBackground bg) {
    if (bg.colors != null) return bg.colors!;
    if (bg.colorKey != null) {
      if (solidColors.containsKey(bg.colorKey)) {
        return solidColors[bg.colorKey]!;
      }
      if (gradientColors.containsKey(bg.colorKey)) {
        return gradientColors[bg.colorKey]!;
      }
    }
    return solidColors['default_blue']!;
  }
}
