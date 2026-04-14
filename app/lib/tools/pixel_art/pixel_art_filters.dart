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
