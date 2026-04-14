import 'package:flutter/material.dart';
import 'maze_models.dart';
import 'maze_storage.dart';
import 'maze_themes.dart';
import 'maze_game_page.dart';

class MazePage extends StatefulWidget {
  const MazePage({super.key});

  @override
  State<MazePage> createState() => _MazePageState();
}

class _MazePageState extends State<MazePage> {
  final MazeStorage _storage = MazeStorage();
  double _mazeSize = 30;
  List<BestRecord> _bestRecords = [];
  MazeTheme _selectedTheme = MazeTheme.defaultTheme;
  MazeSaveState? _savedState;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _storage.loadBestRecords();
    final theme = await _storage.loadTheme();
    final savedState = await _storage.loadState();

    if (mounted) {
      setState(() {
        _bestRecords = records;
        _selectedTheme = theme;
        _savedState = savedState;
      });
    }
  }

  /// 获取指定难度的记录
  BestRecord? _getRecordForLevel(DifficultyLevel level) {
    try {
      return _bestRecords.firstWhere((r) => r.level == level);
    } catch (e) {
      return null;
    }
  }

  /// 开始新游戏
  void _startNewGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MazeGamePage(
          mazeSize: _mazeSize.round(),
          theme: _selectedTheme,
        ),
      ),
    ).then((_) => _loadData());
  }

  /// 继续游戏
  void _continueGame() {
    if (_savedState == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MazeGamePage(
          savedState: _savedState!,
          theme: _selectedTheme,
        ),
      ),
    ).then((_) => _loadData());
  }

  /// 显示继续游戏弹窗
  Future<void> _showContinueDialog() async {
    if (!mounted) return;

    final level = DifficultyLevel.forSize(_savedState!.cols);
    final progress = (_savedState!.progressPercent * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('发现未完成游戏'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('迷宫大小: ${_savedState!.cols}×${_savedState!.rows} (${level.displayName})'),
            Text('当前进度: $progress%'),
            Text('保存时间: ${_formatDate(_savedState!.savedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text('新游戏'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _continueGame();
            },
            child: const Text('继续游戏'),
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.month}-${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 处理开始按钮点击
  void _handleStart() {
    if (_savedState != null) {
      _showContinueDialog();
    } else {
      _startNewGame();
    }
  }

  /// 显示主题选择器
  void _showThemeSelector() {
    MazeThemes.showThemeSelector(
      context,
      currentTheme: _selectedTheme,
      onSelected: (theme) async {
        setState(() => _selectedTheme = theme);
        await _storage.saveTheme(theme);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('迷宫'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: _showThemeSelector,
            tooltip: '主题',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 游戏图标
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.route,
                  size: 60,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 难度选择
            _buildSizeSelector(),
            const SizedBox(height: 32),

            // 开始按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始游戏'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 最佳记录
            _buildRecords(),
          ],
        ),
      ),
    );
  }

  /// 大小选择器
  Widget _buildSizeSelector() {
    final level = DifficultyLevel.forSize(_mazeSize.round());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '迷宫大小',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_mazeSize.round()}×${_mazeSize.round()}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getLevelColor(level),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _mazeSize,
            min: 10,
            max: 100,
            divisions: 90,
            label: '${_mazeSize.round()}',
            onChanged: (value) {
              setState(() => _mazeSize = value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                '100',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 获取难度颜色
  Color _getLevelColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  /// 记录列表
  Widget _buildRecords() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '最佳记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...DifficultyLevel.values.map((level) {
            final record = _getRecordForLevel(level);
            return _RecordItem(
              level: level,
              record: record,
            );
          }),
        ],
      ),
    );
  }
}

/// 记录项
class _RecordItem extends StatelessWidget {
  final DifficultyLevel level;
  final BestRecord? record;

  const _RecordItem({
    required this.level,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getColor(level),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: record != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record!.formattedTime,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${record!.date.month}-${record!.date.day}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '--:--',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }
}
