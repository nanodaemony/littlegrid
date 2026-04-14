# 骰子摇晃检测功能实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为骰子页面添加摇晃手机触发掷骰子的功能，保留原有的按钮触发方式。

**Architecture:** 在 `_DicePageState` 中直接集成 `sensors_plus` 加速度传感器监听，检测摇晃动作并触发 `_rollDice()`。

**Tech Stack:** Flutter, sensors_plus, dart:async, dart:math

---

## 文件结构

| 文件 | 操作 | 说明 |
|------|------|------|
| `app/pubspec.yaml` | 已修改 | 已添加 `sensors_plus: ^4.0.2` |
| `app/lib/tools/dice/dice_page.dart` | 修改 | 添加摇晃检测逻辑 |

---

### Task 1: 确认 pubspec.yaml 依赖并运行 flutter pub get

**Files:**
- Verify: `app/pubspec.yaml`

- [ ] **Step 1: 确认 sensors_plus 依赖已添加**

检查 `app/pubspec.yaml` 包含:
```yaml
  # 传感器（用于摇晃检测）
  sensors_plus: ^4.0.2
```

- [ ] **Step 2: 运行 flutter pub get**

Run:
```bash
cd /home/nano/little-grid2/app
flutter pub get
```

Expected: 依赖安装成功，无错误

---

### Task 2: 修改 dice_page.dart 添加导入和状态变量

**Files:**
- Modify: `app/lib/tools/dice/dice_page.dart`

- [ ] **Step 1: 添加 sensors_plus 导入**

在文件顶部添加:
```dart
import 'package:sensors_plus/sensors_plus.dart';
```

最终导入部分应为:
```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';
```

- [ ] **Step 2: 添加状态变量**

在 `_DicePageState` 类中，在现有变量后添加:
```dart
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  double? _lastX, _lastY, _lastZ;
  static const double _shakeThreshold = 15.0;
  static const Duration _shakeCooldown = Duration(seconds: 1);
```

完整变量列表:
```dart
  final Random _random = Random();
  List<int> _diceValues = [1];
  int _diceCount = 1;
  bool _isRolling = false;
  Timer? _rollTimer;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  double? _lastX, _lastY, _lastZ;
  static const double _shakeThreshold = 15.0;
  static const Duration _shakeCooldown = Duration(seconds: 1);
```

---

### Task 3: 添加 initState 传感器初始化逻辑

**Files:**
- Modify: `app/lib/tools/dice/dice_page.dart`

- [ ] **Step 1: 添加 initState 方法**

在 `dispose()` 方法之前添加:
```dart
  @override
  void initState() {
    super.initState();
    _startListeningToAccelerometer();
  }
```

- [ ] **Step 2: 添加 _startListeningToAccelerometer 方法**

在 `_rollDice()` 方法之后添加:
```dart
  void _startListeningToAccelerometer() {
    _accelerometerSubscription = userAccelerometerEventStream.listen(
      _onAccelerometerEvent,
      onError: (error) {
        // 忽略传感器错误
      },
      cancelOnError: false,
    );
  }

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

    if (acceleration > _shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!) > _shakeCooldown) {
        _lastShakeTime = now;
        _rollDice();
      }
    }

    _lastX = event.x;
    _lastY = event.y;
    _lastZ = event.z;
  }
```

---

### Task 4: 更新 dispose 方法清理资源

**Files:**
- Modify: `app/lib/tools/dice/dice_page.dart`

- [ ] **Step 1: 更新 dispose 方法**

修改 `dispose()` 方法，添加传感器订阅取消:
```dart
  @override
  void dispose() {
    _rollTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
```

---

### Task 5: 验证完整代码并测试

**Files:**
- Verify: `app/lib/tools/dice/dice_page.dart`

- [ ] **Step 1: 确认完整代码结构**

完整的 `_DicePageState` 应包含:
1. 导入语句（含 sensors_plus）
2. 所有状态变量
3. initState 方法
4. dispose 方法
5. _rollDice 方法
6. _startListeningToAccelerometer 方法
7. _onAccelerometerEvent 方法
8. build 方法

- [ ] **Step 2: 运行 flutter analyze 检查错误**

Run:
```bash
cd /home/nano/little-grid2/app
flutter analyze lib/tools/dice/dice_page.dart
```

Expected: 无错误，无警告

- [ ] **Step 3: 提交更改**

```bash
cd /home/nano/little-grid2
git add app/pubspec.yaml app/lib/tools/dice/dice_page.dart docs/superpowers/specs/2026-04-14-dice-shake-detection-design.md docs/superpowers/plans/2026-04-14-dice-shake-detection-plan.md
git commit -m "feat: add shake detection for dice tool

- Add sensors_plus dependency
- Implement shake detection in DicePage
- 15 m/s² threshold with 1 second cooldown
- Clean up sensor subscription on dispose

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

## 完整修改后的 dice_page.dart 参考

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  final Random _random = Random();
  List<int> _diceValues = [1];
  int _diceCount = 1;
  bool _isRolling = false;
  Timer? _rollTimer;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  double? _lastX, _lastY, _lastZ;
  static const double _shakeThreshold = 15.0;
  static const Duration _shakeCooldown = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _startListeningToAccelerometer();
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _rollDice() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    // 随机点数切换动画
    int elapsed = 0;
    const interval = 60; // 每60ms切换一次
    const duration = 600; // 总时长600ms

    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(milliseconds: interval), (timer) {
      setState(() {
        _diceValues = List.generate(
          _diceCount,
          (_) => _random.nextInt(6) + 1,
        );
      });

      elapsed += interval;
      if (elapsed >= duration) {
        timer.cancel();
        setState(() {
          _isRolling = false;
        });
      }
    });
  }

  void _startListeningToAccelerometer() {
    _accelerometerSubscription = userAccelerometerEventStream.listen(
      _onAccelerometerEvent,
      onError: (error) {
        // 忽略传感器错误
      },
      cancelOnError: false,
    );
  }

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

    if (acceleration > _shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!) > _shakeCooldown) {
        _lastShakeTime = now;
        _rollDice();
      }
    }

    _lastX = event.x;
    _lastY = event.y;
    _lastZ = event.z;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('骰子'),
      ),
      body: Column(
        children: [
          // 骰子数量选择
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('骰子数量:'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _diceCount > 1
                      ? () {
                          setState(() {
                            _diceCount--;
                            _diceValues = List.filled(_diceCount, 1);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$_diceCount',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _diceCount < 6
                      ? () {
                          setState(() {
                            _diceCount++;
                            _diceValues = List.filled(_diceCount, 1);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // 骰子显示区
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: _diceValues.map((value) {
                  return _DiceWidget(
                    value: value,
                    isRolling: _isRolling,
                  );
                }).toList(),
              ),
            ),
          ),

          // 点数总和
          if (_diceValues.length > 1 && !_isRolling)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '总和: ${_diceValues.reduce((a, b) => a + b)}',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().scale(),
            ),

          // 投掷按钮
          Padding(
            padding: const EdgeInsets.all(32),
            child: ElevatedButton.icon(
              onPressed: _isRolling ? null : _rollDice,
              icon: const Icon(Icons.casino),
              label: const Text('投掷'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceWidget extends StatelessWidget {
  final int value;
  final bool isRolling;

  const _DiceWidget({required this.value, required this.isRolling});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: _buildDots(value),
    ).animate(target: isRolling ? 1 : 0).shake();
  }

  Widget _buildDots(int value) {
    final dotColor = Colors.red.shade600;
    final dotSize = 12.0;

    Widget dot() => Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );

    switch (value) {
      case 1:
        return Center(child: dot());
      case 2:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [dot(), const Spacer(), dot()],
          ),
        );
      case 3:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [dot(), Center(child: dot()), dot()],
          ),
        );
      case 4:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dot(), dot()],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dot(), dot()],
              ),
            ],
          ),
        );
      case 5:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dot(), dot()],
              ),
              Center(child: dot()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dot(), dot()],
              ),
            ],
          ),
        );
      case 6:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dot(), dot()],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dot(), dot()],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [dot(), dot()],
              ),
            ],
          ),
        );
      default:
        return Center(child: dot());
    }
  }
}
```
