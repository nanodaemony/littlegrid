# 2048 游戏工具实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 "小方格" Flutter 应用实现 2048 数字合并游戏工具，支持无限大数字、渐变色彩 UI 和完整游戏体验。

**Architecture:** 遵循现有工具模块化架构，实现 ToolModule 接口，包含独立的游戏逻辑、UI 页面和数据模型。使用 Provider/State 管理游戏状态，SharedPreferences 持久化数据。

**Tech Stack:** Flutter 3.0+, Dart 3.0+, Material 3, shared_preferences, flutter_animate (可选)

---

## 目录结构预览

```
app/lib/tools/game2048/
├── game2048_tool.dart          # ToolModule 实现
├── game2048_page.dart          # 游戏页面
├── game2048_logic.dart         # 游戏核心逻辑
├── game2048_board.dart         # 棋盘组件
├── game2048_colors.dart        # 数字颜色配置
├── models/
│   ├── tile.dart               # 格子数据模型
│   └── game_state.dart         # 游戏状态模型
└── widgets/
    ├── tile_widget.dart        # 数字格子组件
    ├── score_card.dart         # 分数卡片组件
    └── game_over_dialog.dart   # 游戏结束弹窗
```

---

## Task 1: 创建目录结构和数据模型

**目标:** 建立 2048 工具的基础目录结构和核心数据模型。

**预计工作量:** 20-30 分钟

**依赖:** 无

---

- [ ] **Step 1.1: 创建目录结构**

**运行命令:**
```bash
mkdir -p app/lib/tools/game2048/models
mkdir -p app/lib/tools/game2048/widgets
touch app/lib/tools/game2048/game2048_tool.dart
touch app/lib/tools/game2048/game2048_page.dart
touch app/lib/tools/game2048/game2048_logic.dart
touch app/lib/tools/game2048/game2048_board.dart
touch app/lib/tools/game2048/game2048_colors.dart
touch app/lib/tools/game2048/models/tile.dart
touch app/lib/tools/game2048/models/game_state.dart
touch app/lib/tools/game2048/widgets/tile_widget.dart
touch app/lib/tools/game2048/widgets/score_card.dart
touch app/lib/tools/game2048/widgets/game_over_dialog.dart
```

**验证:** 目录结构已创建
```bash
ls -la app/lib/tools/game2048/
```

---

- [ ] **Step 1.2: 实现 Tile 数据模型**

**文件:** `app/lib/tools/game2048/models/tile.dart`

**代码:**
```dart
/// 2048 游戏格子数据模型
class Tile {
  /// 数字值
  final int value;

  /// 行位置 (0-3)
  final int row;

  /// 列位置 (0-3)
  final int col;

  /// 是否新生成（用于动画）
  final bool isNew;

  /// 是否刚合并（用于动画）
  final bool isMerged;

  /// 唯一标识符（用于动画追踪）
  final int id;

  static int _nextId = 0;

  Tile({
    required this.value,
    required this.row,
    required this.col,
    this.isNew = false,
    this.isMerged = false,
    int? id,
  }) : id = id ?? _nextId++;

  /// 创建副本，可修改部分属性
  Tile copyWith({
    int? value,
    int? row,
    int? col,
    bool? isNew,
    bool? isMerged,
    int? id,
  }) {
    return Tile(
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      isNew: isNew ?? this.isNew,
      isMerged: isMerged ?? this.isMerged,
      id: id ?? this.id,
    );
  }

  /// 重置 ID 计数器（用于新游戏）
  static void resetIdCounter() {
    _nextId = 0;
  }

  @override
  String toString() {
    return 'Tile($value)[$row,$col]';
  }
}
```

---

- [ ] **Step 1.3: 实现 GameState 数据模型**

**文件:** `app/lib/tools/game2048/models/game_state.dart`

**代码:**
```dart
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
```

---

- [ ] **Step 1.4: 提交 Task 1**

**运行命令:**
```bash
cd /home/nano/little-grid/.worktrees/feature-2048
git add app/lib/tools/game2048/
git commit -m "feat(2048): add data models and directory structure

- Add Tile model with animation support
- Add GameState model with undo history
- Create directory structure for 2048 tool

Refs: feature-2048"
```

---

## 后续任务概览

### Task 2: 实现颜色配置和工具注册 (预计 20 分钟)
- game2048_colors.dart - 数字颜色配置
- game2048_tool.dart - ToolModule 实现

### Task 3: 实现核心游戏逻辑 (预计 40 分钟)
- game2048_logic.dart - 移动、合并、得分算法

### Task 4: 实现 UI 组件 (预计 50 分钟)
- widgets/tile_widget.dart
- widgets/score_card.dart
- widgets/game_over_dialog.dart
- game2048_board.dart
- game2048_page.dart

### Task 5: 实现数据持久化和注册 (预计 20 分钟)
- 添加 shared_preferences 依赖
- 实现存储服务
- 在 main.dart 注册工具

**总计预计时间: 2.5-3 小时**

---

**下一步**: 完成 Task 1 后，继续 Task 2 实现颜色配置和工具注册。
