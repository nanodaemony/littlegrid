# 主题切换功能 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现卡片背景主题切换功能，用户可以选择12种纯色或8种背景图片，实时预览并在【我的】页面和抽屉页面生效

**Architecture:** 新建 CardBackground 数据模型，在 AppProvider 中管理主题状态，使用 CardBackgroundContainer 可复用 Widget 来统一渲染背景，通过 StorageService 持久化用户选择

**Tech Stack:** Flutter, Provider, sqflite (数据库存储)

---

## 文件结构

| 文件 | 操作 | 说明 |
|------|------|------|
| `app/lib/core/models/card_background.dart` | Create | 主题数据模型 |
| `app/lib/core/constants/card_theme_constants.dart` | Create | 主题常量定义（颜色、图片资源） |
| `app/lib/widgets/card_background_container.dart` | Create | 可复用的卡片背景容器 Widget |
| `app/lib/pages/theme_page.dart` | Create | 主题选择页面 |
| `app/lib/providers/app_provider.dart` | Modify | 添加主题状态管理 |
| `app/lib/core/services/storage_service.dart` | Modify | 添加主题持久化方法 |
| `app/lib/pages/settings_page.dart` | Modify | 添加主题入口 |
| `app/lib/pages/profile_page.dart` | Modify | 使用主题背景 |
| `app/lib/widgets/app_drawer.dart` | Modify | 使用主题背景 |
| `app/pubspec.yaml` | Modify | 注册资源文件 |
| `app/assets/images/card_themes/` | Create | 背景图片资源目录 |

---

### Task 1: 新建 CardBackground 数据模型

**Files:**
- Create: `app/lib/core/models/card_background.dart`

- [ ] **Step 1: 创建模型文件**

```dart
import 'package:flutter/material.dart';

enum CardBackgroundType {
  solidColor,
  gradient,
  image,
}

class CardBackground {
  final CardBackgroundType type;
  final String? colorKey;
  final String? assetPath;
  final List<Color>? colors;

  const CardBackground({
    required this.type,
    this.colorKey,
    this.assetPath,
    this.colors,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'colorKey': colorKey,
      'assetPath': assetPath,
    };
  }

  factory CardBackground.fromMap(Map<String, dynamic> map) {
    return CardBackground(
      type: CardBackgroundType.values[map['type'] as int],
      colorKey: map['colorKey'] as String?,
      assetPath: map['assetPath'] as String?,
    );
  }

  CardBackground copyWith({
    CardBackgroundType? type,
    String? colorKey,
    String? assetPath,
    List<Color>? colors,
  }) {
    return CardBackground(
      type: type ?? this.type,
      colorKey: colorKey ?? this.colorKey,
      assetPath: assetPath ?? this.assetPath,
      colors: colors ?? this.colors,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardBackground &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          colorKey == other.colorKey &&
          assetPath == other.assetPath;

  @override
  int get hashCode => type.hashCode ^ colorKey.hashCode ^ assetPath.hashCode;
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/core/models/card_background.dart
git commit -m "feat: add CardBackground model"
```

---

### Task 2: 新建主题常量定义

**Files:**
- Create: `app/lib/core/constants/card_theme_constants.dart`

- [ ] **Step 1: 创建常量文件**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/core/constants/card_theme_constants.dart
git commit -m "feat: add card theme constants"
```

---

### Task 3: 更新 StorageService 添加主题持久化

**Files:**
- Modify: `app/lib/core/services/storage_service.dart`

- [ ] **Step 1: 导入模型**

在文件顶部添加：

```dart
import '../models/card_background.dart';
```

- [ ] **Step 2: 添加主题存储方法**

在文件末尾（`remove` 方法之后）添加：

```dart
  // 卡片背景主题管理
  static const String _cardBackgroundKey = 'card_background';

  static Future<void> saveCardBackground(CardBackground background) async {
    final map = background.toMap();
    // 将 map 序列化为 JSON 字符串存储
    final jsonStr = _encodeBackgroundMap(map);
    await setString(_cardBackgroundKey, jsonStr);
  }

  static Future<CardBackground?> getCardBackground() async {
    final jsonStr = await getString(_cardBackgroundKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = _decodeBackgroundMap(jsonStr);
      return CardBackground.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  // 简单的 JSON 序列化（避免引入额外依赖）
  static String _encodeBackgroundMap(Map<String, dynamic> map) {
    final type = map['type'] as int;
    final colorKey = map['colorKey'] as String? ?? '';
    final assetPath = map['assetPath'] as String? ?? '';
    return '$type|$colorKey|$assetPath';
  }

  static Map<String, dynamic> _decodeBackgroundMap(String str) {
    final parts = str.split('|');
    return {
      'type': int.parse(parts[0]),
      'colorKey': parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
      'assetPath': parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
    };
  }
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/core/services/storage_service.dart
git commit -m "feat: add card background storage"
```

---

### Task 4: 更新 AppProvider 添加主题状态管理

**Files:**
- Modify: `app/lib/providers/app_provider.dart`

- [ ] **Step 1: 导入依赖**

在文件顶部添加：

```dart
import '../core/models/card_background.dart';
import '../core/constants/card_theme_constants.dart';
import '../core/services/storage_service.dart';
```

- [ ] **Step 2: 添加主题状态**

在 `AppProvider` 类中，在 `_avatarPath` 后面添加：

```dart
  CardBackground _cardBackground = CardThemeConstants.defaultBackground;
  CardBackground? _previewBackground;

  CardBackground get cardBackground => _cardBackground;
  CardBackground? get previewBackground => _previewBackground;
```

- [ ] **Step 3: 在 init() 中加载主题**

在 `init()` 方法中，在 `await loadAvatar();` 后面添加：

```dart
    await loadCardBackground();
```

- [ ] **Step 4: 添加主题管理方法**

在 `updateAvatar` 方法后面添加：

```dart
  /// 加载卡片背景
  Future<void> loadCardBackground() async {
    try {
      final saved = await StorageService.getCardBackground();
      if (saved != null) {
        _cardBackground = saved;
        notifyListeners();
      }
    } catch (e, stack) {
      AppLogger.e('Failed to load card background', error: e, stackTrace: stack);
    }
  }

  /// 设置预览背景（不保存）
  void setPreviewBackground(CardBackground? background) {
    _previewBackground = background;
    notifyListeners();
  }

  /// 保存卡片背景
  Future<void> saveCardBackground(CardBackground background) async {
    try {
      await StorageService.saveCardBackground(background);
      _cardBackground = background;
      _previewBackground = null;
      notifyListeners();
    } catch (e, stack) {
      AppLogger.e('Failed to save card background', error: e, stackTrace: stack);
    }
  }
```

- [ ] **Step 5: Commit**

```bash
git add app/lib/providers/app_provider.dart
git commit -m "feat: add card background state management"
```

---

### Task 5: 新建 CardBackgroundContainer 可复用 Widget

**Files:**
- Create: `app/lib/widgets/card_background_container.dart`

- [ ] **Step 1: 创建 Widget 文件**

```dart
import 'package:flutter/material.dart';
import '../core/models/card_background.dart';
import '../core/constants/card_theme_constants.dart';

class CardBackgroundContainer extends StatelessWidget {
  final Widget child;
  final CardBackground background;
  final BorderRadius? borderRadius;
  final bool useLightText; // 强制使用浅色文字

  const CardBackgroundContainer({
    super.key,
    required this.child,
    required this.background,
    this.borderRadius,
    this.useLightText = true,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = _buildDecoration();
    final needsDarkText = _needsDarkText();

    return Container(
      decoration: decoration,
      child: DefaultTextStyle(
        style: TextStyle(
          color: needsDarkText ? const Color(0xFF333333) : Colors.white,
        ),
        child: IconTheme(
          data: IconThemeData(
            color: needsDarkText ? const Color(0xFF333333) : Colors.white,
          ),
          child: child,
        ),
      ),
    );
  }

  bool _needsDarkText() {
    if (!useLightText) return false;
    if (background.type == CardBackgroundType.image) return false;
    if (background.type == CardBackgroundType.gradient) return false;
    if (background.colorKey != null) {
      return CardThemeConstants.isLightBackground(background.colorKey!);
    }
    return false;
  }

  Decoration _buildDecoration() {
    switch (background.type) {
      case CardBackgroundType.solidColor:
      case CardBackgroundType.gradient:
        final colors = CardThemeConstants.getColors(background);
        return BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withAlpha((0.3 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        );
      case CardBackgroundType.image:
        return BoxDecoration(
          image: DecorationImage(
            image: AssetImage(background.assetPath!),
            fit: BoxFit.cover,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        );
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/widgets/card_background_container.dart
git commit -m "feat: add CardBackgroundContainer widget"
```

---

### Task 6: 新建 ThemePage 主题选择页面

**Files:**
- Create: `app/lib/pages/theme_page.dart`

- [ ] **Step 1: 创建主题页面文件**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ui/app_colors.dart';
import '../core/models/card_background.dart';
import '../core/constants/card_theme_constants.dart';
import '../widgets/card_background_container.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar_picker.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  bool _isSaving = false;

  Widget _buildAvatar(String? avatarPath) {
    if (avatarPath == null || AvatarPicker.isDefaultAvatar(avatarPath)) {
      final color = AvatarPicker.getDefaultAvatarColor(avatarPath);
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 48,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: Image.file(
          File(avatarPath),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 48,
              color: AppColors.primary,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final isLoggedIn = authProvider.isLoggedIn;
            final user = authProvider.currentUser;
            final background = appProvider.previewBackground ?? appProvider.cardBackground;

            return CardBackgroundContainer(
              background: background,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildAvatar(appProvider.avatarPath),
                    const SizedBox(height: 16),
                    if (isLoggedIn && user != null)
                      Text(
                        user.nickname ?? '用户',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        '用户昵称',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSolidColorSection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final currentBg = appProvider.previewBackground ?? appProvider.cardBackground;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                '纯色主题',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: CardThemeConstants.allSolidColors.length,
                itemBuilder: (context, index) {
                  final bg = CardThemeConstants.allSolidColors[index];
                  final isSelected = currentBg.type == bg.type && currentBg.colorKey == bg.colorKey;
                  final colors = CardThemeConstants.getColors(bg);

                  return GestureDetector(
                    onTap: () {
                      appProvider.setPreviewBackground(bg);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 3)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundImageSection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final currentBg = appProvider.previewBackground ?? appProvider.cardBackground;
        final allOptions = [
          ...CardThemeConstants.allGradients,
          ...CardThemeConstants.allImages,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                '背景图片',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: allOptions.length,
                itemBuilder: (context, index) {
                  final bg = allOptions[index];
                  final isSelected = _isBackgroundEqual(currentBg, bg);

                  return GestureDetector(
                    onTap: () {
                      appProvider.setPreviewBackground(bg);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 3)
                            : null,
                      ),
                      child: _buildOptionPreview(bg),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isBackgroundEqual(CardBackground a, CardBackground b) {
    if (a.type != b.type) return false;
    if (a.type == CardBackgroundType.image) {
      return a.assetPath == b.assetPath;
    }
    return a.colorKey == b.colorKey;
  }

  Widget _buildOptionPreview(CardBackground bg) {
    if (bg.type == CardBackgroundType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          child: Center(
            child: Icon(
              Icons.image,
              color: Colors.grey[600],
              size: 32,
            ),
          ),
        ),
      );
    }

    final colors = CardThemeConstants.getColors(bg);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final appProvider = context.read<AppProvider>();
      final selectedBg = appProvider.previewBackground;

      if (selectedBg != null) {
        // 清除临时颜色，只保存 key
        final bgToSave = selectedBg.copyWith(colors: null);
        await appProvider.saveCardBackground(bgToSave);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPreviewCard(),
                _buildSolidColorSection(),
                _buildBackgroundImageSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '保存',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/pages/theme_page.dart
git commit -m "feat: add theme selection page"
```

---

### Task 7: 更新 SettingsPage 添加主题入口

**Files:**
- Modify: `app/lib/pages/settings_page.dart`

- [ ] **Step 1: 导入主题页面**

在文件顶部添加：

```dart
import 'theme_page.dart';
```

- [ ] **Step 2: 添加主题菜单项**

在 `_buildMenuItem` 语言项后面（第43行后面）添加：

```dart
          _buildMenuItem(
            icon: Icons.palette,
            title: '主题',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemePage(),
                ),
              );
            },
          ),
```

注意：确保在 "外观" section 内，在深色模式和语言之后添加。

- [ ] **Step 3: Commit**

```bash
git add app/lib/pages/settings_page.dart
git commit -m "feat: add theme entry in settings"
```

---

### Task 8: 更新 ProfilePage 使用主题背景

**Files:**
- Modify: `app/lib/pages/profile_page.dart`

- [ ] **Step 1: 导入依赖**

在文件顶部添加：

```dart
import '../core/models/card_background.dart';
import '../core/constants/card_theme_constants.dart';
import '../widgets/card_background_container.dart';
```

- [ ] **Step 2: 修改 _buildUserCard() 方法**

将整个 `_buildUserCard()` 方法替换为：

```dart
  Widget _buildUserCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final isLoggedIn = authProvider.isLoggedIn;
            final user = authProvider.currentUser;

            return CardBackgroundContainer(
              background: appProvider.cardBackground,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 头像
                    _buildAvatar(appProvider.avatarPath),

                    const SizedBox(height: 16),

                    // 昵称或登录按钮
                    if (isLoggedIn && user != null)
                      _buildLoggedInUser(user)
                    else
                      _buildLoginButton(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
```

- [ ] **Step 3: 更新文字颜色**

找到 `_buildLoggedInUser()` 方法（约179行），移除硬编码的白色：

```dart
  Widget _buildLoggedInUser(User user) {
    return Column(
      children: [
        Text(
          user.nickname ?? '用户',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
```

注意：删除 `color: Colors.white,`，让 CardBackgroundContainer 自动控制文字颜色。

- [ ] **Step 4: 更新 _buildLoginButton()**

如果需要，确保登录按钮的样式与浅色背景兼容，但登录按钮本身是白色背景，应该没问题。保持现状即可。

- [ ] **Step 5: Commit**

```bash
git add app/lib/pages/profile_page.dart
git commit -m "feat: use theme background in profile page"
```

---

### Task 9: 更新 AppDrawer 使用主题背景

**Files:**
- Modify: `app/lib/widgets/app_drawer.dart`

- [ ] **Step 1: 导入依赖**

在文件顶部添加：

```dart
import '../core/models/card_background.dart';
import '../core/constants/card_theme_constants.dart';
import 'card_background_container.dart';
```

- [ ] **Step 2: 修改 _buildHeader() 方法**

将整个 `_buildHeader()` 方法替换为：

```dart
  Widget _buildHeader() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return CardBackgroundContainer(
          background: provider.cardBackground,
          borderRadius: BorderRadius.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAvatar(provider.avatarPath),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/widgets/app_drawer.dart
git commit -m "feat: use theme background in app drawer"
```

---

### Task 10: 创建资源目录和占位图片

**Files:**
- Create: `app/assets/images/card_themes/.gitkeep`
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: 创建资源目录**

```bash
mkdir -p app/assets/images/card_themes
touch app/assets/images/card_themes/.gitkeep
```

- [ ] **Step 2: 检查 pubspec.yaml**

先读取现有文件，看是否已有 assets 配置：

```bash
grep -A 10 "assets:" app/pubspec.yaml || echo "No assets section yet"
```

- [ ] **Step 3: 更新 pubspec.yaml**

在 `flutter:` 部分添加 assets 配置（如果还没有的话）：

```yaml
  assets:
    - assets/images/card_themes/
```

注意缩进要正确（2个空格或根据现有格式）。

- [ ] **Step 4: 添加4张渐变占位图说明**

由于实景图片需要用户自行准备，我们先添加一个说明：

创建 `app/assets/images/card_themes/README.md`：

```
# 卡片背景图片

请在此目录下放置以下4张实景图片：

- mountain.jpg - 山景
- ocean.jpg - 海景
- starry.jpg - 星空
- forest.jpg - 森林

建议尺寸：1080x600 像素
建议大小：单张 < 100KB
```

- [ ] **Step 5: Commit**

```bash
git add app/assets/images/card_themes/.gitkeep
git add app/assets/images/card_themes/README.md
git add app/pubspec.yaml
git commit -m "feat: add card theme assets directory"
```

---

## 实现验证

执行完所有任务后，验证以下功能：

- [ ] 从设置页 → 外观 → 主题可以进入主题页
- [ ] 主题页顶部显示预览卡片
- [ ] 点击12种纯色选项，预览即时更新
- [ ] 点击8种背景图片选项，预览即时更新
- [ ] 点击保存，退出页面
- [ ] 【我的】页面的卡片背景更新为所选主题
- [ ] 抽屉页的头部背景更新为所选主题
- [ ] 重启APP后，主题设置依然保留

## 注意事项

1. **实景图片**：Task 10 只创建了目录结构，实际的4张实景图片（mountain.jpg, ocean.jpg, starry.jpg, forest.jpg）需要用户自行添加
2. **浅色背景文字**：CardBackgroundContainer 已自动处理浅色背景下文字切换为深色
3. **图片预览**：ThemePage 中的图片选项暂时显示占位图标，等实际图片资源添加后会正常显示
