import 'tile.dart';

/// 2048 游戏状态模型
class GameState {
  /// 所有格子
  final List<Tile> tiles;

  /// 当前得分
  final int score;

  /// 历史最高分
  final int bestScore;

  /// 当前最大数字
  final int maxTile;

  /// 是否游戏结束
  final bool isGameOver;

  /// 是否已达到 2048
  final bool isWon;

  /// 撤销历史（保存最近3步的棋盘状态）
  final List<List<List<int>>> history;

  /// 游戏开始时间
  final DateTime startTime;

  const GameState({
    required this.tiles,
    required this.score,
    required this.bestScore,
    required this.maxTile,
    required this.isGameOver,
    required this.isWon,
    required this.history,
    required this.startTime,
  });

  /// 创建初始状态
  factory GameState.initial() {
    return GameState(
      tiles: [],
      score: 0,
      bestScore: 0,
      maxTile: 0,
      isGameOver: false,
      isWon: false,
      history: [],
      startTime: DateTime.now(),
    );
  }

  /// 创建副本，可修改部分属性
  GameState copyWith({
    List<Tile>? tiles,
    int? score,
    int? bestScore,
    int? maxTile,
    bool? isGameOver,
    bool? isWon,
    List<List<List<int>>>? history,
    DateTime? startTime,
  }) {
    return GameState(
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      maxTile: maxTile ?? this.maxTile,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      history: history ?? this.history,
      startTime: startTime ?? this.startTime,
    );
  }

  /// 检查是否可以撤销
  bool get canUndo => history.isNotEmpty;

  /// 获取当前棋盘矩阵 (4x4)
  List<List<int>> get boardMatrix {
    final matrix = List.generate(4, (_) => List.filled(4, 0));
    for (final tile in tiles) {
      matrix[tile.row][tile.col] = tile.value;
    }
    return matrix;
  }

  @override
  String toString() {
    return 'GameState(score: $score, tiles: ${tiles.length}, gameOver: $isGameOver)';
  }
}
