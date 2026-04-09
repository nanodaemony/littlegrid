import 'dart:math';
import 'models/tile.dart';
import 'models/game_state.dart';

/// 2048 游戏核心逻辑
class Game2048Logic {
  GameState _state = GameState.initial();
  final Random _random = Random();

  /// 获取当前游戏状态
  GameState get state => _state;

  /// 开始新游戏
  void startNewGame() {
    Tile.resetIdCounter();
    _state = GameState.initial();
    _addRandomTile();
    _addRandomTile();
  }

  /// 向左移动
  void moveLeft() {
    if (_state.isGameOver) return;
    _move(0, -1, 0, 1);
  }

  /// 向右移动
  void moveRight() {
    if (_state.isGameOver) return;
    _move(0, 1, 0, -1);
  }

  /// 向上移动
  void moveUp() {
    if (_state.isGameOver) return;
    _move(-1, 0, 1, 0);
  }

  /// 向下移动
  void moveDown() {
    if (_state.isGameOver) return;
    _move(1, 0, -1, 0);
  }

  /// 核心移动逻辑
  void _move(int rowDir, int colDir, int startRow, int startCol) {
    final oldBoard = _state.boardMatrix;
    final List<Tile> newTiles = [];
    final Set<int> mergedIds = {};
    int newScore = _state.score;

    // 遍历每一行/列
    for (int i = 0; i < 4; i++) {
      final List<int> line = [];
      final List<int?> ids = [];

      // 收集一行/列的数据
      for (int j = 0; j < 4; j++) {
        int row = rowDir != 0 ? (startRow == 0 ? j : 3 - j) : i;
        int col = colDir != 0 ? (startCol == 0 ? j : 3 - j) : i;

        if (rowDir == 0) {
          row = colDir > 0 ? i : i;
          col = colDir > 0 ? (startCol == 0 ? 3 - j : j) : (startCol == 0 ? j : 3 - j);
        } else {
          row = rowDir > 0 ? (startRow == 0 ? 3 - j : j) : (startRow == 0 ? j : 3 - j);
          col = rowDir > 0 ? i : i;
        }

        final tile = _state.tiles.firstWhere(
          (t) => t.row == row && t.col == col,
          orElse: () => Tile(value: 0, row: row, col: col),
        );

        if (tile.value != 0) {
          line.add(tile.value);
          ids.add(tile.id);
        }
      }

      // 合并相同的数字
      final List<int> merged = [];
      final List<int?> mergedIdsList = [];

      for (int k = 0; k < line.length; k++) {
        if (k < line.length - 1 && line[k] == line[k + 1]) {
          merged.add(line[k] * 2);
          mergedIdsList.add(ids[k]);
          newScore += line[k] * 2;
          k++; // 跳过下一个
        } else {
          merged.add(line[k]);
          mergedIdsList.add(ids[k]);
        }
      }

      // 放置合并后的数字
      for (int k = 0; k < merged.length; k++) {
        int row, col;
        if (rowDir != 0) {
          row = rowDir > 0 ? (startRow == 0 ? 3 - k : k) : (startRow == 0 ? k : 3 - k);
          col = i;
        } else {
          row = i;
          col = colDir > 0 ? (startCol == 0 ? 3 - k : k) : (startCol == 0 ? k : 3 - k);
        }

        final isMerged = k < mergedIdsList.length && mergedIdsList[k] != null &&
            (k >= ids.length || ids.indexOf(mergedIdsList[k]) != k);

        newTiles.add(Tile(
          value: merged[k],
          row: row,
          col: col,
          id: mergedIdsList[k] ?? Tile._nextId++,
          isMerged: isMerged,
        ));
      }
    }

    // 检查是否有变化
    final newBoard = List.generate(4, (r) => List.filled(4, 0));
    for (final tile in newTiles) {
      newBoard[tile.row][tile.col] = tile.value;
    }

    bool hasChanged = false;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (oldBoard[r][c] != newBoard[r][c]) {
          hasChanged = true;
          break;
        }
      }
      if (hasChanged) break;
    }

    if (hasChanged) {
      // 保存历史记录
      final newHistory = List<List<List<int>>>.from(_state.history);
      if (newHistory.length >= 3) {
        newHistory.removeAt(0);
      }
      newHistory.add(oldBoard);

      // 更新状态
      _state = _state.copyWith(
        tiles: newTiles,
        score: newScore,
        history: newHistory,
      );

      // 添加新数字
      _addRandomTile();

      // 更新最大数字
      _updateMaxTile();

      // 检查是否达到 2048
      if (!_state.isWon && _state.maxTile >= 2048) {
        _state = _state.copyWith(isWon: true);
      }

      // 检查游戏是否结束
      _checkGameOver();
    }
  }

  /// 添加随机数字
  void _addRandomTile() {
    final emptyCells = <List<int>>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!_state.tiles.any((t) => t.row == r && t.col == c)) {
          emptyCells.add([r, c]);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final cell = emptyCells[_random.nextInt(emptyCells.length)];
      final value = _random.nextDouble() < 0.9 ? 2 : 4;
      _state = _state.copyWith(
        tiles: [..._state.tiles, Tile(
          value: value,
          row: cell[0],
          col: cell[1],
          isNew: true,
        )],
      );
    }
  }

  /// 更新最大数字
  void _updateMaxTile() {
    int maxTile = 0;
    for (final tile in _state.tiles) {
      if (tile.value > maxTile) {
        maxTile = tile.value;
      }
    }
    _state = _state.copyWith(maxTile: maxTile);
  }

  /// 检查游戏是否结束
  void _checkGameOver() {
    // 检查是否还有空格
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!_state.tiles.any((t) => t.row == r && t.col == c)) {
          return; // 还有空格，游戏继续
        }
      }
    }

    // 检查是否还能合并
    for (final tile in _state.tiles) {
      final neighbors = [
        [tile.row - 1, tile.col],
        [tile.row + 1, tile.col],
        [tile.row, tile.col - 1],
        [tile.row, tile.col + 1],
      ];

      for (final neighbor in neighbors) {
        if (neighbor[0] >= 0 && neighbor[0] < 4 && neighbor[1] >= 0 && neighbor[1] < 4) {
          final neighborTile = _state.tiles.firstWhere(
            (t) => t.row == neighbor[0] && t.col == neighbor[1],
            orElse: () => Tile(value: 0, row: neighbor[0], col: neighbor[1]),
          );
          if (neighborTile.value == tile.value) {
            return; // 还可以合并，游戏继续
          }
        }
      }
    }

    // 游戏结束
    _state = _state.copyWith(isGameOver: true);
  }

  /// 撤销上一步
  void undo() {
    if (_state.history.isEmpty) return;

    final previousBoard = _state.history.last;
    final newHistory = List<List<List<int>>>.from(_state.history)..removeLast();

    // 从历史记录重建格子
    final newTiles = <Tile>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (previousBoard[r][c] != 0) {
          newTiles.add(Tile(
            value: previousBoard[r][c],
            row: r,
            col: c,
          ));
        }
      }
    }

    // 恢复分数（无法精确恢复，使用估算）
    final newScore = (_state.score * 0.7).toInt();

    _state = _state.copyWith(
      tiles: newTiles,
      score: newScore,
      history: newHistory,
      isGameOver: false,
    );

    _updateMaxTile();
  }

  /// 加载保存的状态
  void loadState(GameState savedState) {
    _state = savedState;
  }

  /// 获取当前分数
  int get score => _state.score;

  /// 获取最大数字
  int get maxTile => _state.maxTile;

  /// 是否游戏结束
  bool get isGameOver => _state.isGameOver;

  /// 是否获胜
  bool get isWon => _state.isWon;

  /// 是否可以撤销
  bool get canUndo => _state.canUndo;
}
