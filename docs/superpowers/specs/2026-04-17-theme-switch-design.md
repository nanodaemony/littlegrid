---
name: 主题切换功能设计
description: 实现卡片背景主题切换功能，包括纯色和背景图片选择
type: spec
---

# 主题切换功能设计

## 概述

在【我的】页面和抽屉页面实现卡片背景主题切换功能，用户可以选择纯色或内置背景图片作为卡片背景。

## 需求

1. 在设置页【外观】下新增【主题】栏目，点击后进入主题页
2. 主题页包含：
   - 顶部预览区：展示跟我的页面顶部卡片一样的样式（大卡片+头像+昵称）
   - 中间纯色区：展示12种纯色选项（8种彩色+4种淡色/灰色）
   - 下部背景图区：展示8张内置背景图（4张渐变+4张实景）
   - 底部保存按钮
3. 实时预览：点击纯色或背景图，顶部预览即时更新
4. 保存后全局生效：【我的】页面和抽屉页的大卡片背景同步更新

## 设计方案

### 1. 数据结构

#### 主题类型枚举

```dart
enum CardBackgroundType {
  solidColor,  // 纯色渐变
  gradient,    // 渐变背景（代码生成）
  image,       // 图片背景
}
```

#### 主题配置模型

```dart
class CardBackground {
  final CardBackgroundType type;
  final String? colorKey;      // 纯色/渐变的key
  final String? assetPath;      // 图片资源路径
  final List<Color>? colors;    // 渐变颜色（临时预览用）

  const CardBackground({
    required this.type,
    this.colorKey,
    this.assetPath,
    this.colors,
  });
}
```

### 2. 状态管理

在 `AppProvider` 中新增：

```dart
class AppProvider extends ChangeNotifier {
  // ... 现有代码 ...

  CardBackground _cardBackground = const CardBackground(
    type: CardBackgroundType.solidColor,
    colorKey: 'default_blue',
  );

  CardBackground get cardBackground => _cardBackground;

  // 临时预览用（不保存）
  CardBackground? _previewBackground;
  CardBackground? get previewBackground => _previewBackground;

  Future<void> loadCardBackground() async {
    // 从 StorageService 读取保存的主题
    final saved = await StorageService.getCardBackground();
    if (saved != null) {
      _cardBackground = saved;
      notifyListeners();
    }
  }

  void setPreviewBackground(CardBackground? background) {
    _previewBackground = background;
    notifyListeners();
  }

  Future<void> saveCardBackground(CardBackground background) async {
    _cardBackground = background;
    _previewBackground = null;
    await StorageService.saveCardBackground(background);
    notifyListeners();
  }
}
```

### 3. 主题常量定义

新建 `app/lib/core/constants/card_theme_constants.dart`：

```dart
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
}
```

### 4. 页面结构

#### 4.1 设置页 (SettingsPage)

在"外观"部分新增"主题"入口：

```dart
// 在深色模式、语言之后添加
_buildMenuItem(
  icon: Icons.palette,
  title: '主题',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ThemePage()),
    );
  },
),
```

#### 4.2 主题选择页 (ThemePage)

新建 `app/lib/pages/theme_page.dart`：

**页面结构：**
```
ThemePage
├── AppBar (标题：主题)
└── ListView (垂直滚动)
    ├── 预览卡片 _buildPreviewCard()
    ├── 纯色部分 _buildSolidColorSection()
    ├── 背景图片部分 _buildBackgroundImageSection()
    └── 保存按钮
```

**核心组件：**

1. **预览卡片**：复用 ProfilePage 的用户卡片样式，根据当前预览状态展示
2. **纯色选择网格**：2列网格，展示12种纯色选项
3. **背景图选择网格**：2列网格，展示8种背景选项（前4个渐变，后4个图片）
4. **保存按钮**：保存当前选择并退出

#### 4.3 卡片背景 Widget

新建可复用的 `CardBackgroundContainer` Widget：

```dart
class CardBackgroundContainer extends StatelessWidget {
  final Widget child;
  final CardBackground background;
  final BorderRadius? borderRadius;

  const CardBackgroundContainer({
    super.key,
    required this.child,
    required this.background,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = _buildDecoration(background);
    return Container(
      decoration: decoration,
      child: child,
    );
  }

  Decoration _buildDecoration(CardBackground bg) {
    switch (bg.type) {
      case CardBackgroundType.solidColor:
      case CardBackgroundType.gradient:
        final colors = _getColors(bg);
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
            image: AssetImage(bg.assetPath!),
            fit: BoxFit.cover,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        );
    }
  }

  List<Color> _getColors(CardBackground bg) {
    if (bg.colors != null) return bg.colors!;
    if (bg.colorKey != null) {
      return CardThemeConstants.solidColors[bg.colorKey] ??
          CardThemeConstants.solidColors['default_blue']!;
    }
    return CardThemeConstants.solidColors['default_blue']!;
  }
}
```

### 5. 更新现有页面

#### 5.1 ProfilePage

将 `_buildUserCard()` 中的硬编码渐变替换为 `CardBackgroundContainer`：

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

#### 5.2 AppDrawer

将 `_buildHeader()` 中的硬编码渐变替换为 `CardBackgroundContainer`：

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

注意：Drawer 的 Header 不需要圆角，传入 `borderRadius: BorderRadius.zero`。

### 6. 存储服务

在 `StorageService` 中新增：

```dart
// 存储key
static const String _keyCardBackground = 'card_background';

// 保存卡片背景
static Future<void> saveCardBackground(CardBackground background) async {
  final prefs = await SharedPreferences.getInstance();
  final json = jsonEncode(background.toJson());
  await prefs.setString(_keyCardBackground, json);
}

// 获取卡片背景
static Future<CardBackground?> getCardBackground() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_keyCardBackground);
  if (json == null) return null;
  try {
    return CardBackground.fromJson(jsonDecode(json));
  } catch (e) {
    return null;
  }
}
```

### 7. 资源文件

需要添加的资源：
```
app/assets/images/card_themes/
├── mountain.jpg    // 山景
├── ocean.jpg       // 海景
├── starry.jpg      // 星空
└── forest.jpg      // 森林
```

在 `pubspec.yaml` 中注册：
```yaml
assets:
  - assets/images/card_themes/
```

## 实现计划

1. 新建主题常量定义 `card_theme_constants.dart`
2. 更新 `CardBackground` 数据模型和 JSON 序列化
3. 更新 `AppProvider`，添加主题状态管理
4. 更新 `StorageService`，添加主题持久化
5. 新建可复用 `CardBackgroundContainer` Widget
6. 新建 `ThemePage` 主题选择页面
7. 更新 `SettingsPage`，添加主题入口
8. 更新 `ProfilePage`，使用主题背景
9. 更新 `AppDrawer`，使用主题背景
10. 添加背景图片资源

## 注意事项

1. **奶白色主题的文字颜色**：当使用奶白色等浅色背景时，卡片内的文字颜色需要自动切换为深色。在 `CardBackgroundContainer` 中可通过 `Theme` 或 `DefaultTextStyle` 处理。

2. **图片资源尺寸**：背景图片建议使用 1080x600 左右尺寸，控制单张图片在 100KB 以内。

3. **初始化时机**：在 `AppProvider.init()` 中调用 `loadCardBackground()` 加载保存的主题。
