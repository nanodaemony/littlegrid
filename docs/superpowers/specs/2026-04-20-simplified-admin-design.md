---
name: Simplified Admin Design
description: Design specification for simplified admin backend and frontend, removing complex RBAC system
type: spec
---

# 极简 Admin 后台设计文档

## 概述

从小 Grid 项目中移除复杂的 RBAC 权限系统（用户、角色、菜单、部门、岗位），实现极简的 Admin 后台。

## 架构变更

### 删除内容

**后端删除：**
- `grid-system` 模块（整个删除）
  - 用户管理、角色管理、菜单管理、部门管理、岗位管理
  - 定时任务（Quartz）
  - 原有的 Spring Security 配置

**前端删除：**
- `admin-web/` 目录（整个删除）

### 保留内容

**后端保留：**
- `grid-common` - 公共工具模块（不动）
- `grid-app` - App 模块（调整依赖）
- `grid-tools` - 工具模块（不动）

### 新增内容

**后端新增：**
- `grid-admin` 模块 - 新的 Admin 后端模块

**前端新增：**
- `admin/` 目录 - 新的 Admin 前端（React + Next.js）

## 迁移内容

从 `grid-system` 迁移到 `grid-common` 的内容：

1. **SecurityProperties** - JWT 参数配置类
2. **PasswordEncoder** - BCryptPasswordEncoder Bean 配置
3. **基础 Security 配置** - CORS、匿名访问配置

## grid-admin 模块设计

### 目录结构

```
grid-admin/
├── src/main/java/com/naon/grid/admin/
│   ├── config/
│   │   └── AdminSecurityConfig.java    # Admin 专用 Security 配置
│   ├── rest/
│   │   └── AdminAuthController.java     # 登录接口
│   └── security/
│       └── AdminTokenProvider.java      # JWT 工具
└── pom.xml
```

### 登录流程

1. 从 `.env` 配置文件读取：
   - `ADMIN_USERNAME` - Admin 用户名
   - `ADMIN_PASSWORD` - Admin 密码

2. 登录接口：
   - `POST /api/admin/login`
   - 接收用户名密码，简单比对
   - 成功返回 JWT token

3. 后续请求携带 token 鉴权

### 配置示例

`.env` 或 `application.yml` 中添加：

```
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
```

## 前端设计

### 技术栈

- **框架**: React 18 + Next.js 14 (App Router)
- **语言**: TypeScript
- **组件库**: shadcn/ui
- **样式**: Tailwind CSS
- **图标**: Lucide icons

### 目录结构

```
little-grid/admin/
├── app/
│   ├── layout.tsx          # 根布局（含 sidebar）
│   ├── page.tsx            # 登录页
│   └── dashboard/          # 管理页
├── components/
│   ├── ui/                 # shadcn/ui 组件
│   ├── Sidebar.tsx
│   └── Navbar.tsx
└── lib/
```

### 页面布局

```
┌─────────────────────────────────────────┐
│           Navbar (顶部)                  │
├──────────┬──────────────────────────────┤
│          │                              │
│ Sidebar  │       Content (中间)         │
│  (左侧)  │                              │
│          │                              │
└──────────┴──────────────────────────────┘
```

## 数据库

保留 `grid-app` 相关的表，删除 `grid-system` 相关的表：

**保留的表：**
- `app_grid_user` - App 用户表
- `treehole_*` - 树洞相关表

**删除的表：**
- `sys_user`
- `sys_role`
- `sys_menu`
- `sys_dept`
- `sys_job`
- `sys_roles_menus`
- `sys_users_roles`
- `sys_users_jobs`
- `qrtz_*` - Quartz 定时任务表

## 验证清单

- [ ] SecurityProperties 已迁移到 grid-common
- [ ] PasswordEncoder 配置已迁移
- [ ] grid-system 模块已删除
- [ ] grid-admin 模块已创建
- [ ] Admin 登录接口可正常工作
- [ ] admin-web 目录已删除
- [ ] 新 admin/ 前端项目已初始化
- [ ] 前端登录页可正常使用
- [ ] 后端编译通过
- [ ] App 模块功能不受影响
