# 数据库管理功能设计

## 概述

在 Admin Web 的"工具 > 数据库管理"页面实现通用数据库管理工具，通过 JDBC 元数据自动发现数据库中所有表，提供表数据全功能 CRUD 和 SQL 查询执行器。

## 技术方案

JDBC 元数据 + 动态 SQL（PreparedStatement），不依赖 JPA 实体，覆盖所有表。

## 后端 API

所有接口位于 `grid-admin` 模块，路径前缀 `/api/admin/db`，需管理员认证。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/db/tables` | 获取所有表列表（表名、行数、注释） |
| GET | `/api/admin/db/tables/{tableName}/columns` | 获取指定表的列信息（列名、类型、可空、注释等） |
| GET | `/api/admin/db/tables/{tableName}/data?page=1&size=20&sort=col&order=asc` | 分页查询表数据，支持排序 |
| POST | `/api/admin/db/tables/{tableName}/data` | 新增一行数据，body 为 JSON 字段键值对 |
| PUT | `/api/admin/db/tables/{tableName}/data` | 更新行数据，body 含主键字段定位 + 更新字段 |
| DELETE | `/api/admin/db/tables/{tableName}/data` | 删除行，body 含主键字段定位 |
| POST | `/api/admin/db/sql` | 执行自定义 SQL，body 为 `{ "sql": "SELECT ..." }`，仅允许 SELECT |

### 核心实现

- **元数据获取**：注入 `DataSource`，通过 `Connection.getMetaData()` 获取表/列信息
- **动态 CRUD**：用 `PreparedStatement` 参数化查询，表名通过元数据校验确认表存在
- **主键定位**：通过 `DatabaseMetaData.getPrimaryKeys()` 获取主键列，用于 UPDATE/DELETE 的 WHERE 条件
- **SQL 执行器**：仅允许 SELECT 语句，结果以 `List<Map<String, Object>>` 返回，限制最大返回行数 1000

### 后端代码结构

```
grid-admin/src/main/java/com/naon/grid/admin/
├── rest/
│   └── DatabaseAdminController.java    # 7个接口入口
├── service/
│   ├── DatabaseMetadataService.java    # 元数据查询（表列表、列信息、主键）
│   └── DatabaseCrudService.java        # 动态CRUD + SQL执行
└── dto/
    ├── TableInfo.java                  # 表名、行数、注释
    ├── ColumnInfo.java                 # 列名、类型、可空、键类型、默认值、注释
    ├── SqlExecuteRequest.java          # SQL执行请求
    └── SqlExecuteResult.java           # SQL执行结果（columns + rows）
```

## 前端页面

位于 `/dashboard/tools/database`，分三个视图。

### 1. 表列表视图（默认页）

- 左侧：表列表侧栏，按表名字母排序，支持搜索过滤，点击切换选中表
- 右侧上方：选中表的基本信息（表名、行数、注释、引擎类型）
- 右侧下方：列信息表格（列名、类型、可空、键类型、默认值、注释）

### 2. 表数据视图（点击"数据"Tab 切换）

- 顶部工具栏：新增按钮、刷新按钮、每页行数选择
- 主体：数据表格，分页展示，支持点击列头排序
- 每行末尾：编辑、删除操作按钮
- 新增/编辑：弹出对话框，根据列元数据动态生成表单字段
- 删除：确认对话框，显示主键值

### 3. SQL 查询器（独立 Tab）

- 上方：SQL 编辑区（textarea，支持多行）
- 下方：结果表格，展示查询结果
- 执行按钮 + 最大返回行数提示

### 前端代码结构

```
admin/app/dashboard/tools/database/
├── page.tsx                            # 主页面，Tab切换（列信息/数据/SQL）
├── components/
│   ├── table-list.tsx                  # 左侧表列表
│   ├── column-info.tsx                 # 列信息表格
│   ├── data-table.tsx                  # 数据表格+分页+排序
│   ├── row-edit-dialog.tsx             # 新增/编辑对话框
│   └── sql-query.tsx                   # SQL查询器
└── hooks/
    └── use-database.ts                 # 数据请求hook
```

## 数据流

```
前端页面 → Next.js API Route (/api/admin/db/*) → Spring Boot (/api/admin/db/*) → MySQL
```

- 前端请求发往 Next.js API Route 做代理转发（与现有 Admin API 代理模式一致）
- Next.js 代理携带 JWT Token 转发到后端
- 后端通过注入的 `DataSource` 获取连接，执行操作

## 错误处理

| 场景 | 处理方式 |
|------|----------|
| 表不存在 | 400，返回 "表 xxx 不存在" |
| 主键缺失的表执行 UPDATE/DELETE | 400，返回 "该表无主键，不支持修改/删除" |
| 字段类型不匹配 | 400，返回具体的字段校验错误信息 |
| SQL 查询器执行非 SELECT | 403，返回 "仅允许 SELECT 查询" |
| SQL 执行报错 | 400，返回数据库原始错误信息（便于调试） |
| 查询结果超限 | 200，返回数据 + 警告提示 "结果已截断，最大 1000 行" |

## 安全措施

- 所有接口需管理员认证
- SQL 查询器仅允许 SELECT，后端做语句解析拦截
- 表名校验：CRUD 操作前确认表名存在于 `DatabaseMetaData` 中，防止表名注入
- 参数化查询：所有 WHERE 条件值通过 `PreparedStatement.setObject()` 绑定

## 关键实现要点

- `DatabaseMetadataService`：不缓存元数据，每次实时查询，保证表结构变更后即时反映
- `DatabaseCrudService`：INSERT/UPDATE/DELETE 统一通过 `PreparedStatement` 构建，字段值按列类型转换后绑定
- 前端 `row-edit-dialog`：根据 `ColumnInfo` 动态渲染表单，主键字段编辑时只读
- SQL 查询器结果：前端根据返回的 `columns` 数组动态构建表格列
- 设计风格：淡色扁平风格，与 Admin 整体一致，表格斑马纹，操作按钮图标+文字
