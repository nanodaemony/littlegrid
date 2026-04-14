# 迷宫游戏实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现一个迷宫游戏功能格子，支持随机生成 10×10 到 100×100 的迷宫，使用持续滑动+虚拟按键控制，记录进度和最快通关时间，包含提示功能和主题配色。

**Architecture:** 遵循现有工具架构模式，参考贪吃蛇的实现风格，创建 ToolModule + 数据模型 + 生成器 + 游戏逻辑 + 页面 UI 的分层结构。使用 Prim 算法生成迷宫，BFS 算法寻路，InteractiveViewer 处理大迷宫滚动。

**Tech Stack:** Flutter + Dart, SharedPreferences (已有), vector_math (如有需要)

---

## 文件结构

```
app/lib/tools/maze/
├── maze_tool.dart              # ToolModule 实现，工具注册入口
├── maze_page.dart              # 入口页面（难度选择、记录）
├── maze_game_page.dart         # 游戏页面
├── maze_logic.dart             # 游戏逻辑
├── maze_generator.dart         # Prim 算法生成器 + BFS 寻路
├── maze_models.dart            # 数据模型
├── maze_storage.dart           # 本地存储
├── maze_themes.dart            # 主题配色
└── widgets/
    ├── maze_board.dart         # 迷宫画布
    └── virtual_joystick.dart   # 虚拟方向按键

app/lib/main.dart                # 注册 MazeTool
```

---

## Task 1: 创建目录结构和数据模型

**Files:**
- Create: `app/lib/tools/maze/` 目录及子目录
- Create: `app/lib/tools/maze/maze_models.dart`

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p app/lib/tools/maze/widgets
```

- [ ] **Step 2: 编写 maze_models.dart**

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

/// 移动方向
enum Direction { up, down, left, right }

/// 难度等级
enum DifficultyLevel {
  easy(10, 25),
  medium(26, 50),
  hard(51, 100);

  final int minSize;
  final int maxSize;
  const DifficultyLevel(this.minSize, this.maxSize);

  static DifficultyLevel forSize(int size) {
    if (size <= easy.maxSize) return easy;
    if (size <= medium.maxSize) return medium;
    return hard;
  }

  String get displayName {
    switch (this) {
      case easy:
        return '简单';
      case medium:
        return '中等';
      case hard:
        return '困难';
    }
  }
}

/// 迷宫格子
class MazeCell {
  final int row;
  final int col;
  bool topWall;
  bool bottomWall;
  bool leftWall;
  bool rightWall;
  bool isStart;
  bool isEnd;
  bool isVisited;
  bool isOnPath;

  MazeCell({
    required this.row,
    required this.col,
    this.topWall = true,
    this.bottomWall = true,
    this.leftWall = true,
    this.rightWall = true,
    this.isStart = false,
    this.isEnd = false,
    this.isVisited = false,
    this.isOnPath = false,
  });

  /// 检查是否可以向指定方向移动
  bool canMove(Direction direction) {
    switch (direction) {
      case Direction.up:
        return !topWall;
      case Direction.down:
        return !bottomWall;
      case Direction.left:
        return !leftWall;
      case Direction.right:
        return !rightWall;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'topWall': topWall,
      'bottomWall': bottomWall,
      'leftWall': leftWall,
      'rightWall': rightWall,
      'isStart': isStart,
      'isEnd': isEnd,
      'isVisited': isVisited,
    };
  }

  factory MazeCell.fromJson(Map<String, dynamic> json) {
    return MazeCell(
      row: json['row'] as int,
      col: json['col'] as int,
      topWall: json['topWall'] as bool,
      bottomWall: json['bottomWall'] as bool,
      leftWall: json['leftWall'] as bool,
      rightWall: json['rightWall'] as bool,
      isStart: json['isStart'] as bool,
      isEnd: json['isEnd'] as bool,
      isVisited: json['isVisited'] as bool,
    );
  }
}

/// 最佳记录
class BestRecord {
  final DifficultyLevel level;
  final Duration bestTime;
  final DateTime date;

  BestRecord({
    required this.level,
    required this.bestTime,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'bestTimeMs': bestTime.inMilliseconds,
      'date': date.toIso8601String(),
    };
  }

  factory BestRecord.fromJson(Map<String, dynamic> json) {
    return BestRecord(
      level: DifficultyLevel.values.firstWhere((l) => l.name == json['level']),
      bestTime: Duration(milliseconds: json['bestTimeMs'] as int),
      date: DateTime.parse(json['date'] as String),
    );
  }

  String get formattedTime {
    final minutes = bestTime.inMinutes;
    final seconds = bestTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 存档状态
class MazeSaveState {
  final int rows;
  final int cols;
  final int seed;
  final int playerRow;
  final int playerCol;
  final List<List<bool>> visitedCells;
  final Duration elapsed;
  final int moveCount;
  final DateTime savedAt;

  MazeSaveState({
    required this.rows,
    required this.cols,
    required this.seed,
    required this.playerRow,
    required this.playerCol,
    required this.visitedCells,
    required this.elapsed,
    required this.moveCount,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'cols': cols,
      'seed': seed,
      'playerRow': playerRow,
      'playerCol': playerCol,
      'visitedCells': visitedCells.map((row) => row.toList()).toList(),
      'elapsedMs': elapsed.inMilliseconds,
      'moveCount': moveCount,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory MazeSaveState.fromJson(Map<String, dynamic> json) {
    final visitedCellsJson = json['visitedCells'] as List;
    final visitedCells = visitedCellsJson
        .map((row) => (row as List).cast<bool>())
        .toList();

    return MazeSaveState(
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      seed: json['seed'] as int,
      playerRow: json['playerRow'] as int,
      playerCol: json['playerCol'] as int,
      visitedCells: visitedCells,
      elapsed: Duration(milliseconds: json['elapsedMs'] as int),
      moveCount: json['moveCount'] as int,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  /// 计算进度百分比
  double get progressPercent {
    int total = 0;
    int visited = 0;
    for (var row in visitedCells) {
      for (var cell in row) {
        total++;
        if (cell) visited++;
      }
    }
    return total > 0 ? visited / total : 0;
  }
}

/// 游戏状态
class MazeState {
  final int rows;
  final int cols;
  final List<List<MazeCell>> cells;
  final int seed;

  int playerRow;
  int playerCol;
  bool isGameOver;
  int moveCount;
  Duration elapsed;
  DateTime? startTime;

  bool showHint;
  bool showPath;
  List<Offset>? pathPoints;

  MazeState({
    required this.rows,
    required this.cols,
    required this.cells,
    required this.seed,
    required this.playerRow,
    required this.playerCol,
    this.isGameOver = false,
    this.moveCount = 0,
    this.elapsed = Duration.zero,
    this.startTime,
    this.showHint = false,
    this.showPath = false,
    this.pathPoints,
  });

  /// 获取当前玩家位置的格子
  MazeCell get currentCell => cells[playerRow][playerCol];

  /// 检查是否到达终点
  bool get hasReachedEnd => cells[playerRow][playerCol].isEnd;

  /// 获取可行的方向列表
  List<Direction> get availableDirections {
    final result = <Direction>[];
    final cell = currentCell;
    if (cell.canMove(Direction.up)) result.add(Direction.up);
    if (cell.canMove(Direction.down)) result.add(Direction.down);
    if (cell.canMove(Direction.left)) result.add(Direction.left);
    if (cell.canMove(Direction.right)) result.add(Direction.right);
    return result;
  }
}

/// 迷宫主题
enum MazeTheme {
  defaultTheme,
  classic,
  dark,
  fresh,
}

/// 主题配色数据
class MazeThemeData {
  final Color wallColor;
  final Color pathColor;
  final Color visitedColor;
  final Color playerColor;
  final Color startColor;
  final Color endColor;
  final Color hintColor;
  final Color pathHighlightColor;
  final Color backgroundColor;

  MazeThemeData({
    required this.wallColor,
    required this.pathColor,
    required this.visitedColor,
    required this.playerColor,
    required this.startColor,
    required this.endColor,
    required this.hintColor,
    required this.pathHighlightColor,
    required this.backgroundColor,
  });

  static MazeThemeData of(MazeTheme theme) {
    switch (theme) {
      case MazeTheme.defaultTheme:
        return MazeThemeData(
          wallColor: Colors.grey.shade800,
          pathColor: Colors.white,
          visitedColor: Colors.blue.withValues(alpha: 0.1),
          playerColor: Colors.blue.shade600,
          startColor: Colors.green.shade500,
          endColor: Colors.red.shade500,
          hintColor: Colors.amber.shade500,
          pathHighlightColor: Colors.green.withValues(alpha: 0.3),
          backgroundColor: Colors.grey.shade100,
        );
      case MazeTheme.classic:
        return MazeThemeData(
          wallColor: Colors.black,
          pathColor: Colors.white,
          visitedColor: Colors.grey.shade200,
          playerColor: Colors.black,
          startColor: Colors.green,
          endColor: Colors.red,
          hintColor: Colors.blue,
          pathHighlightColor: Colors.green.withValues(alpha: 0.4),
          backgroundColor: Colors.white,
        );
      case MazeTheme.dark:
        return MazeThemeData(
          wallColor: Colors.grey.shade600,
          pathColor: Colors.grey.shade900,
          visitedColor: Colors.blue.shade900.withValues(alpha: 0.3),
          playerColor: Colors.blue.shade400,
          startColor: Colors.green.shade400,
          endColor: Colors.red.shade400,
          hintColor: Colors.amber.shade400,
          pathHighlightColor: Colors.green.shade700.withValues(alpha: 0.5),
          backgroundColor: Colors.grey.shade950,
        );
      case MazeTheme.fresh:
        return MazeThemeData(
          wallColor: Colors.green.shade300,
          pathColor: Colors.pink.shade50,
          visitedColor: Colors.green.withValues(alpha: 0.1),
          playerColor: Colors.pink.shade400,
          startColor: Colors.green.shade400,
          endColor: Colors.pink.shade500,
          hintColor: Colors.orange.shade400,
          pathHighlightColor: Colors.green.shade200,
          backgroundColor: Colors.pink.shade50,
        );
    }
  }

  String get displayName {
    switch (this as MazeTheme) {
      case MazeTheme.defaultTheme:
        return '默认';
      case MazeTheme.classic:
        return '经典';
      case MazeTheme.dark:
        return '深色';
      case MazeTheme.fresh:
        return '清新';
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/tools/maze/maze_models.dart
git commit -m "feat: add maze data models"
```

---

## Task 2: 创建迷宫生成器和寻路算法

**Files:**
- Create: `app/lib/tools/maze/maze_generator.dart`

- [ ] **Step 1: 编写 maze_generator.dart**

```dart
import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'maze_models.dart';

/// Prim 迷宫生成器
class MazeGenerator {
  /// 生成迷宫
  static List<List<MazeCell>> generate(int rows, int cols, {int? seed}) {
    final random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

    // 确保是奇数行列（墙-格子-墙模式）
    final effectiveRows = rows.isOdd ? rows : rows + 1;
    final effectiveCols = cols.isOdd ? cols : cols + 1;

    // 初始化所有格子都有墙
    final cells = List.generate(effectiveRows, (row) =>
      List.generate(effectiveCols, (col) => MazeCell(row: row, col: col)));

    // 设置起点和终点（确保在通道上）
    final startRow = 1;
    final startCol = 1;
    final endRow = effectiveRows - 2;
    final endCol = effectiveCols - 2;

    cells[startRow][startCol].isStart = true;
    cells[endRow][endCol].isEnd = true;

    // Prim 算法
    final visited = <MazeCell>{};
    final walls = <_Wall>[];

    // 从起点开始
    final startCell = cells[startRow][startCol];
    visited.add(startCell);

    // 添加起点的墙到列表
    _addWalls(startCell, walls, cells, effectiveRows, effectiveCols);

    while (walls.isNotEmpty) {
      // 随机选择一面墙
      final wallIndex = random.nextInt(walls.length);
      final wall = walls.removeAt(wallIndex);

      final cell1 = wall.cell;
      final cell2 = wall.adjacentCell;

      if (!visited.contains(cell2)) {
        // 拆除墙
        _removeWall(cell1, cell2, wall.direction);

        visited.add(cell2);
        _addWalls(cell2, walls, cells, effectiveRows, effectiveCols);
      }
    }

    return cells;
  }

  /// 添加格子的四堵墙到候选列表
  static void _addWalls(MazeCell cell, List<_Wall> walls,
      List<List<MazeCell>> cells, int rows, int cols) {
    final directions = [
      (Direction.up, -1, 0),
      (Direction.down, 1, 0),
      (Direction.left, 0, -1),
      (Direction.right, 0, 1),
    ];

    for (final dir in directions) {
      final newRow = cell.row + dir.$2;
      final newCol = cell.col + dir.$3;

      if (newRow >= 0 && newRow < rows &&
          newCol >= 0 && newCol < cols) {
        walls.add(_Wall(cell, cells[newRow][newCol], dir.$1));
      }
    }
  }

  /// 拆除两格之间的墙
  static void _removeWall(MazeCell cell1, MazeCell cell2, Direction direction) {
    switch (direction) {
      case Direction.up:
        cell1.topWall = false;
        cell2.bottomWall = false;
        break;
      case Direction.down:
        cell1.bottomWall = false;
        cell2.topWall = false;
        break;
      case Direction.left:
        cell1.leftWall = false;
        cell2.rightWall = false;
        break;
      case Direction.right:
        cell1.rightWall = false;
        cell2.leftWall = false;
        break;
    }
  }
}

/// 墙数据（内部使用）
class _Wall {
  final MazeCell cell;
  final MazeCell adjacentCell;
  final Direction direction;
  _Wall(this.cell, this.adjacentCell, this.direction);
}

/// BFS 最短路径寻路器
class PathFinder {
  /// 查找从起点到终点的最短路径
  static List<Offset>? findPath(List<List<MazeCell>> cells,
      int startRow, int startCol, int endRow, int endCol) {
    final rows = cells.length;
    final cols = cells[0].length;

    final visited = List.generate(rows, (_) => List.filled(cols, false));
    final parent = List.generate(rows, (_) =>
      List.generate(cols, (_) => const Offset(-1, -1)));

    final queue = Queue<Offset>();
    queue.add(Offset(startCol.toDouble(), startRow.toDouble()));
    visited[startRow][startCol] = true;

    final directions = [
      (Direction.up, -1, 0),
      (Direction.down, 1, 0),
      (Direction.left, 0, -1),
      (Direction.right, 0, 1),
    ];

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final col = current.dx.toInt();
      final row = current.dy.toInt();

      if (row == endRow && col == endCol) {
        // 重建路径
        final path = <Offset>[];
        var r = endRow, c = endCol;
        while (r != -1 && c != -1) {
          path.add(Offset(c.toDouble(), r.toDouble()));
          final p = parent[r][c];
          r = p.dy.toInt();
          c = p.dx.toInt();
        }
        return path.reversed.toList();
      }

      final cell = cells[row][col];
      for (final dir in directions) {
        final newRow = row + dir.$2;
        final newCol = col + dir.$3;

        // 检查是否可以移动到该方向
        if (!_canMove(cell, dir.$1)) continue;
        if (newRow < 0 || newRow >= rows) continue;
        if (newCol < 0 || newCol >= cols) continue;
        if (visited[newRow][newCol]) continue;

        visited[newRow][newCol] = true;
        parent[newRow][newCol] = Offset(col.toDouble(), row.toDouble());
        queue.add(Offset(newCol.toDouble(), newRow.toDouble()));
      }
    }

    return null;
  }

  /// 检查是否可以向指定方向移动
  static bool _canMove(MazeCell cell, Direction direction) {
    switch (direction) {
      case Direction.up:
        return !cell.topWall;
      case Direction.down:
        return !cell.bottomWall;
      case Direction.left:
        return !cell.leftWall;
      case Direction.right:
        return !cell.rightWall;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/tools/maze/maze_generator.dart
git commit -m "feat: add maze generator (Prim algorithm) and path finder (BFS)"
```

---

## Task 3: 创建游戏逻辑和持续移动控制器

**Files:**
- Create: `app/lib/tools/maze/maze_logic.dart`

- [ ] **Step 1: 编写 maze_logic.dart**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'maze_models.dart';
import 'maze_generator.dart';

/// 持续移动控制器
class ContinuousMovementController {
  Timer? _moveTimer;
  Direction? _currentDirection;
  VoidCallback? onMove;

  static const _moveInterval = Duration(milliseconds: 180);

  void start(Direction direction, VoidCallback moveCallback) {
    _currentDirection = direction;
    onMove = moveCallback;
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(_moveInterval, (_) {
      onMove?.call();
    });
    // 立即执行一次
    onMove?.call();
  }

  void updateDirection(Direction direction) {
    if (_currentDirection != direction) {
      _currentDirection = direction;
    }
  }

  void stop() {
    _moveTimer?.cancel();
    _moveTimer = null;
    _currentDirection = null;
    onMove = null;
  }

  Direction? get currentDirection => _currentDirection;
  bool get isMoving => _moveTimer != null;
}

/// 迷宫游戏逻辑
class MazeLogic {
  late MazeState state;
  final ContinuousMovementController movementController =
      ContinuousMovementController();
  Timer? _gameTimer;

  /// 初始化新游戏
  void initialize(int size, {int? seed}) {
    final actualSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    final cells = MazeGenerator.generate(size, size, seed: actualSeed);

    // 找到起点和终点
    int startRow = 1, startCol = 1;
    int endRow = cells.length - 2, endCol = cells[0].length - 2;

    for (var row = 0; row < cells.length; row++) {
      for (var col = 0; col < cells[0].length; col++) {
        if (cells[row][col].isStart) {
          startRow = row;
          startCol = col;
        }
        if (cells[row][col].isEnd) {
          endRow = row;
          endCol = col;
        }
      }
    }

    // 标记起点为已访问
    cells[startRow][startCol].isVisited = true;

    state = MazeState(
      rows: cells.length,
      cols: cells[0].length,
      cells: cells,
      seed: actualSeed,
      playerRow: startRow,
      playerCol: startCol,
    );
  }

  /// 从存档恢复游戏
  void restore(MazeSaveState saveState) {
    final cells = MazeGenerator.generate(saveState.rows, saveState.cols,
        seed: saveState.seed);

    // 恢复访问状态
    for (var row = 0; row < saveState.visitedCells.length; row++) {
      for (var col = 0; col < saveState.visitedCells[row].length; col++) {
        if (row < cells.length && col < cells[0].length) {
          cells[row][col].isVisited = saveState.visitedCells[row][col];
        }
      }
    }

    state = MazeState(
      rows: cells.length,
      cols: cells[0].length,
      cells: cells,
      seed: saveState.seed,
      playerRow: saveState.playerRow,
      playerCol: saveState.playerCol,
      moveCount: saveState.moveCount,
      elapsed: saveState.elapsed,
    );
  }

  /// 开始游戏计时
  void startTimer(VoidCallback onTick) {
    _gameTimer?.cancel();
    state.startTime ??= DateTime.now();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.startTime != null) {
        state.elapsed = DateTime.now().difference(state.startTime!);
      }
      onTick();
    });
  }

  /// 暂停游戏计时
  void pauseTimer() {
    _gameTimer?.cancel();
  }

  /// 尝试向指定方向移动
  bool tryMove(Direction direction) {
    if (state.isGameOver) return false;

    final cell = state.cells[state.playerRow][state.playerCol];
    if (!cell.canMove(direction)) return false;

    // 计算新位置
    int newRow = state.playerRow;
    int newCol = state.playerCol;

    switch (direction) {
      case Direction.up:
        newRow--;
        break;
      case Direction.down:
        newRow++;
        break;
      case Direction.left:
        newCol--;
        break;
      case Direction.right:
        newCol++;
        break;
    }

    // 更新位置
    state.playerRow = newRow;
    state.playerCol = newCol;
    state.moveCount++;

    // 标记为已访问
    state.cells[newRow][newCol].isVisited = true;

    // 清除路径高亮（移动后消失）
    if (state.showPath) {
      state.showPath = false;
      state.pathPoints = null;
      for (var row in state.cells) {
        for (var cell in row) {
          cell.isOnPath = false;
        }
      }
    }

    // 检查是否到达终点
    if (state.hasReachedEnd) {
      state.isGameOver = true;
      pauseTimer();
      movementController.stop();
    }

    return true;
  }

  /// 切换提示显示
  void toggleHint() {
    state.showHint = !state.showHint;
  }

  /// 计算并显示最短路径
  void showShortestPath() {
    // 找到起点和终点
    int? startRow, startCol, endRow, endCol;
    for (var row = 0; row < state.cells.length; row++) {
      for (var col = 0; col < state.cells[0].length; col++) {
        if (state.cells[row][col].isStart) {
          startRow = row;
          startCol = col;
        }
        if (state.cells[row][col].isEnd) {
          endRow = row;
          endCol = col;
        }
      }
    }

    if (startRow == null || endRow == null) return;

    // 从当前位置寻路
    final path = PathFinder.findPath(
      state.cells,
      state.playerRow,
      state.playerCol,
      endRow,
      endCol,
    );

    if (path != null) {
      state.pathPoints = path;
      state.showPath = true;

      // 标记路径上的格子
      for (var point in path) {
        final row = point.dy.toInt();
        final col = point.dx.toInt();
        if (row < state.cells.length && col < state.cells[0].length) {
          state.cells[row][col].isOnPath = true;
        }
      }
    }
  }

  /// 隐藏路径
  void hidePath() {
    state.showPath = false;
    state.pathPoints = null;
    for (var row in state.cells) {
      for (var cell in row) {
        cell.isOnPath = false;
      }
    }
  }

  /// 清理资源
  void dispose() {
    movementController.stop();
    _gameTimer?.cancel();
  }

  /// 获取存档状态
  MazeSaveState getSaveState() {
    final visitedCells = state.cells
        .map((row) => row.map((cell) => cell.isVisited).toList())
        .toList();

    return MazeSaveState(
      rows: state.rows,
      cols: state.cols,
      seed: state.seed,
      playerRow: state.playerRow,
      playerCol: state.playerCol,
      visitedCells: visitedCells,
      elapsed: state.elapsed,
      moveCount: state.moveCount,
      savedAt: DateTime.now(),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/tools/maze/maze_logic.dart
git commit -m "feat: add maze game logic and continuous movement controller"
```

---

## Task 4: 创建本地存储

**Files:**
- Create: `app/lib/tools/maze/maze_storage.dart`

- [ ] **Step 1: 编写 maze_storage.dart**

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import 'maze_models.dart';

/// 迷宫本地存储
class MazeStorage {
  static const String _currentStateKey = 'maze_current_state';
  static const String _bestRecordsKey = 'maze_best_records';
  static const String _selectedThemeKey = 'maze_selected_theme';

  /// 保存当前游戏状态
  Future<void> saveState(MazeSaveState state) async {
    try {
      final json = state.toJson();
      await StorageService.setString(_currentStateKey, jsonEncode(json));
    } catch (e) {
      debugPrint('Save maze state failed: $e');
    }
  }

  /// 加载当前游戏状态
  Future<MazeSaveState?> loadState() async {
    try {
      final jsonString = await StorageService.getString(_currentStateKey);
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return MazeSaveState.fromJson(json);
    } catch (e) {
      debugPrint('Load maze state failed: $e');
      return null;
    }
  }

  /// 清除当前游戏状态
  Future<void> clearState() async {
    try {
      await StorageService.remove(_currentStateKey);
    } catch (e) {
      debugPrint('Clear maze state failed: $e');
    }
  }

  /// 加载最佳记录列表
  Future<List<BestRecord>> loadBestRecords() async {
    try {
      final jsonString = await StorageService.getString(_bestRecordsKey);
      if (jsonString == null) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => BestRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Load maze best records failed: $e');
      return [];
    }
  }

  /// 获取指定难度的最佳记录
  Future<BestRecord?> getBestRecord(DifficultyLevel level) async {
    final records = await loadBestRecords();
    try {
      return records.firstWhere((r) => r.level == level);
    } catch (e) {
      return null;
    }
  }

  /// 保存最佳记录（如果更好则更新）
  Future<bool> saveRecordIfBetter(Duration time, int size) async {
    final level = DifficultyLevel.forSize(size);
    final records = await loadBestRecords();
    final existingIndex = records.indexWhere((r) => r.level == level);

    if (existingIndex >= 0) {
      if (time < records[existingIndex].bestTime) {
        records[existingIndex] = BestRecord(
          level: level,
          bestTime: time,
          date: DateTime.now(),
        );
        await _saveRecords(records);
        return true;
      }
      return false;
    } else {
      records.add(BestRecord(
        level: level,
        bestTime: time,
        date: DateTime.now(),
      ));
      await _saveRecords(records);
      return true;
    }
  }

  /// 保存记录列表
  Future<void> _saveRecords(List<BestRecord> records) async {
    try {
      final jsonList = records.map((r) => r.toJson()).toList();
      await StorageService.setString(_bestRecordsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Save maze best records failed: $e');
    }
  }

  /// 加载选中的主题
  Future<MazeTheme> loadTheme() async {
    try {
      final themeName = await StorageService.getString(_selectedThemeKey);
      if (themeName != null) {
        return MazeTheme.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => MazeTheme.defaultTheme,
        );
      }
    } catch (e) {
      debugPrint('Load maze theme failed: $e');
    }
    return MazeTheme.defaultTheme;
  }

  /// 保存主题
  Future<void> saveTheme(MazeTheme theme) async {
    try {
      await StorageService.setString(_selectedThemeKey, theme.name);
    } catch (e) {
      debugPrint('Save maze theme failed: $e');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/tools/maze/maze_storage.dart
git commit -m "feat: add maze storage service"
```

---

## Task 5: 创建主题配置

**Files:**
- Create: `app/lib/tools/maze/maze_themes.dart`

- [ ] **Step 1: 编写 maze_themes.dart**

```dart
import 'package:flutter/material.dart';
import 'maze_models.dart';

/// 主题管理
class MazeThemes {
  /// 获取所有可用主题
  static List<(MazeTheme, String)> get allThemes => [
        (MazeTheme.defaultTheme, '默认'),
        (MazeTheme.classic, '经典'),
        (MazeTheme.dark, '深色'),
        (MazeTheme.fresh, '清新'),
      ];

  /// 主题选择器弹窗
  static void showThemeSelector(
    BuildContext context, {
    required MazeTheme currentTheme,
    required Function(MazeTheme) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部指示器
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 标题
            Text(
              '选择主题',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 主题列表
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: allThemes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final (theme, name) = allThemes[index];
                  final themeData = MazeThemeData.of(theme);
                  final isSelected = theme == currentTheme;

                  return _ThemeOption(
                    theme: theme,
                    name: name,
                    themeData: themeData,
                    isSelected: isSelected,
                    onTap: () {
                      onSelected(theme);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 主题选项
class _ThemeOption extends StatelessWidget {
  final MazeTheme theme;
  final String name;
  final MazeThemeData themeData;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.name,
    required this.themeData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            // 主题预览
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: themeData.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeData.wallColor, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: themeData.playerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 名称
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            // 选中标记
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/tools/maze/maze_themes.dart
git commit -m "feat: add maze theme configuration"
```

---

## Task 6: 创建 Widget 组件

**Files:**
- Create: `app/lib/tools/maze/widgets/maze_board.dart`
- Create: `app/lib/tools/maze/widgets/virtual_joystick.dart`

- [ ] **Step 1: 编写 maze_board.dart**

```dart
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../maze_models.dart';
import '../maze_logic.dart';

/// 迷宫画布
class MazeBoard extends StatefulWidget {
  final MazeState state;
  final MazeThemeData theme;
  final TransformationController transformationController;

  const MazeBoard({
    super.key,
    required this.state,
    required this.theme,
    required this.transformationController,
  });

  @override
  State<MazeBoard> createState() => _MazeBoardState();
}

class _MazeBoardState extends State<MazeBoard> {
  static const double cellSize = 32.0;
  static const double wallThickness = 2.0;

  @override
  Widget build(BuildContext context) {
    final boardWidth = widget.state.cols * cellSize;
    final boardHeight = widget.state.rows * cellSize;

    return SizedBox(
      width: boardWidth,
      height: boardHeight,
      child: CustomPaint(
        painter: _MazePainter(
          state: widget.state,
          theme: widget.theme,
          cellSize: cellSize,
          wallThickness: wallThickness,
        ),
      ),
    );
  }
}

/// 迷宫绘制器
class _MazePainter extends CustomPainter {
  final MazeState state;
  final MazeThemeData theme;
  final double cellSize;
  final double wallThickness;

  _MazePainter({
    required this.state,
    required this.theme,
    required this.cellSize,
    required this.wallThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final bgPaint = Paint()..color = theme.pathColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 绘制路径高亮
    if (state.showPath) {
      final pathPaint = Paint()..color = theme.pathHighlightColor;
      for (var row = 0; row < state.cells.length; row++) {
        for (var col = 0; col < state.cells[row].length; col++) {
          final cell = state.cells[row][col];
          if (cell.isOnPath) {
            final rect = Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize,
              cellSize,
            );
            canvas.drawRect(rect, pathPaint);
          }
        }
      }
    }

    // 绘制已访问的路径
    final visitedPaint = Paint()..color = theme.visitedColor;
    for (var row = 0; row < state.cells.length; row++) {
      for (var col = 0; col < state.cells[row].length; col++) {
        final cell = state.cells[row][col];
        if (cell.isVisited && !cell.isOnPath) {
          final rect = Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          );
          canvas.drawRect(rect, visitedPaint);
        }
      }
    }

    // 绘制起点和终点
    _drawStartEnd(canvas);

    // 绘制墙
    _drawWalls(canvas);

    // 绘制提示（可行方向）
    if (state.showHint) {
      _drawHint(canvas);
    }

    // 绘制玩家
    _drawPlayer(canvas);
  }

  /// 绘制起点和终点
  void _drawStartEnd(Canvas canvas) {
    for (var row = 0; row < state.cells.length; row++) {
      for (var col = 0; col < state.cells[row].length; col++) {
        final cell = state.cells[row][col];
        if (cell.isStart || cell.isEnd) {
          final center = Offset(
            col * cellSize + cellSize / 2,
            row * cellSize + cellSize / 2,
          );
          final radius = cellSize * 0.3;
          final paint = Paint()
            ..color = cell.isStart ? theme.startColor : theme.endColor
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, radius, paint);
        }
      }
    }
  }

  /// 绘制墙
  void _drawWalls(Canvas canvas) {
    final wallPaint = Paint()
      ..color = theme.wallColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = wallThickness;

    for (var row = 0; row < state.cells.length; row++) {
      for (var col = 0; col < state.cells[row].length; col++) {
        final cell = state.cells[row][col];
        final left = col * cellSize;
        final top = row * cellSize;
        final right = left + cellSize;
        final bottom = top + cellSize;

        if (cell.topWall) {
          canvas.drawLine(Offset(left, top), Offset(right, top), wallPaint);
        }
        if (cell.bottomWall) {
          canvas.drawLine(Offset(left, bottom), Offset(right, bottom), wallPaint);
        }
        if (cell.leftWall) {
          canvas.drawLine(Offset(left, top), Offset(left, bottom), wallPaint);
        }
        if (cell.rightWall) {
          canvas.drawLine(Offset(right, top), Offset(right, bottom), wallPaint);
        }
      }
    }
  }

  /// 绘制提示
  void _drawHint(Canvas canvas) {
    final hintPaint = Paint()
      ..color = theme.hintColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final directions = state.availableDirections;
    final playerCenter = Offset(
      state.playerCol * cellSize + cellSize / 2,
      state.playerRow * cellSize + cellSize / 2,
    );
    final arrowSize = cellSize * 0.2;

    for (final dir in directions) {
      Offset arrowOffset;
      switch (dir) {
        case Direction.up:
          arrowOffset = Offset(0, -cellSize * 0.35);
          break;
        case Direction.down:
          arrowOffset = Offset(0, cellSize * 0.35);
          break;
        case Direction.left:
          arrowOffset = Offset(-cellSize * 0.35, 0);
          break;
        case Direction.right:
          arrowOffset = Offset(cellSize * 0.35, 0);
          break;
      }

      final arrowCenter = playerCenter + arrowOffset;
      canvas.drawCircle(arrowCenter, arrowSize, hintPaint);
    }
  }

  /// 绘制玩家
  void _drawPlayer(Canvas canvas) {
    final center = Offset(
      state.playerCol * cellSize + cellSize / 2,
      state.playerRow * cellSize + cellSize / 2,
    );
    final radius = cellSize * 0.35;

    final paint = Paint()
      ..color = theme.playerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MazePainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.theme != theme;
  }
}
```

- [ ] **Step 2: 编写 virtual_joystick.dart**

```dart
import 'package:flutter/material.dart';
import '../maze_models.dart';

/// 虚拟方向按键
class VirtualJoystick extends StatelessWidget {
  final Function(Direction) onDirectionStart;
  final VoidCallback onDirectionEnd;
  final Function(Direction)? onDirectionTap;

  const VirtualJoystick({
    super.key,
    required this.onDirectionStart,
    required this.onDirectionEnd,
    this.onDirectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上
          _DirectionButton(
            direction: Direction.up,
            icon: Icons.keyboard_arrow_up,
            onDirectionStart: onDirectionStart,
            onDirectionEnd: onDirectionEnd,
            onDirectionTap: onDirectionTap,
          ),
          const SizedBox(height: 8),
          // 中排（左-空-右）
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DirectionButton(
                direction: Direction.left,
                icon: Icons.keyboard_arrow_left,
                onDirectionStart: onDirectionStart,
                onDirectionEnd: onDirectionEnd,
                onDirectionTap: onDirectionTap,
              ),
              const SizedBox(width: 8),
              // 中间空位
              SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DirectionButton(
                direction: Direction.right,
                icon: Icons.keyboard_arrow_right,
                onDirectionStart: onDirectionStart,
                onDirectionEnd: onDirectionEnd,
                onDirectionTap: onDirectionTap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 下
          _DirectionButton(
            direction: Direction.down,
            icon: Icons.keyboard_arrow_down,
            onDirectionStart: onDirectionStart,
            onDirectionEnd: onDirectionEnd,
            onDirectionTap: onDirectionTap,
          ),
        ],
      ),
    );
  }
}

/// 单个方向按钮
class _DirectionButton extends StatefulWidget {
  final Direction direction;
  final IconData icon;
  final Function(Direction) onDirectionStart;
  final VoidCallback onDirectionEnd;
  final Function(Direction)? onDirectionTap;

  const _DirectionButton({
    required this.direction,
    required this.icon,
    required this.onDirectionStart,
    required this.onDirectionEnd,
    this.onDirectionTap,
  });

  @override
  State<_DirectionButton> createState() => _DirectionButtonState();
}

class _DirectionButtonState extends State<_DirectionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onDirectionStart(widget.direction);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onDirectionEnd();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onDirectionEnd();
      },
      onTap: () {
        widget.onDirectionTap?.call(widget.direction);
      },
      onLongPressStart: (_) {
        setState(() => _isPressed = true);
        widget.onDirectionStart(widget.direction);
      },
      onLongPressEnd: (_) {
        setState(() => _isPressed = false);
        widget.onDirectionEnd();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _isPressed
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(
          widget.icon,
          size: 32,
          color: _isPressed
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/tools/maze/widgets/maze_board.dart
git add app/lib/tools/maze/widgets/virtual_joystick.dart
git commit -m "feat: add maze widgets (board, virtual joystick)"
```

---

## Task 7: 创建入口页面 MazePage

**Files:**
- Create: `app/lib/tools/maze/maze_page.dart`

- [ ] **Step 1: 编写 maze_page.dart**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/tools/maze/maze_page.dart
git commit -m "feat: add MazePage entrance UI"
```

---

## Task 8: 创建游戏页面 MazeGamePage

**Files:**
- Create: `app/lib/tools/maze/maze_game_page.dart`

- [ ] **Step 1: 编写 maze_game_page.dart**

```dart
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
    final cellSize = 32.0;
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
                  transformationController: _transformationController,
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
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/tools/maze/maze_game_page.dart
git commit -m "feat: add MazeGamePage game UI"
```

---

## Task 9: 创建 MazeTool 入口

**Files:**
- Create: `app/lib/tools/maze/maze_tool.dart`

- [ ] **Step 1: 编写 maze_tool.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/services/tool_registry.dart';
import 'maze_page.dart';

class MazeTool implements ToolModule {
  @override
  String get id => 'maze';

  @override
  String get name => '迷宫';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.route;

  @override
  ToolCategory get category => ToolCategory.game;

  @override
  int get gridSize => 1;

  @override
  Widget buildPage(BuildContext context) {
    return const MazePage();
  }

  @override
  ToolSettings? get settings => null;

  @override
  Future<void> onInit() async {}

  @override
  Future<void> onDispose() async {}

  @override
  void onEnter() {}

  @override
  void onExit() {}
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/tools/maze/maze_tool.dart
git commit -m "feat: add MazeTool module entry"
```

---

## Task 10: 注册 MazeTool

**Files:**
- Modify: `app/lib/main.dart`

- [ ] **Step 1: 读取 main.dart 查看现有结构**

先让我们查看一下 main.dart 的当前内容，找到正确的注册位置：

```bash
cat app/lib/main.dart | head -100
```

- [ ] **Step 2: 添加导入语句**

在 main.dart 顶部 imports 区域添加：

```dart
import 'tools/maze/maze_tool.dart';
```

- [ ] **Step 3: 注册工具**

在 `ToolRegistry.registerAll` 调用处添加：

```dart
MazeTool(),
```

- [ ] **Step 4: Commit**

```bash
git add app/lib/main.dart
git commit -m "feat: register MazeTool in main.dart"
```

---

## Task 11: 验证和测试

**Files:**
- All maze files

- [ ] **Step 1: 运行 Flutter analyze**

```bash
cd app && flutter analyze lib/tools/maze/
```

预期：无错误

- [ ] **Step 2: 检查文件完整性**

```bash
ls -la app/lib/tools/maze/
ls -la app/lib/tools/maze/widgets/
```

应该包含：
- maze/maze_tool.dart
- maze/maze_page.dart
- maze/maze_game_page.dart
- maze/maze_logic.dart
- maze/maze_generator.dart
- maze/maze_models.dart
- maze/maze_storage.dart
- maze/maze_themes.dart
- maze/widgets/maze_board.dart
- maze/widgets/virtual_joystick.dart

- [ ] **Step 3: 检查 vector_math 依赖**

```bash
grep "vector_math" app/pubspec.yaml
```

如果没有，添加：

```yaml
dependencies:
  vector_math: ^2.1.4
```

然后运行：

```bash
cd app && flutter pub get
```

---

## 完成标准

- [ ] 目录结构和数据模型已创建
- [ ] Prim 算法迷宫生成器已实现
- [ ] BFS 寻路算法已实现
- [ ] 游戏逻辑和持续移动控制器已实现
- [ ] 本地存储已实现
- [ ] 主题配置已实现
- [ ] Widget 组件已创建（迷宫画布、虚拟方向按键）
- [ ] 入口页面已创建
- [ ] 游戏页面已创建
- [ ] MazeTool 入口已创建
- [ ] main.dart 已注册 MazeTool
- [ ] Flutter analyze 无错误
- [ ] 所有 imports 正确

---

## 后续优化（可选，不在本计划内）

1. 多人对战模式
2. 限时挑战模式
3. 收集道具/金币
4. 多种迷宫生成算法（递归回溯、Kruskal、Eller）
5. 成就系统
6. 自定义主题颜色
7. 分享迷宫给好友
8. 音效和震动反馈
