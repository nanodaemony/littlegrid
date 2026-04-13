---
name: 项目规范沉淀结构设计
description: 为三个子项目（Flutter APP、Java 后端、Vue 前端）创建规范文档结构
type: spec
---

# 项目规范沉淀结构设计

## 概述

为 little-grid 项目的三个子项目创建统一的规范文档结构，方便开发者参考和 Claude AI 自动引用。

## 目标

- 沉淀项目现有代码模式和最佳实践
- 让新开发者快速上手
- 让 Claude AI 在每次会话中自动了解项目规范
- 保持代码风格一致性

## 整体架构

```
little-grid/
├── .rules/                           # 完整规范文档（人读）
│   ├── README.md                     # 总览 + 索引
│   ├── app/                          # Flutter 应用规范
│   │   ├── README.md                 # 主规范文件
│   │   └── patterns/                 # 代码模板
│   │       ├── new_tool.md           # 新工具模板
│   │       ├── new_service.md        # 服务层模板
│   │       └── new_model.md          # 模型模板
│   ├── backend/                      # Java 后端规范
│   │   ├── README.md                 # 主规范文件
│   │   └── patterns/
│   │       ├── new_module.md         # 新模块模板
│   │       ├── new_entity.md         # Entity 模板
│   │       └── new_controller.md     # Controller 模板
│   └── admin-web/                    # Vue 前端规范
│       ├── README.md                 # 主规范文件
│       └── patterns/
│           ├── new_api.md            # API 模块模板
│           ├── new_view.md           # 页面模板
│           └── new_component.md      # 组件模板
│
└── .claude/projects/-home-nano-little-grid/memory/
    ├── MEMORY.md                     # 索引文件
    └── quick-reference.md            # Claude 速查表（自动加载）
```

## .rules/ 规范内容结构

### 每个项目的 README.md 包含：

1. **技术栈版本** - SDK、核心依赖版本
2. **目录结构** - 标准目录组织
3. **命名规范** - 文件、类、变量命名
4. **代码规范** - 格式化、Lint 规则
5. **常用命令** - 构建、测试、运行
6. **检查清单** - 提交前必查

### patterns/ 目录

存放可直接复制的代码模板。

## quick-reference.md 速查表内容

给 Claude 看的一页纸速查，包含：
- 每个项目的一句话定位
- 关键文件位置
- 最常用的 3-5 个代码模式
- 常用命令

## 各项目核心规范（基于现有代码）

### Flutter (app)

- ToolModule 接口实现模式
- 工具注册方式（main.dart 中调用 ToolRegistry.register()）
- 数据库表升级流程（app_constants.dart 中 dbVersion）
- AppColors 颜色规范（不要硬编码颜色）
- 目录结构：`app/lib/tools/<tool_name>/<tool_name>_tool.dart`

### Java (backend)

- Entity 继承 BaseEntity 模式
- Repository/Service/Dto/Mapper 分层架构
- MapStruct 映射用法
- REST API 返回格式
- 模块结构：grid-common, grid-logging, grid-system, grid-tools, grid-generator, grid-app
- 使用 Lombok 简化代码

### Vue (admin-web)

- API 模块定义方式（src/api/ 目录）
- request.js 拦截器使用（自动加 Token、TraceId、日志）
- Vuex store 结构（src/store/modules/）
- Element UI 组件规范
- 目录结构：src/views/, src/api/, src/components/

## 实现计划

1. 创建 `.rules/` 目录结构
2. 为每个子项目编写主规范文件
3. 提取常用代码模板到 patterns/
4. 创建 Claude memory 的 quick-reference.md
5. 更新 MEMORY.md 索引

## 验收标准

- [ ] `.rules/` 目录结构完整
- [ ] 三个子项目都有规范文档
- [ ] quick-reference.md 能被 Claude 自动加载
- [ ] 规范内容与现有代码一致
