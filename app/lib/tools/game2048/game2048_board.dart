import 'package:flutter/material.dart';
import 'game2048_colors.dart';
import 'models/tile.dart';
import 'widgets/tile_widget.dart';

/// 2048 游戏棋盘组件
class Game2048Board extends StatelessWidget {
  final List<Tile> tiles;
  final double size;

  const Game2048Board({
    super.key,
    required this.tiles,
    this.size = 320,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = (size - 40) / 4; // 减去间距

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Game2048Colors.boardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // 背景网格
          _buildBackgroundGrid(),
          // 数字格子
          ...tiles.map((tile) {
            return Positioned(
              left: 8 + tile.col * (tileSize + 8),
              top: 8 + tile.row * (tileSize + 8),
              child: TileWidget(
                tile: tile,
                size: tileSize,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    final tileSize = (size - 40) / 4;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (col) {
            return Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: Game2048Colors.emptyTile,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      }),
    );
  }
}
