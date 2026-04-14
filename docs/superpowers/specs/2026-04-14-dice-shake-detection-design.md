# 骰子摇晃检测功能设计文档

**日期：** 2026-04-14
**作者：** Claude
**状态：** 已批准

---

## 1. 需求概述

为现有的骰子工具添加摇晃手机触发掷骰子的功能，保留原有的按钮触发方式。

### 1.1 功能需求
- 摇晃手机时自动触发掷骰子
- 保持原有的"投掷"按钮功能不变
- 中等灵敏度的摇晃检测（平衡误触和易用性）
- 防抖机制：触发后1秒内不重复响应
- 仅在骰子页面激活时监听传感器

### 1.2 限制条件
- 仅在骰子页面生效
- 不影响其他工具功能
- 不破坏现有代码结构

---

## 2. 架构设计

### 2.1 修改文件
```
app/lib/tools/dice/dice_page.dart    # 唯一修改文件
```

### 2.2 新增依赖
| 依赖 | 版本 | 用途 |
|------|------|------|
| sensors_plus | ^4.0.2 | 加速度传感器监听 |

### 2.3 实现方案
采用**方案 A：简单实现**，在 `_DicePageState` 中直接集成摇晃检测逻辑。

---

## 3. 详细设计

### 3.1 摇晃检测算法

**传感器选择：**
- 使用 `userAccelerometerEvent`（排除重力影响，只检测用户动作）

**检测阈值：**
- 中度灵敏度：15 m/s²
- 计算方式：`sqrt(dx² + dy² + dz²)`

**防抖机制：**
- 记录上次触发时间 `_lastShakeTime`
- 两次触发间隔至少 1 秒

### 3.2 生命周期管理

| 生命周期 | 操作 |
|----------|------|
| `initState` | 初始化传感器监听 |
| `dispose` | 取消传感器订阅 |

### 3.3 状态变量

```dart
// 新增状态变量
StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
DateTime? _lastShakeTime;
double? _lastX, _lastY, _lastZ;

// 已有状态变量（保持不变）
final Random _random = Random();
List<int> _diceValues = [1];
int _diceCount = 1;
bool _isRolling = false;
Timer? _rollTimer;
```

### 3.4 核心逻辑

**传感器监听回调：**
```dart
void _onAccelerometerEvent(UserAccelerometerEvent event) {
  if (_lastX == null || _lastY == null || _lastZ == null) {
    _lastX = event.x;
    _lastY = event.y;
    _lastZ = event.z;
    return;
  }

  final dx = event.x - _lastX!;
  final dy = event.y - _lastY!;
  final dz = event.z - _lastZ!;

  final acceleration = sqrt(dx * dx + dy * dy + dz * dz);

  if (acceleration > 15) {
    final now = DateTime.now();
    if (_lastShakeTime == null ||
        now.difference(_lastShakeTime!) > const Duration(seconds: 1)) {
      _lastShakeTime = now;
      _rollDice();
      // 可选：轻微震动反馈
    }
  }

  _lastX = event.x;
  _lastY = event.y;
  _lastZ = event.z;
}
```

---

## 4. 交互体验

### 4.1 用户体验
- 摇晃触发时复用现有的 `_rollDice()` 方法，保持一致的动画效果
- 原有按钮功能完全保留
- 无视觉变化，行为自然

### 4.2 震动反馈（可选）
利用已有的 `vibration: ^2.0.0` 依赖，摇晃时触发轻微震动：
```dart
Vibration.vibrate(duration: 50);
```

---

## 5. 测试要点

### 5.1 功能测试
- [ ] 摇晃手机能触发掷骰子
- [ ] 按钮触发仍然正常工作
- [ ] 快速连续摇晃只触发一次（防抖）
- [ ] 离开页面后摇晃不触发

### 5.2 灵敏度测试
- [ ] 轻度摇晃不会误触
- [ ] 中度摇晃正常触发
- [ ] 灵敏度适中，用户体验良好

---

## 6. 依赖

| 依赖 | 用途 |
|------|------|
| `sensors_plus: ^4.0.2` | 加速度传感器数据 |
| `dart:async` | StreamSubscription |
| `dart:math` | sqrt 计算 |
| `vibration: ^2.0.0` | 震动反馈（已有） |

---

## 7. 变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-14 | 1.0.0 | 初始设计文档 |
