---
name: 个人信息与设置页面优化
description: 优化【我的】页面和设置页面，新增【我的信息】编辑页面和后端更新接口
type: spec
---

# 个人信息与设置页面优化设计

## 概述

本次优化主要针对【我的】页面、设置页面进行结构调整，新增个人信息编辑页面，并提供后端更新接口。

## 变更内容

### 1. 【我的】页面简化

**文件：** `app/lib/pages/profile_page.dart`

**改动：**
- 移除头像的点击修改功能
- 简化用户卡片，只保留头像和昵称
- 移除昵称旁边的编辑图标
- 移除手机号展示
- 移除邮箱展示和绑定邮箱按钮
- 移除退出登录按钮

**布局效果：**
- 顶部蓝色渐变卡片
- 中间80x80头像
- 头像下方白色昵称文字（20号字，加粗）
- 整体更简洁清爽

---

### 2. 设置页面改动

**文件：** `app/lib/pages/settings_page.dart`

**改动：**
- 在"数据"section之前，新增"账号"section
- 在"账号"section下添加"我的信息"选项（图标：`Icons.person_outline`）
- 在页面最底部添加红色"退出登录"按钮区域
  - 距离上方32px间距
  - 全屏宽按钮，左右16px边距
  - 红色背景，白色文字
  - 点击后弹出确认对话框
  - 退出成功后返回上一页

**设置页面新结构：**
```
- 外观
  - 深色模式
  - 语言
- 通知
  - 推送通知
- 账号（新增）
  - 我的信息（新增）
- 数据
  - 导出数据
  - 清除缓存
- 其他
  - 检查更新
  - 隐私政策
  
（32px间距）

[红色退出登录按钮]（新增）
```

---

### 3. 【我的信息】页面

**新建文件：** `app/lib/pages/my_info_page.dart`

**页面结构：**
1. AppBar，标题"我的信息"
2. ListView主体内容：
   - **头像区域**（顶部居中）：
     - 100x100尺寸
     - 右下角编辑图标
     - 点击弹出底部选择框：拍照/从相册选择（复用 `AvatarPicker`）
     - 头像仅保存本地，不上传服务端
   - **昵称**：
     - 左侧标签"昵称"
     - 右侧输入框，可编辑
   - **手机号**：
     - 左侧标签"手机号"
     - 右侧脱敏展示（如 138****8888）
     - 不可编辑，无箭头
   - **邮箱**：
     - 左侧标签"邮箱"
     - 右侧输入框，可直接填写修改
     - 无校验逻辑
3. 底部固定"保存"按钮：
   - 全屏宽，左右16px边距
   - 蓝色背景，白色文字
   - **保存前校验：** 昵称不能为空，否则提示"昵称不能为空"
   - 调用更新接口
   - 成功后Toast提示"更新成功"，返回上一页

---

### 4. 后端更新个人信息接口

#### 4.1 新增 DTO

**新建文件：** `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/UpdateUserDTO.java`

```java
@Data
public class UpdateUserDTO {
    @ApiModelProperty(value = "昵称")
    private String nickname;

    @ApiModelProperty(value = "邮箱")
    private String email;
}
```

#### 4.2 Controller 接口

**文件：** `backend/grid-app/src/main/java/com/naon/grid/modules/app/rest/AppAuthController.java`

新增接口：
- 路径：`POST /api/app/auth/user/update`
- 权限：需要登录
- 请求体：`UpdateUserDTO`
- 返回：`ResponseEntity<AppUserDTO>`

#### 4.3 Service 层

**文件：** `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/AppAuthService.java`

新增方法：
```java
AppUserDTO updateUser(Long userId, UpdateUserDTO updateUserDTO);
```

**文件：** `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/impl/AppAuthServiceImpl.java`

实现方法：
- 根据 userId 获取用户
- 更新 nickname（非空时）
- 更新 email（非空时）
- 保存到数据库
- 返回更新后的用户信息

---

### 5. 客户端服务层更新

#### 5.1 AuthService 更新

**文件：** `app/lib/core/services/auth_service.dart`

新增方法：
```dart
static Future<User> updateUser({String? nickname, String? email})
```

- 调用 `POST /api/app/auth/user/update` 接口
- 更新本地存储的用户信息

#### 5.2 AuthProvider 更新

**文件：** `app/lib/providers/auth_provider.dart`

新增方法：
```dart
Future<bool> updateUser({String? nickname, String? email})
```

- 调用 AuthService.updateUser
- 更新 currentUser
- notifyListeners

---

## 数据流程

### 保存个人信息流程

```
用户点击保存
    ↓
校验昵称不为空
    ↓ (失败)
显示"昵称不能为空"Toast → 结束
    ↓ (成功)
调用 updateUser 接口
    ↓ (失败)
显示错误Toast → 结束
    ↓ (成功)
更新本地用户信息
    ↓
显示"更新成功"Toast
    ↓
返回上一页
```

---

## 注意事项

1. 头像修改仅保存本地，暂不上传服务端
2. 邮箱无校验逻辑，用户可直接填写
3. 手机号不可修改
4. 退出登录移到设置页面底部
