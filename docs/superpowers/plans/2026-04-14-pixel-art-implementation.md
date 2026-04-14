# 像素画生成器 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现像素画生成器功能，支持从相册选择图片，应用多种复古滤镜，调整像素大小和颜色数量，并保存到相册。

**Architecture:** 纯前端 Flutter 实现，使用 `image` 包进行图像处理，遵循现有工具模块的架构模式。

**Tech Stack:** Flutter, image: ^4.0.17, image_picker, gal, path_provider

---

## 文件结构概览

**新增文件：**
- `app/lib/tools/pixel_art/pixel_art_tool.dart` - 工具注册
- `app/lib/tools/pixel_art/pixel_art_page.dart` - 主页面
- `app/lib/tools/pixel_art/pixel_art_processor.dart` - 图像处理核心
- `app/lib/tools/pixel_art/pixel_art_filters.dart` - 滤镜预设
- `app/lib/tools/pixel_art/widgets/pixel_preview.dart` - 预览组件
- `app/lib/tools/pixel_art/widgets/filter_selector.dart` - 滤镜选择器
- `app/lib/tools/pixel_art/widgets/control_slider.dart` - 参数滑块

**修改文件：**
- `app/pubspec.yaml` - 添加依赖
- `app/lib/main.dart` - 注册工具

---

### Task 1: 添加 image 依赖

**Files:**
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: 读取现有 pubspec.yaml**

```bash
cd /home/nano/little-grid2/app && cat pubspec.yaml
```

- [ ] **Step 2: 添加 image 依赖**

在 `dependencies` 部分添加：
```yaml
image: ^4.0.17  # 用于图像处理
```

插入位置：在 `flutter_image_compress: ^2.0.0` 之后

- [ ] **Step 3: 验证 pubspec.yaml 格式**

```bash
cd /home/nano/little-grid2/app && flutter pub get
```

Expected: 成功获取依赖，无错误

- [ ] **Step 4: Commit**

```bash
cd /home/nano/little-grid2 && git add app/pubspec.yaml && git commit -m "Add image package dependency for pixel art generator

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

### Task 2: 创建滤镜预设定义

**Files:**
- Create: `app/lib/tools/pixel_art/pixel_art_filters.dart`

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p /home/nano/little-grid2/app/lib/tools/pixel_art/widgets
```

- [ ] **Step 2: 编写 pixel_art_filters.dart**

```dart
import 'package:flutter/material.dart';

enum PixelFilterType {
  eightBit,
  sixteenBit,
  gameBoy,
  nes,
  segaGenesis,
  commodore64,
  pixelSketch,
}

class PixelFilter {
  final String name;
  final List<Color>? palette;
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
  // Game Boy 4色调色板
  static const List<Color> _gameBoyPalette = [
    Color(0xFF0F380F),
    Color(0xFF306230),
    Color(0xFF8BAC0F),
    Color(0xFF9BBC0F),
  ];

  // NES 52色调色板
  static const List<Color> _nesPalette = [
    Color(0xFF7C7C7C), Color(0xFF0000FC), Color(0xFF0000BC), Color(0xFF4428BC),
    Color(0xFF940084), Color(0xFFA80020), Color(0xFFA81000), Color(0xFF881400),
    Color(0xFF503000), Color(0xFF007800), Color(0xFF006800), Color(0xFF005800),
    Color(0xFF004058), Color(0xFF000000), Color(0xFF000000), Color(0xFF000000),
    Color(0xFFBCBCBC), Color(0xFF0078F8), Color(0xFF0058F8), Color(0xFF6844FC),
    Color(0xFFD800CC), Color(0xFFE40058), Color(0xFFF83800), Color(0xFFE45C10),
    Color(0xFFAC7C00), Color(0xFF00B800), Color(0xFF00A800), Color(0xFF00A844),
    Color(0xFF008888), Color(0xFF000000), Color(0xFF000000), Color(0xFF000000),
    Color(0xFFF8F8F8), Color(0xFF3CBCFC), Color(0xFF6888FC), Color(0xFF9878F8),
    Color(0xFFF878F8), Color(0xFFF85898), Color(0xFFF87858), Color(0xFFFCA044),
    Color(0xFFF8B800), Color(0xFFB8F818), Color(0xFF58D854), Color(0xFF58F898),
    Color(0xFF00E8D8), Color(0xFF787878), Color(0xFF000000), Color(0xFF000000),
    Color(0xFFFCFCFC), Color(0xFFA4E4FC), Color(0xFFB8B8F8), Color(0xFFD8B8F8),
    Color(0xFFF8B8F8), Color(0xFFF8A4C0), Color(0xFFF0D0B0), Color(0xFFFCE0A8),
    Color(0xFFF8D878), Color(0xFFD8F878), Color(0xFFB8F8B8), Color(0xFFB8F8D8),
    Color(0xFF00FCFC), Color(0xFFF8D8F8), Color(0xFF000000), Color(0xFF000000),
  ];

  // Sega Genesis 64色调色板 (9位RGB, 3位/通道)
  static final List<Color> _segaGenesisPalette = List.generate(64, (index) {
    final r = ((index >> 4) & 0x03) * 85;
    final g = ((index >> 2) & 0x03) * 85;
    final b = (index & 0x03) * 85;
    return Color.fromARGB(255, r, g, b);
  });

  // Commodore 64 16色调色板
  static const List<Color> _commodore64Palette = [
    Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF880000), Color(0xFFAAFFEE),
    Color(0xFFCC44CC), Color(0xFF00CC55), Color(0xFF0000AA), Color(0xFFEEEE77),
    Color(0xFFDD8855), Color(0xFF664400), Color(0xFFFF7777), Color(0xFF333333),
    Color(0xFF777777), Color(0xFFAAFF66), Color(0xFF0088FF), Color(0xFFBBBBBB),
  ];

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
      palette: _gameBoyPalette,
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

- [ ] **Step 3: Commit**

```bash
cd /home/nano/little-grid2 && git add app/lib/tools/pixel_art/pixel_art_filters.dart && git commit -m "Add pixel art filters definitions

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

### Task 3: 创建图像处理核心

**Files:**
- Create: `app/lib/tools/pixel_art/pixel_art_processor.dart`

- [ ] **Step 1: 编写 pixel_art_processor.dart**

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'pixel_art_filters.dart';

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
    img.Image processed;
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
  img.Image _applyPixelFilter(
    img.Image image,
    int pixelSize,
    int colorCount,
    PixelFilter filter,
  ) {
    // 步骤1: 降采样
    final downscaled = _downscale(image, pixelSize);

    // 步骤2: 颜色量化
    img.Image quantized;
    if (filter.palette != null) {
      quantized = _applyFixedPalette(downscaled, filter.palette!);
    } else {
      quantized = _quantizeColors(downscaled, colorCount, filter.isGrayscale);
    }

    // 步骤3: 放大回原尺寸（最近邻插值）
    return _upscale(quantized, image.width, image.height);
  }

  /// 像素素描滤镜
  img.Image _applyPixelSketch(img.Image image, int pixelSize) {
    // 1. 转灰度
    final grayscale = img.grayscale(image);

    // 2. 降采样
    final downscaled = _downscale(grayscale, pixelSize);

    // 3. 边缘检测（Sobel算子）
    final edges = _detectEdges(downscaled);

    // 4. 二值化 - 反转颜色，线条为黑色
    final binary = _binarize(edges, threshold: 30, invert: true);

    // 5. 放大回原尺寸
    return _upscale(binary, image.width, image.height);
  }

  /// 降采样（按像素块大小）
  img.Image _downscale(img.Image image, int pixelSize) {
    final newWidth = (image.width / pixelSize).floor();
    final newHeight = (image.height / pixelSize).floor();
    return img.copyResize(image, width: newWidth, height: newHeight);
  }

  /// 放大（最近邻插值，保持像素感）
  img.Image _upscale(img.Image image, int targetWidth, int targetHeight) {
    return img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.nearest,
    );
  }

  /// 简单颜色量化 - 均匀量化
  img.Image _quantizeColors(img.Image image, int colorCount, bool isGrayscale) {
    if (isGrayscale) {
      // 灰度量化
      final grayLevels = colorCount;
      final step = 255 ~/ (grayLevels - 1);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final gray = img.getLuminance(pixel);
          final quantizedGray = (gray / step).round() * step;
          image.setPixelRgba(x, y, quantizedGray, quantizedGray, quantizedGray);
        }
      }
    } else {
      // RGB 均匀量化 - 使用中位切分简化版
      final bitsPerChannel = _calculateBitsPerChannel(colorCount);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = _quantizeChannel(img.getRed(pixel), bitsPerChannel);
          final g = _quantizeChannel(img.getGreen(pixel), bitsPerChannel);
          final b = _quantizeChannel(img.getBlue(pixel), bitsPerChannel);
          image.setPixelRgba(x, y, r, g, b);
        }
      }
    }
    return image;
  }

  int _calculateBitsPerChannel(int colorCount) {
    if (colorCount <= 8) return 1;
    if (colorCount <= 64) return 2;
    if (colorCount <= 512) return 3;
    return 4;
  }

  int _quantizeChannel(int value, int bits) {
    final levels = (1 << bits) - 1;
    final step = 255 ~/ levels;
    return (value / step).round() * step;
  }

  /// 应用固定调色板
  img.Image _applyFixedPalette(img.Image image, List<Color> palette) {
    // 将 Color 转换为 RGB 列表
    final paletteColors = palette.map((c) {
      return [c.red, c.green, c.blue];
    }).toList();

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);

        // 找到最近的调色板颜色
        var minDist = double.maxFinite;
        var nearestColor = paletteColors[0];

        for (final color in paletteColors) {
          final dist = _colorDistance(r, g, b, color[0], color[1], color[2]);
          if (dist < minDist) {
            minDist = dist;
            nearestColor = color;
          }
        }

        image.setPixelRgba(x, y, nearestColor[0], nearestColor[1], nearestColor[2]);
      }
    }
    return image;
  }

  double _colorDistance(int r1, int g1, int b1, int r2, int g2, int b2) {
    // 使用欧氏距离
    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    return dr * dr + dg * dg + db * db;
  }

  /// 边缘检测
  img.Image _detectEdges(img.Image image) {
    final result = img.Image(image.width, image.height);

    // Sobel 算子
    const sobelX = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]];
    const sobelY = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]];

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double gx = 0;
        double gy = 0;

        // 应用卷积
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final gray = img.getLuminance(pixel);
            gx += gray * sobelX[ky + 1][kx + 1];
            gy += gray * sobelY[ky + 1][kx + 1];
          }
        }

        // 计算梯度幅值
        final magnitude = (gx * gx + gy * gy).sqrt().toInt();
        final clamped = magnitude.clamp(0, 255);
        result.setPixelRgba(x, y, clamped, clamped, clamped);
      }
    }

    return result;
  }

  /// 二值化
  img.Image _binarize(img.Image image, {required int threshold, bool invert = false}) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel);
        var value = gray > threshold ? 255 : 0;
        if (invert) value = 255 - value;
        image.setPixelRgba(x, y, value, value, value);
      }
    }
    return image;
  }

  /// ui.Image 转换为 image包的Image
  Future<img.Image> _convertUiImageToImage(ui.Image uiImage) async {
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return img.decodeImage(bytes)!;
  }

  /// image包的Image 转换为 ui.Image
  Future<ui.Image> _convertImageToUiImage(img.Image image) async {
    final bytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// 缩小图片
  Future<ui.Image> _scaleDownImage(ui.Image image, {required int maxSize}) async {
    if (image.width <= maxSize && image.height <= maxSize) {
      return image;
    }

    // 计算缩放比例
    double scale;
    if (image.width > image.height) {
      scale = maxSize / image.width;
    } else {
      scale = maxSize / image.height;
    }

    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();

    // 转换为 image 包进行缩放
    final imgImage = await _convertUiImageToImage(image);
    final scaled = img.copyResize(imgImage, width: newWidth, height: newHeight);
    return _convertImageToUiImage(scaled);
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/nano/little-grid2 && git add app/lib/tools/pixel_art/pixel_art_processor.dart && git commit -m "Add pixel art image processor

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

### Task 4: 创建 UI 组件

**Files:**
- Create: `app/lib/tools/pixel_art/widgets/pixel_preview.dart`
- Create: `app/lib/tools/pixel_art/widgets/filter_selector.dart`
- Create: `app/lib/tools/pixel_art/widgets/control_slider.dart`

- [ ] **Step 1: 编写 pixel_preview.dart**

```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PixelPreview extends StatelessWidget {
  final ui.Image? image;
  final bool isLoading;
  final VoidCallback? onTap;
  final String placeholderText;

  const PixelPreview({
    super.key,
    this.image,
    this.isLoading = false,
    this.onTap,
    this.placeholderText = '请选择图片',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('处理中...'),
          ],
        ),
      );
    }

    if (image == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              placeholderText,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: RawImage(
        image: image,
        fit: BoxFit.contain,
      ),
    );
  }
}
```

- [ ] **Step 2: 编写 filter_selector.dart**

```dart
import 'package:flutter/material.dart';
import '../pixel_art_filters.dart';

class FilterSelector extends StatelessWidget {
  final PixelFilterType selectedFilter;
  final ValueChanged<PixelFilterType> onFilterSelected;

  const FilterSelector({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '滤镜风格',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: PixelFilterType.values.length,
            itemBuilder: (context, index) {
              final filterType = PixelFilterType.values[index];
              final filter = PixelArtFilters.get(filterType);
              final isSelected = filterType == selectedFilter;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(filter.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onFilterSelected(filterType);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: 编写 control_slider.dart**

```dart
import 'package:flutter/material.dart';

class ControlSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const ControlSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: enabled ? null : Colors.grey,
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: enabled ? null : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: enabled
                ? (newValue) => onChanged(newValue.round())
                : null,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd /home/nano/little-grid2 && git add app/lib/tools/pixel_art/widgets/pixel_preview.dart app/lib/tools/pixel_art/widgets/filter_selector.dart app/lib/tools/pixel_art/widgets/control_slider.dart && git commit -m "Add pixel art UI widgets

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

### Task 5: 创建主页面

**Files:**
- Create: `app/lib/tools/pixel_art/pixel_art_page.dart`

- [ ] **Step 1: 编写 pixel_art_page.dart**

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'pixel_art_filters.dart';
import 'pixel_art_processor.dart';
import 'widgets/pixel_preview.dart';
import 'widgets/filter_selector.dart';
import 'widgets/control_slider.dart';

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

    setState(() => _isProcessing = true);

    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      setState(() {
        _originalImage = frame.image;
      });

      await _updatePreview();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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

      if (mounted) {
        setState(() => _processedImage = processed);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = PixelArtFilters.get(_selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('像素画生成器'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 图片预览区
                    PixelPreview(
                      image: _showOriginal ? _originalImage : _processedImage,
                      isLoading: _isProcessing,
                      onTap: _originalImage == null ? _pickImage : null,
                    ),
                    const SizedBox(height: 12),

                    // 原图/效果图切换
                    if (_originalImage != null) ...[
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleButton('原图', _showOriginal),
                            const SizedBox(width: 8),
                            _buildToggleButton('效果图', !_showOriginal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 滤镜选择
                    FilterSelector(
                      selectedFilter: _selectedFilter,
                      onFilterSelected: (filterType) {
                        setState(() {
                          _selectedFilter = filterType;
                          _colorCount = PixelArtFilters.get(filterType).defaultColorCount;
                        });
                        _updatePreview();
                      },
                    ),
                    const SizedBox(height: 8),

                    // 像素大小滑块
                    ControlSlider(
                      label: '像素大小',
                      value: _pixelSize,
                      min: 1,
                      max: 32,
                      onChanged: (value) {
                        setState(() => _pixelSize = value);
                        _updatePreview();
                      },
                    ),

                    // 颜色数量滑块
                    ControlSlider(
                      label: '颜色数量',
                      value: _colorCount,
                      min: 2,
                      max: 256,
                      onChanged: (value) {
                        setState(() => _colorCount = value);
                        _updatePreview();
                      },
                      enabled: filter.allowsColorCountAdjustment,
                    ),
                  ],
                ),
              ),
            ),

            // 底部操作按钮
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('选择图片'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _processedImage == null || _isProcessing ? null : _saveImage,
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return OutlinedButton(
      onPressed: () {
        setState(() => _showOriginal = label == '原图');
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/nano/little-grid2 && git add app/lib/tools/pixel_art/pixel_art_page.dart && git commit -m "Add pixel art main page

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

### Task 6: 创建工具注册文件

**Files:**
- Create: `app/lib/tools/pixel_art/pixel_art_tool.dart`

- [ ] **Step 1: 编写 pixel_art_tool.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/services/tool_registry.dart';
import 'pixel_art_page.dart';

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

- [ ] **Step 2: Commit**

```bash
cd /home/nano/little-grid2 && git add app/lib/tools/pixel_art/pixel_art_tool.dart && git commit -m "Add pixel art tool registration

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

### Task 7: 在 main.dart 中注册工具

**Files:**
- Modify: `app/lib/main.dart`

- [ ] **Step 1: 读取现有 main.dart**

```bash
cd /home/nano/little-grid2 && head -80 app/lib/main.dart
```

- [ ] **Step 2: 添加 import 语句**

在 import 区域（约第43行）添加：
```dart
import 'tools/pixel_art/pixel_art_tool.dart';
```

位置：在 `import 'tools/treehole/treehole_tool.dart';` 之后

- [ ] **Step 3: 注册工具**

在 `main()` 函数中（约第78行）添加：
```dart
ToolRegistry.register(PixelArtTool());
```

位置：在 `ToolRegistry.register(TreeholeTool());` 之后

- [ ] **Step 4: 验证修改并提交**

```bash
cd /home/nano/little-grid2/app && flutter analyze lib/main.dart
```

Expected: 无分析错误

- [ ] **Step 5: Commit**

```bash
cd /home/nano/little-grid2 && git add app/lib/main.dart && git commit -m "Register pixel art tool in main.dart

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

### Task 8: 集成测试

**Files:**
- 无新文件，使用现有项目进行测试

- [ ] **Step 1: 运行 flutter analyze**

```bash
cd /home/nano/little-grid2/app && flutter analyze
```

Expected: 无严重错误

- [ ] **Step 2: 尝试编译项目**

```bash
cd /home/nano/little-grid2/app && flutter build apk --debug --no-pub
```

Expected: 编译成功（或至少无像素画生成器相关的错误）

- [ ] **Step 3: Commit（如有修复）**

（仅在发现问题并修复后执行）

---

## 自我评审检查

### 1. Spec 覆盖检查
- ✅ 图片选择（相册）- Task 5
- ✅ 像素大小调节 - Task 3, 5
- ✅ 颜色数量调节 - Task 3, 5
- ✅ 滤镜风格（8位、16位、Game Boy、NES、Sega Genesis、Commodore 64、像素素描）- Task 2, 3
- ✅ 保存到相册 - Task 5
- ✅ 实时预览 - Task 3, 5

### 2. 占位符检查
- ✅ 无 TBD/TODO
- ✅ 所有代码都完整提供
- ✅ 所有步骤都有明确的命令和期望结果

### 3. 类型一致性检查
- ✅ `PixelFilterType` 枚举在 Task 2 定义，在 Task 3, 5, 6 中使用一致
- ✅ `PixelArtProcessor` 方法签名一致
- ✅ 所有 widget 参数类型正确

---

## 执行选择

Plan complete and saved to `docs/superpowers/plans/2026-04-14-pixel-art-implementation.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
