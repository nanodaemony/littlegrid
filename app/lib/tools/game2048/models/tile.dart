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
