# 数据库浏览器设计文档

**日期：** 2026-04-14
**作者：** Claude
**状态：** 待审核

## 概述

在 admin-web 中新增一个独立的"数据库浏览器"模块，用于管理项目本身的 MySQL 数据库，支持查看表结构、浏览数据、增删改查等操作。

## 需求背景

- 需要方便地查看和管理用户数据
- 现有"运维-数据库管理"仅支持外部数据库连接管理和 SQL 脚本执行
- 需要可视化的数据管理界面，类似 phpMyAdmin/Navicat

## 功能需求

### 核心功能

1. **表列表展示**
   - 左侧树状展示所有数据库表
   - 支持刷新表列表

2. **表结构查看**
   - 点击表名可查看表结构详情
   - 展示列名、数据类型、是否可为空、键信息、默认值

3. **数据浏览**
   - 分页查询表数据（默认每页 10 条）
   - 支持切换每页显示条数
   - 默认进入数据视图

4. **数据增删改**
   - 新增数据：根据表字段动态生成表单
   - 编辑数据：在弹窗中编辑现有数据
   - 删除数据：单条删除，支持批量删除

5. **关键表二次确认**
   - 系统关键表（sys_user、sys_role 等）的增删改操作需要二次确认

6. **权限控制**
   - 可配置权限，与其他模块保持一致

### 非功能需求

- 安全性：使用 PreparedStatement 防止 SQL 注入
- 性能：分页查询，避免加载大量数据
- 可用性：遵循 eladmin 现有风格，操作直观

## 技术方案

### 架构设计

**模块位置：**
- 后端：`backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/`
- 前端：`admin-web/src/views/tools/databaseBrowser/`

### 后端设计

#### 新增文件结构

```
backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/
├── domain/
│   ├── TableInfo.java        # 表信息
│   ├── ColumnInfo.java       # 列信息
│   └── QueryCriteria.java    # 查询条件
├── service/
│   ├── DatabaseBrowserService.java
│   └── impl/
│       └── DatabaseBrowserServiceImpl.java
├── rest/
│   └── DatabaseBrowserController.java
└── util/
    └── JdbcUtils.java        # JDBC 工具类
```

#### API 设计

| 方法 | 路径 | 描述 | 权限 |
|------|------|------|------|
| GET | `/api/databaseBrowser/tables` | 获取所有表列表 | `databaseBrowser:list` |
| GET | `/api/databaseBrowser/tables/{tableName}/columns` | 获取表结构 | `databaseBrowser:list` |
| GET | `/api/databaseBrowser/tables/{tableName}/data` | 分页查询表数据 | `databaseBrowser:list` |
| POST | `/api/databaseBrowser/tables/{tableName}/data` | 新增数据 | `databaseBrowser:add` |
| PUT | `/api/databaseBrowser/tables/{tableName}/data` | 更新数据 | `databaseBrowser:edit` |
| DELETE | `/api/databaseBrowser/tables/{tableName}/data` | 删除数据 | `databaseBrowser:del` |
| POST | `/api/databaseBrowser/executeSql` | 执行 SQL（查询用） | `databaseBrowser:sql` |

#### 技术实现要点

- 使用 Spring 的 `DataSource` 注入获取数据库连接
- 通过 `DatabaseMetaData` 获取表和列信息
- 分页使用 MySQL 的 `LIMIT/OFFSET` 语法
- 所有增删改操作使用 `PreparedStatement` 防止 SQL 注入
- 复用项目现有的 `SqlUtils` 或扩展它

#### 关键表列表

需要二次确认的系统关键表：
```java
private static final Set<String> SENSITIVE_TABLES = Set.of(
    "sys_user", "sys_role", "sys_menu",
    "sys_dept", "sys_permission",
    "mnt_database"
);
```

### 前端设计

#### 新增文件结构

```
admin-web/src/views/tools/databaseBrowser/
├── index.vue               # 主页面
├── components/
│   ├── TableTree.vue       # 左侧表树
│   ├── DataView.vue        # 数据视图
│   ├── StructureView.vue   # 表结构视图
│   ├── DataForm.vue        # 新增/编辑表单
│   └── SqlConsole.vue      # SQL 控制台
└── api.js                   # API 调用
```

#### 页面布局

左右分栏布局：
- 左侧：表树导航（宽度 250px，可调整）
- 右侧：数据/结构视图（自适应宽度）

顶部操作栏：
- 表名展示
- 视图切换（数据/结构）
- 操作按钮（新增、刷新、执行 SQL）

#### 组件说明

**TableTree.vue**
- 使用 `el-tree` 组件
- 展示所有表名
- 点击表名切换右侧视图
- 支持刷新

**DataView.vue**
- 使用 eladmin 现有的 CRUD 混合模式
- 分页展示数据
- 操作列：编辑、删除
- 动态列根据表结构生成

**StructureView.vue**
- 表格展示列信息
- 包含：列名、数据类型、是否可为空、键、默认值

**DataForm.vue**
- 动态生成表单
- 根据列类型显示不同的表单控件
- 必填项校验

#### 权限设计

新增权限标识：
- `databaseBrowser:list` - 查看表和数据
- `databaseBrowser:add` - 新增数据
- `databaseBrowser:edit` - 编辑数据
- `databaseBrowser:del` - 删除数据
- `databaseBrowser:sql` - 执行 SQL

菜单配置：
- 菜单名称：数据库浏览器
- 菜单路径：`/tools/databaseBrowser`
- 图标：`database`
- 父级菜单：系统工具

## 安全考虑

1. **SQL 注入防护**
   - 所有查询使用 PreparedStatement
   - 表名和列名做白名单校验

2. **权限控制**
   - 接口级权限校验
   - 前端按钮级权限隐藏

3. **关键表保护**
   - 系统表操作需要二次确认
   - 可考虑增加操作日志

4. **数据脱敏**（可选）
   - 密码等敏感字段在前端展示时脱敏

## 实施计划

1. 后端基础框架搭建（Service、Controller、DTO）
2. 表信息获取和查询功能实现
3. 数据增删改功能实现
4. 权限配置
5. 前端页面布局和组件开发
6. 集成测试
7. 文档和使用说明

## 风险评估

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| 误删系统关键数据 | 高 | 中 | 二次确认、操作日志 |
| SQL 注入漏洞 | 高 | 低 | 使用 PreparedStatement |
| 大数据量查询性能问题 | 中 | 中 | 强制分页、限制每页最大条数 |
