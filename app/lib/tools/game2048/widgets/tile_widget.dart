import 'package:flutter/material.dart';
import '../game2048_colors.dart';
import '../models/tile.dart';

/// 2048 数字格子组件
class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;

  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Game2048Colors.getBackgroundColor(tile.value);
    final textColor = Game2048Colors.getTextColor(tile.value);
    final fontSize = Game2048Colors.getFontSize(tile.value);

    Widget tileWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          tile.value.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    // 新数字生成动画
    if (tile.isNew) {
      tileWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: tileWidget,
      );
    }

    // 合并动画
    if (tile.isMerged) {
      tileWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.15),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.15, end: 1.0),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
            builder: (context, scale2, child2) {
              return Transform.scale(
                scale: scale == 1.15 ? scale2 : scale,
                child: child2,
              );
            },
            child: child,
          );
        },
        child: tileWidget,
      );
    }

    return tileWidget;
  }
}
