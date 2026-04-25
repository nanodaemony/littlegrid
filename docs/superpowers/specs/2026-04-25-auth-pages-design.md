# Auth Pages Design - 认证页面设计

## Overview

为"小方格"App 设计3种不同风格的登录、注册、忘记密码页面，放入设计TAB第3个按钮下，供选择使用。所有风格统一采用卡片淡色基调，参考现有"我的"页面和设置页面的视觉风格。

## Navigation Structure

### 设计TAB第3个按钮
- 按钮名称："按钮3" → "认证页面设计"
- 图标：radio_button_unchecked → lock_outline
- 点击后导航到 `AuthDesignPage`

### AuthDesignPage 页面结构
```
顶部：风格A | 风格B | 风格C    (SegmentedButton)
中部：登录 | 注册 | 忘记密码    (TabBar)
底部：对应页面预览
```

## Common Design Language

### 色彩（沿用现有 AppColors）
- 主色：#5B9BD5（蓝色）
- 主色浅：#BDD7EE（浅蓝）
- 背景：#F5F5F5（浅灰）
- 卡片：#FFFFFF（白色）
- 文字主：#333333
- 文字次：#666666
- 文字三：#999999

### 共同元素
- 所有页面顶部居中放置 App Logo（60x60圆形）+ "小方格" 文字标题
- 卡片统一白色、圆角12px、elevation=2
- 主按钮：主色蓝背景、白字、圆角8px、高度48px
- 链接文字：主色蓝、14px
- 页面背景：#F5F5F5

---

## Style A: Classic Centered Card（经典居中卡片）

### 特点
- 一个居中大白色卡片包含所有表单内容
- 输入框用淡蓝背景填充（#BDD7EE 30%透明度）
- 链接文字在卡片外
- 对称、稳重，与现有"我的"页面风格最接近

### Login Page
```
背景 #F5F5F5
  居中: [Logo 60x60] + "小方格"

  白色卡片 (margin=24px, radius=12px, elevation=2):
    手机号输入框 (淡蓝填充背景, 前缀📱图标)
    密码输入框 (淡蓝填充背景, 前缀🔒图标, 密码可见切换)
    "忘记密码？" (右对齐, 蓝色链接, 14px)
    登录按钮 (主色蓝, 全宽, 高48px, 圆角8px)

  卡片外居中: "还没有账号？去注册" (链接)
```

### Register Page
```
背景 #F5F5F5
  居中: [Logo 60x60] + "小方格"

  白色卡片:
    手机号输入框 (淡蓝填充背景, 前缀📱图标)
    密码输入框 (淡蓝填充背景, 前缀🔒图标)
    密码强度指示条 (密码框下方, 红/橙/绿三段进度条, 高3px)
    确认密码输入框 (淡蓝填充背景, 前缀🔒图标)
    昵称输入框 (淡蓝填充背景, 前缀👤图标, 标注"选填")
    注册按钮 (主色蓝, 全宽)

  卡片外居中: "已有账号？去登录"
```

### Forgot Password Page
```
背景 #F5F5F5
  居中: [Logo 60x60] + "小方格"

  白色卡片:
    步骤指示器 (顶部横向: ① → ② → ③, 蓝色已完成/灰色未完成)

    [Step 1] 手机号输入框 + "发送验证码"按钮 (同行排列)
    [Step 2] 6位验证码输入框 (可考虑分6个格子)
    [Step 3] 新密码输入框 + 强度条 + 确认密码输入框

    操作按钮:
      Step 1-2: "下一步" (主色蓝)
      Step 3: "完成" (主色蓝)
```

---

## Style B: Label + Divider Card（标签行+分割线卡片）

### 特点
- 一个居中大白色卡片
- 输入框用标签行+底部灰色分割线样式（上方灰色标签文字，下方输入区，再下方分割线）
- 更简约、留白更多
- 链接文字在卡片内部

### Login Page
```
背景 #F5F5F5
  居中: [Logo 60x60] + "小方格"

  白色卡片 (margin=24px, radius=12px, elevation=2):
    标签行 "手机号" (灰色12px文字)
    输入区 (无背景色, 无边框)
    灰色分割线 (#E0E0E0, 高1px)

    间距 16px

    标签行 "密码" (灰色12px文字)
    输入区 (含密码可见切换图标)
    灰色分割线

    间距 16px

    "忘记密码？" (右对齐, 蓝色链接)

    间距 24px

    登录按钮 (主色蓝, 全宽)

    间距 12px

    "还没有账号？去注册" (居中, 链接, 在卡片内)
```

### Register Page
```
同风格A字段，但每个字段使用标签行+分割线样式:
  手机号 → 标签"手机号" + 输入 + 分割线
  密码 → 标签"密码" + 输入 + 强度条 + 分割线
  确认密码 → 标签"确认密码" + 输入 + 分割线
  昵称 → 标签"昵称（选填）" + 输入 + 分割线
  注册按钮
  "已有账号？去登录" (卡片内)
```

### Forgot Password Page
```
同风格A步骤逻辑，但字段使用标签行+分割线样式:
  顶部步骤指示器
  Step 1: 标签"手机号" + 输入 + 分割线 + "发送验证码"按钮
  Step 2: 标签"验证码" + 6位输入 + 分割线
  Step 3: 标签"新密码" + 输入 + 强度条 + 分割线
          标签"确认密码" + 输入 + 分割线
  操作按钮 + 卡片内链接
```

---

## Style C: Segmented Cards（分段卡片组合）

### 特点
- 多个小卡片，功能分区
- 输入框用淡蓝填充背景（同风格A）
- 卡片各自独立圆角和阴影
- 卡片间距8px
- 链接文字在卡片外

### Login Page
```
背景 #F5F5F5
  居中: [Logo 60x60] + "小方格"

  卡片1 - 输入区 (margin=24px左右, radius=12px):
    手机号输入框 (淡蓝填充背景, 前缀📱图标)
    密码输入框 (淡蓝填充背景, 前缀🔒图标)

  卡片间距 8px

  卡片2 - 操作区 (同宽):
    登录按钮 (主色蓝, 全宽)

  卡片外居中:
    "忘记密码？"
    "还没有账号？去注册"
```

### Register Page
```
  卡片1 - 输入区:
    手机号 + 密码(含强度条) + 确认密码 + 昵称(选填)

  卡片2 - 操作区:
    注册按钮

  卡片外: "已有账号？去登录"
```

### Forgot Password Page
```
  卡片1 - 步骤指示器 (横向: ①→②→③)

  卡片2 - 内容区:
    [Step 1] 手机号 + 发送验证码
    [Step 2] 6位验证码
    [Step 3] 新密码 + 强度条 + 确认密码

  卡片3 - 操作区:
    Step 1-2: "下一步"
    Step 3: "完成"

  卡片外: "返回登录"
```

---

## File Structure

```
app/lib/pages/design/
  auth_design_page.dart          # 主容器：风格切换 + 页面类型切换
  auth_style_a_page.dart         # 风格A容器（含登录/注册/忘记密码子页面）
  auth_style_b_page.dart         # 风格B容器
  auth_style_c_page.dart         # 风格C容器
  auth_style_a/
    login_page_a.dart             # 风格A-登录
    register_page_a.dart          # 风格A-注册
    forgot_password_page_a.dart   # 风格A-忘记密码
  auth_style_b/
    login_page_b.dart
    register_page_b.dart
    forgot_password_page_b.dart
  auth_style_c/
    login_page_c.dart
    register_page_c.dart
    forgot_password_page_c.dart
```

## Design Tab Modification

在 `design_page.dart` 中：
- 第3个按钮：标题改为"认证页面设计"，图标改为 `lock_outline`
- 点击行为：导航到 `AuthDesignPage()`

## Implementation Notes

- 所有页面是**纯展示/预览**页面，不连接真实后端API
- 输入框可交互但不做真实验证（仅密码强度实时计算）
- 按钮点击后显示 SnackBar："此为设计预览，请选择您喜欢的风格"
- 步骤指示器的步骤切换可交互
- 沿用现有 `AppColors` 和 `AppTheme` 常量
