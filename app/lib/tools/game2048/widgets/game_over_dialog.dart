import 'package:flutter/material.dart';

/// 游戏结束弹窗
class GameOverDialog extends StatelessWidget {
  final int score;
  final int maxTile;
  final bool isWon;
  final VoidCallback onRestart;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.maxTile,
    required this.isWon,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final title = isWon ? '恭喜你赢了！' : '游戏结束';
    final message = isWon
        ? '太棒了！你达到了 2048，继续挑战更高数字吧！'
        : '棋盘已满，无法继续移动';
    final icon = isWon ? Icons.emoji_events : Icons.sentiment_dissatisfied;
    final iconColor = isWon ? Colors.amber : Colors.grey;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('最终得分', score),
              _buildStat('最大数字', maxTile),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('返回'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRestart();
          },
          child: const Text('再来一局'),
        ),
      ],
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
