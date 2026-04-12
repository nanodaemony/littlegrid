# 个人信息与设置页面优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 优化【我的】页面和设置页面，新增【我的信息】编辑页面和后端更新接口

**Architecture:** 按现有架构逐步修改，保持代码风格一致，改动集中易于测试

**Tech Stack:** Flutter (frontend), Spring Boot (backend)

---

## 文件结构

**Frontend:**
- 新建: `app/lib/pages/my_info_page.dart` - 我的信息编辑页面
- 修改: `app/lib/pages/profile_page.dart` - 简化我的页面
- 修改: `app/lib/pages/settings_page.dart` - 添加我的信息入口和退出登录按钮
- 修改: `app/lib/core/services/auth_service.dart` - 添加更新用户信息方法
- 修改: `app/lib/providers/auth_provider.dart` - 添加更新用户信息方法

**Backend:**
- 新建: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/UpdateUserDTO.java` - 更新用户信息DTO
- 修改: `backend/grid-app/src/main/java/com/naon/grid/modules/app/rest/AppAuthController.java` - 新增更新接口
- 修改: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/AppAuthService.java` - 新增service方法
- 修改: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/impl/AppAuthServiceImpl.java` - 实现service方法

---

## 实现任务

### Task 1: 后端 - 新增 UpdateUserDTO

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/UpdateUserDTO.java`

- [ ] **Step 1: 创建 UpdateUserDTO.java**

```java
package com.naon.grid.modules.app.service.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

@Data
public class UpdateUserDTO {
    @ApiModelProperty(value = "昵称")
    private String nickname;

    @ApiModelProperty(value = "邮箱")
    private String email;
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/nano/claude/little-grid
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/UpdateUserDTO.java
git commit -m "feat: add UpdateUserDTO for updating user info"
```

---

### Task 2: 后端 - Service 接口与实现

**Files:**
- Modify: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/AppAuthService.java`
- Modify: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/impl/AppAuthServiceImpl.java`

- [ ] **Step 1: 在 AppAuthService 接口新增方法**

在 `AppAuthService.java` 末尾添加:

```java
    AppUserDTO updateUser(Long userId, UpdateUserDTO updateUserDTO);
```

- [ ] **Step 2: 在 AppAuthServiceImpl 实现该方法**

在 `AppAuthServiceImpl.java` 末尾添加:

```java
    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppUserDTO updateUser(Long userId, UpdateUserDTO updateUserDTO) {
        GridUser user = userRepository.findById(userId)
                .orElseThrow(() -> new BadRequestException("用户不存在"));

        if (StrUtil.isNotBlank(updateUserDTO.getNickname())) {
            user.setNickname(updateUserDTO.getNickname());
        }
        if (StrUtil.isNotBlank(updateUserDTO.getEmail())) {
            user.setEmail(updateUserDTO.getEmail());
        }

        userRepository.save(user);
        return convertToDTO(user);
    }
```

注意: 确保文件顶部已导入 `UpdateUserDTO` 和所需的其他类。

- [ ] **Step 3: Commit**

```bash
cd /Users/nano/claude/little-grid
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/service/AppAuthService.java
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/service/impl/AppAuthServiceImpl.java
git commit -m "feat: add updateUser service method"
```

---

### Task 3: 后端 - Controller 新增更新接口

**Files:**
- Modify: `backend/grid-app/src/main/java/com/naon/grid/modules/app/rest/AppAuthController.java`

- [ ] **Step 1: 在 AppAuthController 新增接口**

在 `AppAuthController.java` 末尾添加:

```java
    @Log("APP用户更新信息")
    @ApiOperation("更新用户信息")
    @PostMapping("/user/update")
    public ResponseEntity<AppUserDTO> updateUser(@Validated @RequestBody UpdateUserDTO updateUserDTO) {
        Long userId = SecurityUtils.getCurrentUserId();
        AppUserDTO userDTO = appAuthService.updateUser(userId, updateUserDTO);
        return ResponseEntity.ok(userDTO);
    }
```

注意: 确保文件顶部已导入 `UpdateUserDTO`。

- [ ] **Step 2: Commit**

```bash
cd /Users/nano/claude/little-grid
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/rest/AppAuthController.java
git commit -m "feat: add update user info endpoint"
```

---

### Task 4: 前端 - AuthService 添加更新方法

**Files:**
- Modify: `app/lib/core/services/auth_service.dart`

- [ ] **Step 1: 在 AuthService 新增 updateUser 方法**

在 `auth_service.dart` 末尾添加:

```dart
  /// Update user info
  static Future<User> updateUser({String? nickname, String? email}) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('请先登录');
    }

    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickname'] = nickname;
    if (email != null) body['email'] = email;

    final response = await HttpClient.post(
      Uri.parse('$_baseUrl/user/update'),
      headers: {'Authorization': token},
      body: body,
      module: 'AuthService',
    );

    if (response.statusCode == 200) {
      final userJson = jsonDecode(response.body);
      final user = User.fromJson(userJson);
      await SecureStorage.saveUser(user.toJsonString());
      return user;
    } else {
      throw Exception('更新失败: ${response.body}');
    }
  }
```

- [ ] **Step 2: Commit**

```bash
cd /Users/nano/claude/little-grid
git add app/lib/core/services/auth_service.dart
git commit -m "feat: add updateUser method to AuthService"
```

---

### Task 5: 前端 - AuthProvider 添加更新方法

**Files:**
- Modify: `app/lib/providers/auth_provider.dart`

- [ ] **Step 1: 在 AuthProvider 新增 updateUser 方法**

在 `auth_provider.dart` 末尾添加:

```dart
  /// Update user info
  Future<bool> updateUser({String? nickname, String? email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await AuthService.updateUser(nickname: nickname, email: email);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
```

- [ ] **Step 2: Commit**

```bash
cd /Users/nano/claude/little-grid
git add app/lib/providers/auth_provider.dart
git commit -m "feat: add updateUser method to AuthProvider"
```

---

### Task 6: 前端 - 简化【我的】页面

**Files:**
- Modify: `app/lib/pages/profile_page.dart`

- [ ] **Step 1: 修改 _buildLoggedInUser 方法**

将 `_buildLoggedInUser` 方法替换为:

```dart
  Widget _buildLoggedInUser(User user) {
    return Column(
      children: [
        Text(
          user.nickname ?? '用户',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 2: 移除头像点击事件**

在 `_buildUserCard` 方法中，将 `GestureDetector` 包裹的头像改为普通 Container:

```dart
                  // 头像
                  _buildAvatar(appProvider.avatarPath),
```

同时可以移除不再使用的 `_onAvatarTap` 方法和 `_editNickname` 方法，以及 `_nickname` 状态变量（如果未使用）。

- [ ] **Step 3: Commit**

```bash
cd /Users/nano/claude/little-grid
git add app/lib/pages/profile_page.dart
git commit -m "feat: simplify profile page to show only avatar and nickname"
```

---

### Task 7: 前端 - 修改设置页面

**Files:**
- Modify: `app/lib/pages/settings_page.dart`

- [ ] **Step 1: 添加必要的导入**

在文件顶部添加:

```dart
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'my_info_page.dart';
```

- [ ] **Step 2: 修改 SettingsPage 为 StatefulWidget 并添加退出登录逻辑**

将 `_SettingsPageState` 类修改，添加退出登录方法:

```dart
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
```

- [ ] **Step 3: 修改 build 方法，添加账号section和退出登录按钮**

将 `build` 方法的 `ListView` children 修改为:

```dart
          // 外观设置
          _buildSectionHeader('外观'),
          _buildSwitchItem(
            icon: Icons.dark_mode,
            title: '深色模式',
            subtitle: '跟随系统',
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
            },
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: '语言',
            subtitle: _language,
            onTap: () => _showLanguageDialog(),
          ),

          const Divider(),

          // 通知设置
          _buildSectionHeader('通知'),
          _buildSwitchItem(
            icon: Icons.notifications,
            title: '推送通知',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),

          const Divider(),

          // 账号设置
          _buildSectionHeader('账号'),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: '我的信息',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyInfoPage(),
                ),
              );
            },
          ),

          const Divider(),

          // 数据管理
          _buildSectionHeader('数据'),
          _buildMenuItem(
            icon: Icons.download,
            title: '导出数据',
            onTap: () {
              // TODO: 导出数据
            },
          ),
          _buildMenuItem(
            icon: Icons.delete_outline,
            title: '清除缓存',
            subtitle: '12.5 MB',
            onTap: () => _showClearCacheDialog(),
          ),

          const Divider(),

          // 其他
          _buildSectionHeader('其他'),
          _buildMenuItem(
            icon: Icons.update,
            title: '检查更新',
            onTap: () {
              // TODO: 检查更新
            },
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip,
            title: '隐私政策',
            onTap: () {
              // TODO: 显示隐私政策
            },
          ),

          const SizedBox(height: 32),

          // 退出登录按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '退出登录',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 32),
```

- [ ] **Step 4: Commit**

```bash
cd /Users/nano/claude/little-grid
git add app/lib/pages/settings_page.dart
git commit -m "feat: add my info option and logout button to settings page"
```

---

### Task 8: 前端 - 新建【我的信息】页面

**Files:**
- Create: `app/lib/pages/my_info_page.dart`

- [ ] **Step 1: 创建 my_info_page.dart**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ui/app_colors.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar_picker.dart';

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nicknameController.text = user?.nickname ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onAvatarTap() async {
    final path = await AvatarPicker.show(context);
    if (path != null && mounted) {
      await context.read<AppProvider>().updateAvatar(path);
    }
  }

  Widget _buildAvatar(String? avatarPath) {
    if (avatarPath == null || AvatarPicker.isDefaultAvatar(avatarPath)) {
      final color = AvatarPicker.getDefaultAvatarColor(avatarPath);
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 50,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
        child: Image.file(
          File(avatarPath),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 50,
              color: AppColors.primary,
            );
          },
        ),
      ),
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 11) return phone ?? '';
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();

    if (nickname.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称不能为空')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateUser(
        nickname: nickname,
        email: email.isNotEmpty ? email : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final avatarPath = context.watch<AppProvider>().avatarPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的信息'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 头像
                Center(
                  child: GestureDetector(
                    onTap: _onAvatarTap,
                    child: Stack(
                      children: [
                        _buildAvatar(avatarPath),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 昵称
                _buildInfoItem(
                  label: '昵称',
                  child: TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      hintText: '请输入昵称',
                      border: InputBorder.none,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                const Divider(height: 1),

                // 手机号
                _buildInfoItem(
                  label: '手机号',
                  child: Text(
                    _maskPhone(user?.phone),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                const Divider(height: 1),

                // 邮箱
                _buildInfoItem(
                  label: '邮箱',
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: '请输入邮箱',
                      border: InputBorder.none,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // 保存按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '保存',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/nano/claude/little-grid
git add app/lib/pages/my_info_page.dart
git commit -m "feat: add my info page for editing user information"
```

---

## 自审查

### 1. Spec 覆盖检查
- ✅ 【我的】页面简化 - Task 6
- ✅ 设置页面添加"我的信息"入口 - Task 7
- ✅ 设置页面底部红色退出登录按钮 - Task 7
- ✅ 【我的信息】页面新建 - Task 8
- ✅ 后端更新接口 - Task 1-3
- ✅ 客户端服务层更新 - Task 4-5
- ✅ 昵称非空校验 - Task 8
- ✅ 头像只保存本地不上传 - Task 8

### 2. 占位符扫描
- ✅ 无 TBD/TODO
- ✅ 所有代码片段完整
- ✅ 所有步骤有明确内容

### 3. 类型一致性检查
- ✅ UpdateUserDTO 字段与接口一致
- ✅ User 模型字段匹配
- ✅ 方法命名一致

---

## 执行

Plan complete and saved to `docs/superpowers/plans/2026-04-12-profile-settings-optimization.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
