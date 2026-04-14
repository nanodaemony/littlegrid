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
