---
name: Grid Sort Order Change
description: Change homepage grid sort order from last-used to name-based, keeping pin feature
type: project
---

# 首页功能格子排序改造设计文档

## 概述

修改 APP 首页功能格子的排序逻辑，去掉"点击后跑到最前面"的功能，改为按功能名称排序，同时保留置顶功能。

## 背景

当前行为：
- 功能格子按「置顶 → 最后使用时间 → sortOrder」排序
- 每次点击打开工具后，该工具会更新 `lastUsedAt` 时间戳并跑到最前面
- 用户希望顺序稳定，按功能名称排序更容易找到工具

## 需求

1. 去掉点击工具后排序变化的功能
2. 整体顺序按照格子的功能名称排序
3. 保留置顶功能（置顶的工具仍然显示在最前面）

## 设计方案

### 修改范围

仅修改一个文件：`app/lib/providers/app_provider.dart`

### 详细设计

#### 1. 修改 `getSortedTools()` 方法

**位置**: `app/lib/providers/app_provider.dart` 第 98-118 行

**当前逻辑**:
```dart
List<ToolConfig> getSortedTools() {
  final sorted = List<ToolConfig>.from(_toolConfigs);

  // 按置顶和最后使用时间排序
  sorted.sort((a, b) {
    // 置顶优先
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;

    // 然后按最后使用时间
    if (a.lastUsedAt != null && b.lastUsedAt != null) {
      return b.lastUsedAt!.compareTo(a.lastUsedAt!);
    }
    if (a.lastUsedAt != null) return -1;
    if (b.lastUsedAt != null) return 1;

    return a.sortOrder.compareTo(b.sortOrder);
  });

  return sorted;
}
```

**新逻辑**:
```dart
List<ToolConfig> getSortedTools() {
  final sorted = List<ToolConfig>.from(_toolConfigs);

  // 按置顶和功能名称排序
  sorted.sort((a, b) {
    // 置顶优先
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;

    // 按功能名称排序（字母/拼音顺序）
    return a.name.compareTo(b.name);
  });

  return sorted;
}
```

### 数据流向

- 打开工具时仍然调用 `recordToolUse()` → 更新 `useCount` 和 `lastUsedAt`（仅用于统计，不影响排序）
- 置顶功能通过长按菜单继续工作
- 格子显示顺序：
  1. 置顶的工具按名称排序
  2. 非置顶的工具按名称排序

### 保留的功能

- 置顶/取消置顶（长按菜单）
- 使用次数统计（`useCount`）
- 最后使用时间记录（`lastUsedAt`）

### 移除的功能

- 按最后使用时间排序

## 测试计划

1. 验证首页格子按名称排序显示
2. 验证置顶功能正常工作（置顶的工具在最前面，内部按名称排序）
3. 验证打开工具后顺序不发生变化
4. 验证长按置顶/取消置顶功能正常

## 风险评估

- 低风险：仅修改排序逻辑，不涉及数据结构变更
- 回滚方案：恢复原有的 `getSortedTools()` 方法即可

## 时间估算

- 编码：5 分钟
- 测试：10 分钟
- 总计：15 分钟
