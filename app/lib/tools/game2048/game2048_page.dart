import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import 'game2048_colors.dart';
import 'game2048_logic.dart';
import 'game2048_board.dart';
import 'widgets/score_card.dart';
import 'widgets/game_over_dialog.dart';

/// 2048 游戏页面
class Game2048Page extends StatefulWidget {
  const Game2048Page({super.key});

  @override
  State<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends State<Game2048Page> {
  late Game2048Logic _logic;
  bool _hasShownWinDialog = false;

  @override
  void initState() {
    super.initState();
    _logic = Game2048Logic();
    _logic.startNewGame();
  }

  void _handleSwipe(DragEndDetails details) {
    if (_logic.isGameOver) return;

    final velocity = details.primaryVelocity;
    if (velocity == null) return;

    // 检测滑动方向
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      // 水平滑动
      if (dx > 0) {
        _logic.moveRight();
      } else {
        _logic.moveLeft();
      }
    } else {
      // 垂直滑动
      if (dy > 0) {
        _logic.moveDown();
      } else {
        _logic.moveUp();
      }
    }

    setState(() {
      _checkWinCondition();
      _checkGameOver();
    });
  }

  void _checkWinCondition() {
    if (_logic.isWon && !_hasShownWinDialog) {
      _hasShownWinDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWinDialog();
      });
    }
  }

  void _checkGameOver() {
    if (_logic.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 32),
            const SizedBox(width: 12),
            const Text('恭喜你！'),
          ],
        ),
        content: const Text(
          '太棒了！你成功达到了 2048！\n\n继续游戏，挑战更高的数字吧！',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续游戏'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        score: _logic.score,
        maxTile: _logic.maxTile,
        isWon: false,
        onRestart: () {
          setState(() {
            _hasShownWinDialog = false;
            _logic.startNewGame();
          });
        },
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _hasShownWinDialog = false;
      _logic.startNewGame();
    });
  }

  void _undo() {
    if (_logic.canUndo) {
      setState(() {
        _logic.undo();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth - 48; // 留边距

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('2048'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _logic.canUndo ? _undo : null,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: '重新开始',
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _handleSwipe,
        onVerticalDragEnd: _handleSwipe,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 分数显示区域
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ScoreCard(
                      label: '得分',
                      value: _logic.score,
                    ),
                    ScoreCard(
                      label: '最大数字',
                      value: _logic.maxTile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 游戏棋盘
                Center(
                  child: Game2048Board(
                    tiles: _logic.state.tiles,
                    size: boardSize.clamp(280, 400),
                  ),
                ),
                const SizedBox(height: 24),
                // 操作提示
                Text(
                  '上下左右滑动来移动方块',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
