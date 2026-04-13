---
name: 注册后自动登录
description: 修复注册成功后还需要手动登录的问题，注册完成直接跳转回首页并显示已登录状态
type: project
---

# 注册后自动登录设计文档

## 概述

修复 APP 注册流程中的用户体验问题：当前注册成功后会返回登录页，用户需要手动再次输入密码登录。实际上注册接口已经返回了 token，用户应该直接处于登录状态。

## 问题分析

### 当前流程

```
ProfilePage (未登录)
  ↓ 点击"登录 / 注册"按钮
  push → LoginPage
    ↓ 点击"还没有账号？去注册"
    push → RegisterPage
      ↓ 填写信息并注册成功
      ↓ 保存 token 和用户信息 ✓
      ↓ 设置登录状态 ✓
      pop() → LoginPage (问题所在！)
        ↓ 用户需要手动输入密码再次登录
```

### 问题根源

1. **后端**：注册接口 `/api/app/auth/register` 已经返回 token 和用户信息（与登录接口一致）
2. **前端 AuthService**：`register()` 方法已经调用 `_saveAuthData()` 保存 token 和用户信息
3. **前端 AuthProvider**：`register()` 方法已经设置 `_isLoggedIn = true` 和 `_currentUser`
4. **唯一问题**：注册成功后导航只执行了一次 `pop()`，返回到了 LoginPage 而不是 ProfilePage

### 期望流程

```
ProfilePage (未登录)
  ↓ push → LoginPage
    ↓ push → RegisterPage
      ↓ 注册成功
      ↓ 保存 token 和用户信息 ✓
      ↓ 设置登录状态 ✓
      popUntil() → ProfilePage (直接显示已登录状态)
```

## 解决方案

### 技术方案

修改 `register_page.dart` 中的注册成功后的导航逻辑，使用 `popUntil()` 直接返回到 ProfilePage，而不是只返回到 LoginPage。

### 修改详情

**文件**：`app/lib/pages/login/register_page.dart`

**修改位置**：第 115 行附近，注册成功后的导航部分

**当前代码**：
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('注册成功')),
);
Navigator.of(context).pop();
```

**修改后代码**：
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('注册成功')),
);
// 直接返回到首页，跳过登录页
Navigator.of(context).popUntil((route) => route.isFirst);
```

### 为什么使用 `popUntil((route) => route.isFirst)`

1. **简单可靠**：直接返回到导航栈的第一个路由（MainPage）
2. **符合当前架构**：MainPage 包含 ProfilePage，返回后 ProfilePage 会通过 `Consumer<AuthProvider>` 自动刷新显示已登录状态
3. **最小改动**：只修改一行代码，风险最低

### 验证点

修改后需要验证：

1. 注册成功后直接回到"我的"页面 ✓
2. "我的"页面显示用户昵称和已登录状态 ✓
3. Token 已正确保存到 SecureStorage ✓
4. 可以正常使用需要登录的功能 ✓

## 不涉及的改动

- 后端接口：无需修改，注册接口已经返回 token
- AuthService：无需修改，已经保存认证数据
- AuthProvider：无需修改，已经设置登录状态
- LoginPage：无需修改
- ProfilePage：无需修改（已有 Consumer 监听状态变化）

## 风险评估

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| 导航栈结构变化导致 popUntil 失效 | 中 | 低 | 使用 route.isFirst 最稳定 |
| ProfilePage 未正确刷新状态 | 低 | 低 | 已有 Consumer 监听 AuthProvider |

## 后续优化（可选）

如果未来导航结构更复杂，可以考虑：

1. 使用命名路由（Named Routes）来更精确地控制返回目标
2. 在 LoginPage 添加登录状态监听，已登录时自动 pop

但当前方案对于现有架构已经足够简单可靠。
