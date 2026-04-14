# 像素画生成器设计文档

**日期:** 2026-04-14
**作者:** Claude
**状态:** 待审核

## 概述

在小方格应用中新增"像素画生成器"功能格子，用户可以从相册选择照片，将其转换为像素风格图像，支持多种复古滤镜风格，调整像素大小和颜色数量，并保存到相册。

## 需求背景

- 用户需要将普通照片转换为复古像素风格
- 提供多种经典游戏主机的调色板滤镜
- 支持自定义像素化程度和颜色数量
- 纯本地处理，无需上传到服务器
- 丰富小方格应用的图像类工具

## 功能需求

### 核心功能

1. **图片选择**
   - 从相册选择图片
   - 支持常见图片格式（JPG、PNG等）

2. **像素化处理**
   - 可调像素块大小（范围：1-32）
   - 可调颜色数量（范围：2-256）
   - 实时预览处理效果

3. **滤镜风格**
   - 8位风格（256色自适应）
   - 16位风格（65536色）
   - Game Boy（4灰阶）
   - NES（52色固定调色板）
   - Sega Genesis（64色固定调色板）
   - Commodore 64（16色固定调色板）
   - 像素素描（黑白边缘效果）

4. **导出保存**
   - 保存处理后的图片到相册
   - 保持原图片分辨率

### 非功能需求

- 性能：预览使用缩略图处理，保证流畅性
- 可用性：界面简洁，操作直观
- 纯前端：无需后端，所有处理本地完成

## 技术方案

### 架构设计

**模块位置:**
- 前端: `app/lib/tools/pixel_art/`

### 依赖新增

在 `app/pubspec.yaml` 中新增：
```yaml
image: ^4.0.17  # 用于图像处理
```

### 前端设计

#### 新增文件结构

```
app/lib/tools/pixel_art/
├── pixel_art_tool.dart          # 工具注册
├── pixel_art_page.dart          # 主页面
├── pixel_art_processor.dart     # 图像处理核心逻辑
├── pixel_art_filters.dart       # 滤镜预设定义
└── widgets/
    ├── pixel_preview.dart       # 像素化预览组件
    ├── filter_selector.dart     # 滤镜选择器
    └── control_slider.dart      # 参数滑块组件
```

#### 页面说明

**主页面 (pixel_art_page.dart)**

```
┌─────────────────────────┐
│   像素画生成器          │ ← AppBar
├─────────────────────────┤
│                         │
│   ┌───────────────┐    │
│   │               │    │
│   │  图片预览区   │    │ ← 显示原图/效果图切换
│   │               │    │
│   └───────────────┘    │
│         [原图/效果图]   │ ← 切换按钮
│                         │
├─────────────────────────┤
│  滤镜风格               │ ← 横向滚动滤镜选择
│  [8位][16位][GB][NES]  │
├─────────────────────────┤
│  像素大小: [||||||] 16 │ ← 滑块 (1-32)
│  颜色数量: [||||||] 32 │ ← 滑块 (2-256，部分滤镜禁用)
├─────────────────────────┤
│  [选择图片]  [保存]     │ ← 底部操作按钮
└─────────────────────────┘
```

**交互流程：**
1. 初始状态：显示占位图 + "选择图片"按钮
2. 选择图片后：显示预览，默认使用 8位 滤镜
3. 调整参数：实时更新预览（使用缩略图以保证流畅）
4. 保存：处理全图并写入相册

#### 滤镜预设定义 (pixel_art_filters.dart)

```dart
enum PixelFilterType {
  eightBit,        // 8位 (256色自适应)
  sixteenBit,      // 16位 (65536色)
  gameBoy,         // Game Boy (4灰阶)
  nes,             // NES (52色)
  segaGenesis,     // Sega Genesis (64色)
  commodore64,     // Commodore 64 (16色)
  pixelSketch,     // 像素素描 (黑白边缘)
}

class PixelFilter {
  final String name;
  final List<Color>? palette;  // 固定调色板，null表示使用自适应
  final int defaultColorCount;
  final bool isGrayscale;
  final bool allowsColorCountAdjustment;

  PixelFilter({
    required this.name,
    this.palette,
    required this.defaultColorCount,
    this.isGrayscale = false,
    this.allowsColorCountAdjustment = true,
  });
}

class PixelArtFilters {
  static final Map<PixelFilterType, PixelFilter> filters = {
    PixelFilterType.eightBit: PixelFilter(
      name: '8位',
      defaultColorCount: 256,
      allowsColorCountAdjustment: true,
    ),
    PixelFilterType.sixteenBit: PixelFilter(
      name: '16位',
      defaultColorCount: 256,
      allowsColorCountAdjustment: true,
    ),
    PixelFilterType.gameBoy: PixelFilter(
      name: 'Game Boy',
      palette: [
        Color(0xFF0F380F),
        Color(0xFF306230),
        Color(0xFF8BAC0F),
        Color(0xFF9BBC0F),
      ],
      defaultColorCount: 4,
      isGrayscale: true,
      allowsColorCountAdjustment: false,
    ),
    PixelFilterType.nes: PixelFilter(
      name: 'NES',
      palette: _nesPalette,
      defaultColorCount: 52,
      allowsColorCountAdjustment: false,
    ),
    PixelFilterType.segaGenesis: PixelFilter(
      name: 'Sega Genesis',
      palette: _segaGenesisPalette,
      defaultColorCount: 64,
      allowsColorCountAdjustment: false,
    ),
    PixelFilterType.commodore64: PixelFilter(
      name: 'Commodore 64',
      palette: _commodore64Palette,
      defaultColorCount: 16,
      allowsColorCountAdjustment: false,
    ),
    PixelFilterType.pixelSketch: PixelFilter(
      name: '像素素描',
      defaultColorCount: 2,
      isGrayscale: true,
      allowsColorCountAdjustment: false,
    ),
  };

  static PixelFilter get(PixelFilterType type) => filters[type]!;
}
```

**调色板定义说明：**
- Game Boy: 经典的4种绿色调
- NES: 52色标准调色板
- Sega Genesis: 64色（9位RGB，3位/通道）
- Commodore 64: 16色固定调色板

#### 图像处理核心 (pixel_art_processor.dart)

```dart
class PixelArtProcessor {
  static final PixelArtProcessor instance = PixelArtProcessor._();
  PixelArtProcessor._();

  /// 主处理入口 - 处理全图（用于保存）
  Future<ui.Image> processImage({
    required ui.Image original,
    required int pixelSize,
    required int colorCount,
    required PixelFilterType filterType,
  }) async {
    final filter = PixelArtFilters.get(filterType);

    // 1. 将 ui.Image 转换为 image 包的 Image
    final image = await _convertUiImageToImage(original);

    // 2. 应用滤镜处理
    Image processed;
    if (filterType == PixelFilterType.pixelSketch) {
      processed = _applyPixelSketch(image, pixelSize);
    } else {
      processed = _applyPixelFilter(
        image,
        pixelSize,
        colorCount,
        filter,
      );
    }

    // 3. 转换回 ui.Image
    return _convertImageToUiImage(processed);
  }

  /// 处理预览图（缩小版本，更快）
  Future<ui.Image> processPreview({
    required ui.Image original,
    required int pixelSize,
    required int colorCount,
    required PixelFilterType filterType,
  }) async {
    // 先缩放到最大边长512px
    final scaled = await _scaleDownImage(original, maxSize: 512);
    return processImage(
      original: scaled,
      pixelSize: pixelSize,
      colorCount: colorCount,
      filterType: filterType,
    );
  }

  /// 像素滤镜处理
  Image _applyPixelFilter(
    Image image,
    int pixelSize,
    int colorCount,
    PixelFilter filter,
  ) {
    // 步骤1: 降采样
    final downscaled = _downscale(image, pixelSize);

    // 步骤2: 颜色量化
    Image quantized;
    if (filter.palette != null) {
      quantized = _applyFixedPalette(downscaled, filter.palette!);
    } else {
      quantized = _quantizeColors(downscaled, colorCount, filter.isGrayscale);
    }

    // 步骤3: 放大回原尺寸（最近邻插值）
    return _upscale(quantized, image.width, image.height);
  }

  /// 像素素描滤镜
  Image _applyPixelSketch(Image image, int pixelSize) {
    // 1. 转灰度
    final grayscale = image.grayscale();

    // 2. 降采样
    final downscaled = _downscale(grayscale, pixelSize);

    // 3. 边缘检测（Sobel算子）
    final edges = _detectEdges(downscaled);

    // 4. 二值化
    final binary = _binarize(edges, threshold: 30);

    // 5. 放大回原尺寸
    return _upscale(binary, image.width, image.height);
  }

  /// 降采样（按像素块大小）
  Image _downscale(Image image, int pixelSize) {
    final newWidth = (image.width / pixelSize).floor();
    final newHeight = (image.height / pixelSize).floor();
    return copyResize(image, width: newWidth, height: newHeight);
  }

  /// 放大（最近邻插值，保持像素感）
  Image _upscale(Image image, int targetWidth, int targetHeight) {
    return copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: Interpolation.nearest,
    );
  }

  /// 使用中位切分算法进行颜色量化
  Image _quantizeColors(Image image, int colorCount, bool isGrayscale) {
    // 实现中位切分算法
    // ...
  }

  /// 应用固定调色板
  Image _applyFixedPalette(Image image, List<Color> palette) {
    // 将每个像素映射到最近的调色板颜色
    // ...
  }

  /// 边缘检测
  Image _detectEdges(Image image) {
    // Sobel算子实现
    // ...
  }

  /// 二值化
  Image _binarize(Image image, {required int threshold}) {
    // ...
  }

  /// ui.Image 转换为 image包的Image
  Future<Image> _convertUiImageToImage(ui.Image uiImage) async {
    // ...
  }

  /// image包的Image 转换为 ui.Image
  Future<ui.Image> _convertImageToUiImage(Image image) async {
    // ...
  }

  /// 缩小图片
  Future<ui.Image> _scaleDownImage(ui.Image image, {required int maxSize}) async {
    // ...
  }
}
```

#### 主页面状态管理 (pixel_art_page.dart)

```dart
class PixelArtPage extends StatefulWidget {
  const PixelArtPage({super.key});

  @override
  State<PixelArtPage> createState() => _PixelArtPageState();
}

class _PixelArtPageState extends State<PixelArtPage> {
  ui.Image? _originalImage;
  ui.Image? _processedImage;
  bool _showOriginal = false;

  PixelFilterType _selectedFilter = PixelFilterType.eightBit;
  int _pixelSize = 16;
  int _colorCount = 32;

  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _originalImage = frame.image;
    });

    await _updatePreview();
  }

  Future<void> _updatePreview() async {
    if (_originalImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final processed = await PixelArtProcessor.instance.processPreview(
        original: _originalImage!,
        pixelSize: _pixelSize,
        colorCount: _colorCount,
        filterType: _selectedFilter,
      );

      setState(() => _processedImage = processed);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveImage() async {
    if (_originalImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final processed = await PixelArtProcessor.instance.processImage(
        original: _originalImage!,
        pixelSize: _pixelSize,
        colorCount: _colorCount,
        filterType: _selectedFilter,
      );

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pixel_art_${DateTime.now().millisecondsSinceEpoch}.png');

      // 将 ui.Image 编码为 PNG
      final byteData = await processed.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(byteData!.buffer.asUint8List());

      // 保存到相册
      await Gal.putImage(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到相册')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 构建
    // ...
  }
}
```

#### 工具注册 (pixel_art_tool.dart)

```dart
class PixelArtTool implements ToolModule {
  @override
  String get id => 'pixel_art';

  @override
  String get name => '像素画生成器';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.palette;

  @override
  ToolCategory get category => ToolCategory.life;

  @override
  int get gridSize => 1;

  @override
  Widget buildPage(BuildContext context) => const PixelArtPage();

  @override
  ToolSettings? get settings => null;

  @override
  Future<void> onInit() async {}

  @override
  Future<void> onDispose() async {}

  @override
  void onEnter() {}

  @override
  void onExit() {}
}
```

## 实施计划

1. 在 `pubspec.yaml` 中添加 `image` 依赖
2. 创建 `pixel_art_filters.dart` - 定义滤镜预设
3. 创建 `pixel_art_processor.dart` - 实现图像处理核心逻辑
4. 创建 widgets 组件
5. 创建 `pixel_art_page.dart` - 主页面UI
6. 创建 `pixel_art_tool.dart` - 工具注册
7. 在 `main.dart` 中注册工具
8. 集成测试

## 风险评估

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| 大图片处理慢 | 中 | 中 | 预览使用缩略图，保存时提示等待 |
| 内存占用过高 | 中 | 低 | 及时释放不需要的图像数据 |
| 颜色量化效果不佳 | 中 | 低 | 调整算法参数，提供多种预设 |
