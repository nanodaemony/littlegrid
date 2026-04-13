# 注册后自动登录实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复注册成功后还需要手动登录的问题，注册完成直接跳转回首页并显示已登录状态

**Architecture:** 修改 register_page.dart 中注册成功后的导航逻辑，使用 popUntil 直接返回到首页，而不是只返回到登录页

**Tech Stack:** Flutter, Provider

---

## 文件结构映射

| 文件 | 职责 | 变更类型 |
|------|------|----------|
| `app/lib/pages/login/register_page.dart` | 注册页面，修改注册成功后的导航逻辑 | 修改 |

---

## Task 1: 修改注册页面的导航逻辑

**Files:**
- Modify: `app/lib/pages/login/register_page.dart:115`

- [ ] **Step 1: 读取当前 register_page.dart 文件**

先确认文件内容：
```bash
cat app/lib/pages/login/register_page.dart | grep -n -A 5 -B 5 "Navigator.of(context).pop"
```

- [ ] **Step 2: 修改注册成功后的导航代码**

找到注册成功后的代码段（约第 115 行）：

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('注册成功')),
);
Navigator.of(context).pop();
```

修改为：

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('注册成功')),
);
// 直接返回到首页，跳过登录页
Navigator.of(context).popUntil((route) => route.isFirst);
```

- [ ] **Step 3: 验证修改后的文件**

运行 flutter analyze 检查语法错误：
```bash
cd app && flutter analyze lib/pages/login/register_page.dart
```

预期：无错误

- [ ] **Step 4: 提交修改**

```bash
git add app/lib/pages/login/register_page.dart
git commit -m "fix: auto-login after registration

- Change navigation from single pop to popUntil to first route
- User is now automatically logged in after registration
- Skips the login page and goes directly to ProfilePage

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>"
```

---

## Task 2: 验证功能

**Files:**
- Test: Manual testing in app

- [ ] **Step 1: 启动 APP**

```bash
cd app && flutter run
```

- [ ] **Step 2: 测试注册流程**

手动测试步骤：
1. 进入"我的"页面
2. 点击"登录 / 注册"按钮
3. 点击"还没有账号？去注册"
4. 填写手机号、密码、确认密码
5. 点击"注册"按钮
6. 验证：注册成功后直接回到"我的"页面
7. 验证："我的"页面显示用户昵称和已登录状态

- [ ] **Step 3: 验证 token 已保存**

在 debug 页面或通过日志验证：
- SecureStorage 中已保存 auth_token
- SecureStorage 中已保存 auth_user

---

## Spec Coverage Check

| 设计文档要求 | 对应任务 |
|-------------|---------|
| 修改 register_page.dart 导航逻辑 | Task 1 |
| 使用 popUntil((route) => route.isFirst) | Task 1 |
| 注册成功后直接回到 ProfilePage | Task 1, Task 2 |
| ProfilePage 显示已登录状态 | Task 2 |

---

## Placeholder Scan

检查无以下问题：
- ✅ 无 "TBD", "TODO"
- ✅ 无 "Add appropriate error handling"
- ✅ 所有代码步骤都有完整代码
- ✅ 无 "Similar to Task N"
- ✅ 所有文件路径都是完整路径
