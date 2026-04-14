import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'maze_models.dart';
import 'maze_logic.dart';
import 'maze_storage.dart';
import 'maze_themes.dart';
import 'widgets/maze_board.dart';
import 'widgets/virtual_joystick.dart';

class MazeGamePage extends StatefulWidget {
  final int? mazeSize;
  final MazeSaveState? savedState;
  final MazeTheme theme;

  const MazeGamePage({
    super.key,
    this.mazeSize,
    this.savedState,
    required this.theme,
  }) : assert(mazeSize != null || savedState != null);

  @override
  State<MazeGamePage> createState() => _MazeGamePageState();
}

class _MazeGamePageState extends State<MazeGamePage> {
  final MazeLogic _logic = MazeLogic();
  final TransformationController _transformationController =
      TransformationController();
  final MazeStorage _storage = MazeStorage();
  late MazeThemeData _themeData;
  Timer? _saveTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _themeData = MazeThemeData.of(widget.theme);

    if (widget.savedState != null) {
      _logic.restore(widget.savedState!);
    } else {
      _logic.initialize(widget.mazeSize!);
    }

    // 开始游戏计时
    if (!_logic.state.isGameOver) {
      _logic.startTimer(() {
        if (!_isDisposed) setState(() {});
      });
    }

    // 居中视图
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());

    // 定期保存
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveState());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _saveTimer?.cancel();
    _saveState();
    _logic.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// 保存当前状态
  Future<void> _saveState() async {
    if (_logic.state.isGameOver) {
      await _storage.clearState();
    } else {
      await _storage.saveState(_logic.getSaveState());
    }
  }

  /// 居中视图到玩家位置
  void _centerView() {
    final screenSize = MediaQuery.of(context).size;
    const cellSize = 32.0;
    final boardWidth = _logic.state.cols * cellSize;
    final boardHeight = _logic.state.rows * cellSize;

    final playerX = _logic.state.playerCol * cellSize + cellSize / 2;
    final playerY = _logic.state.playerRow * cellSize + cellSize / 2;

    final offsetX = playerX - screenSize.width / 2;
    final offsetY = playerY - (screenSize.height - kToolbarHeight - 200) / 2;

    _transformationController.value = Matrix4.translation(
      Vector3(-offsetX.clamp(0.0, boardWidth - screenSize.width),
              -offsetY.clamp(0.0, boardHeight - screenSize.height + 100),
              0),
    );
  }

  /// 处理滑动开始
  void _handlePanStart(DragStartDetails details) {
    if (_logic.state.isGameOver) return;
  }

  /// 处理滑动更新
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_logic.state.isGameOver) return;

    final dx = details.delta.dx;
    final dy = details.delta.dy;

    if (dx.abs() < 3 && dy.abs() < 3) return;

    Direction direction;
    if (dx.abs() > dy.abs()) {
      direction = dx > 0 ? Direction.right : Direction.left;
    } else {
      direction = dy > 0 ? Direction.down : Direction.up;
    }

    if (!_logic.movementController.isMoving) {
      _logic.movementController.start(direction, () {
        if (_logic.tryMove(direction)) {
          if (mounted) {
            setState(() {
              if (_logic.state.hasReachedEnd) {
                _showWinDialog();
              }
            });
          }
        }
      });
    } else {
      _logic.movementController.updateDirection(direction);
    }
  }

  /// 处理滑动结束
  void _handlePanEnd(DragEndDetails details) {
    _logic.movementController.stop();
  }

  /// 处理虚拟按键开始
  void _handleJoystickStart(Direction direction) {
    if (_logic.state.isGameOver) return;

    _logic.movementController.start(direction, () {
      if (_logic.tryMove(direction)) {
        if (mounted) {
          setState(() {
            if (_logic.state.hasReachedEnd) {
              _showWinDialog();
            }
          });
        }
      }
    });
  }

  /// 处理虚拟按键结束
  void _handleJoystickEnd() {
    _logic.movementController.stop();
  }

  /// 处理虚拟按键点击
  void _handleJoystickTap(Direction direction) {
    if (_logic.state.isGameOver) return;

    if (_logic.tryMove(direction)) {
      setState(() {
        if (_logic.state.hasReachedEnd) {
          _showWinDialog();
        }
      });
    }
  }

  /// 切换提示
  void _toggleHint() {
    setState(() {
      _logic.toggleHint();
    });
  }

  /// 显示最短路径
  Future<void> _showPath() async {
    // 长按提示
    setState(() {
      _logic.showShortestPath();
    });
  }

  /// 重新开始
  void _reset() {
    final size = widget.savedState != null
        ? widget.savedState!.cols
        : widget.mazeSize!;

    setState(() {
      _logic.dispose();
      _logic.initialize(size);
      _logic.startTimer(() {
        if (!_isDisposed) setState(() {});
      });
    });

    _centerView();
  }

  /// 显示通关弹窗
  void _showWinDialog() async {
    final time = _logic.state.elapsed;
    final size = _logic.state.cols;
    final isNewRecord = await _storage.saveRecordIfBetter(time, size);
    final level = DifficultyLevel.forSize(size);

    if (!mounted) return;

    await _storage.clearState();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 32),
            const SizedBox(width: 12),
            const Text('恭喜通关！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('迷宫大小: $size×$size (${level.displayName})'),
            Text('用时: ${_formatDuration(time)}'),
            Text('步数: ${_logic.state.moveCount}'),
            if (isNewRecord) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    const Text(
                      '新纪录！',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _reset();
            },
            child: const Text('再来一局'),
          ),
        ],
      ),
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('迷宫游戏'),
        actions: [
          GestureDetector(
            onTap: _toggleHint,
            onLongPress: _showPath,
            child: Tooltip(
              message: '提示（长按显示路径）',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  _logic.state.showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: '重新开始',
          ),
        ],
      ),
      backgroundColor: _themeData.backgroundColor,
      body: Column(
        children: [
          // 状态栏
          _buildStatusBar(),
          // 迷宫区域
          Expanded(
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.3,
                maxScale: 2.0,
                child: MazeBoard(
                  state: _logic.state,
                  theme: _themeData,
                ),
              ),
            ),
          ),
          // 虚拟方向按键
          VirtualJoystick(
            onDirectionStart: _handleJoystickStart,
            onDirectionEnd: _handleJoystickEnd,
            onDirectionTap: _handleJoystickTap,
          ),
        ],
      ),
    );
  }

  /// 状态栏
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                '用时',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                _formatDuration(_logic.state.elapsed),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '步数',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${_logic.state.moveCount}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '大小',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${_logic.state.cols}×${_logic.state.rows}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
