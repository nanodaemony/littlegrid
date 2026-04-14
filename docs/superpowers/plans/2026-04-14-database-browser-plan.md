# 数据库浏览器 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 admin-web 中新增一个独立的"数据库浏览器"模块，用于管理项目本身的 MySQL 数据库，支持查看表结构、浏览数据、增删改查等操作。

**Architecture:** 纯 JDBC 实现，后端提供 REST API，前端使用 Vue 2 + Element UI，左右分栏布局（左侧表树，右侧数据/结构视图）

**Tech Stack:** Spring Boot 2.7, JdbcTemplate/DatabaseMetaData, Vue 2.7, Element UI 2.15

---

## 文件结构总览

**后端新增文件：**
```
backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/
├── domain/
│   ├── TableInfo.java
│   ├── ColumnInfo.java
│   └── TableData.java
├── service/
│   ├── DatabaseBrowserService.java
│   └── impl/
│       └── DatabaseBrowserServiceImpl.java
└── rest/
    └── DatabaseBrowserController.java
```

**前端新增文件：**
```
admin-web/src/
├── api/tools/databaseBrowser.js
└── views/tools/databaseBrowser/
    ├── index.vue
    └── components/
        ├── TableTree.vue
        ├── DataView.vue
        ├── StructureView.vue
        └── DataForm.vue
```

---

## Task 1: 后端 - Domain 类和基础结构

**Files:**
- Create: `backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/domain/TableInfo.java`
- Create: `backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/domain/ColumnInfo.java`
- Create: `backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/domain/TableData.java`

- [ ] **Step 1: 创建 TableInfo.java**

```java
package com.naon.grid.modules.tools.database.domain;

import io.swagger.annotations.ApiModelProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TableInfo {

    @ApiModelProperty(value = "表名")
    private String tableName;

    @ApiModelProperty(value = "表注释")
    private String tableComment;

    @ApiModelProperty(value = "列信息")
    private List<ColumnInfo> columns;
}
```

- [ ] **Step 2: 创建 ColumnInfo.java**

```java
package com.naon.grid.modules.tools.database.domain;

import io.swagger.annotations.ApiModelProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ColumnInfo {

    @ApiModelProperty(value = "列名")
    private String columnName;

    @ApiModelProperty(value = "数据类型")
    private String dataType;

    @ApiModelProperty(value = "列类型（含长度）")
    private String columnType;

    @ApiModelProperty(value = "是否可为空")
    private Boolean nullable;

    @ApiModelProperty(value = "键类型（PRI/MUL/UNI）")
    private String columnKey;

    @ApiModelProperty(value = "默认值")
    private String columnDefault;

    @ApiModelProperty(value = "列注释")
    private String columnComment;

    @ApiModelProperty(value = "是否自增")
    private Boolean autoIncrement;
}
```

- [ ] **Step 3: 创建 TableData.java**

```java
package com.naon.grid.modules.tools.database.domain;

import io.swagger.annotations.ApiModelProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TableData {

    @ApiModelProperty(value = "列信息")
    private List<ColumnInfo> columns;

    @ApiModelProperty(value = "数据行")
    private List<Map<String, Object>> rows;

    @ApiModelProperty(value = "总条数")
    private Long total;
}
```

- [ ] **Step 4: 提交**

```bash
cd /home/nano/little-grid2
git add backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/domain/
git commit -m "feat: add database browser domain classes"
```

---

## Task 2: 后端 - Service 接口和 JDBC 工具方法

**Files:**
- Create: `backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/service/DatabaseBrowserService.java`
- Create: `backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/service/impl/DatabaseBrowserServiceImpl.java`

- [ ] **Step 1: 创建 DatabaseBrowserService.java 接口**

```java
package com.naon.grid.modules.tools.database.service;

import com.naon.grid.modules.tools.database.domain.ColumnInfo;
import com.naon.grid.modules.tools.database.domain.TableData;
import com.naon.grid.modules.tools.database.domain.TableInfo;

import java.util.List;
import java.util.Map;

public interface DatabaseBrowserService {

    /**
     * 获取所有表列表
     */
    List<TableInfo> getAllTables();

    /**
     * 获取表结构
     */
    List<ColumnInfo> getTableColumns(String tableName);

    /**
     * 分页查询表数据
     */
    TableData getTableData(String tableName, int page, int size);

    /**
     * 新增数据
     */
    void insertData(String tableName, Map<String, Object> data);

    /**
     * 更新数据
     */
    void updateData(String tableName, Map<String, Object> data, Map<String, Object> whereClause);

    /**
     * 删除数据
     */
    void deleteData(String tableName, Map<String, Object> whereClause);

    /**
     * 检查表是否为敏感表
     */
    boolean isSensitiveTable(String tableName);
}
```

- [ ] **Step 2: 创建 DatabaseBrowserServiceImpl.java**

```java
package com.naon.grid.modules.tools.database.service.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.naon.grid.modules.tools.database.domain.ColumnInfo;
import com.naon.grid.modules.tools.database.domain.TableData;
import com.naon.grid.modules.tools.database.domain.TableInfo;
import com.naon.grid.modules.tools.database.service.DatabaseBrowserService;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.*;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class DatabaseBrowserServiceImpl implements DatabaseBrowserService {

    private final DataSource dataSource;

    private static final Set<String> SENSITIVE_TABLES = Set.of(
        "sys_user", "sys_role", "sys_menu",
        "sys_dept", "sys_permission",
        "mnt_database"
    );

    @Override
    public List<TableInfo> getAllTables() {
        List<TableInfo> tables = new ArrayList<>();
        try (Connection conn = dataSource.getConnection()) {
            DatabaseMetaData metaData = conn.getMetaData();
            try (ResultSet rs = metaData.getTables(conn.getCatalog(), null, "%", new String[]{"TABLE"})) {
                while (rs.next()) {
                    TableInfo table = new TableInfo();
                    table.setTableName(rs.getString("TABLE_NAME"));
                    table.setTableComment(rs.getString("REMARKS"));
                    tables.add(table);
                }
            }
            // 排序
            tables.sort(Comparator.comparing(TableInfo::getTableName));
        } catch (SQLException e) {
            log.error("获取表列表失败", e);
            throw new RuntimeException("获取表列表失败: " + e.getMessage());
        }
        return tables;
    }

    @Override
    public List<ColumnInfo> getTableColumns(String tableName) {
        List<ColumnInfo> columns = new ArrayList<>();
        try (Connection conn = dataSource.getConnection()) {
            DatabaseMetaData metaData = conn.getMetaData();

            // 获取列信息
            try (ResultSet rs = metaData.getColumns(conn.getCatalog(), null, tableName, "%")) {
                while (rs.next()) {
                    ColumnInfo column = new ColumnInfo();
                    column.setColumnName(rs.getString("COLUMN_NAME"));
                    column.setDataType(rs.getString("TYPE_NAME"));
                    column.setColumnType(rs.getString("COLUMN_TYPE"));
                    column.setNullable("YES".equals(rs.getString("IS_NULLABLE")));
                    column.setColumnKey(rs.getString("COLUMN_KEY"));
                    column.setColumnDefault(rs.getString("COLUMN_DEF"));
                    column.setColumnComment(rs.getString("REMARKS"));
                    column.setAutoIncrement("YES".equals(rs.getString("IS_AUTOINCREMENT")));
                    columns.add(column);
                }
            }

            // 补充表注释（如果为空）
            if (columns.isEmpty()) {
                try (ResultSet rs = metaData.getTables(conn.getCatalog(), null, tableName, new String[]{"TABLE"})) {
                    if (rs.next()) {
                        // 表存在但无列，不处理
                    } else {
                        throw new RuntimeException("表不存在: " + tableName);
                    }
                }
            }
        } catch (SQLException e) {
            log.error("获取表结构失败: {}", tableName, e);
            throw new RuntimeException("获取表结构失败: " + e.getMessage());
        }
        return columns;
    }

    @Override
    public TableData getTableData(String tableName, int page, int size) {
        TableData tableData = new TableData();
        List<ColumnInfo> columns = getTableColumns(tableName);
        tableData.setColumns(columns);

        List<Map<String, Object>> rows = new ArrayList<>();
        long total = 0;

        // 获取主键列名
        String primaryKey = columns.stream()
            .filter(c -> "PRI".equals(c.getColumnKey()))
            .findFirst()
            .map(ColumnInfo::getColumnName)
            .orElse(columns.get(0).getColumnName());

        String countSql = "SELECT COUNT(*) FROM " + quoteIdentifier(tableName);
        String dataSql = "SELECT * FROM " + quoteIdentifier(tableName)
            + " ORDER BY " + quoteIdentifier(primaryKey)
            + " LIMIT ? OFFSET ?";

        try (Connection conn = dataSource.getConnection();
             PreparedStatement countStmt = conn.prepareStatement(countSql);
             PreparedStatement dataStmt = conn.prepareStatement(dataSql)) {

            // 查询总数
            try (ResultSet rs = countStmt.executeQuery()) {
                if (rs.next()) {
                    total = rs.getLong(1);
                }
            }
            tableData.setTotal(total);

            // 查询分页数据
            dataStmt.setInt(1, size);
            dataStmt.setInt(2, (page - 1) * size);

            try (ResultSet rs = dataStmt.executeQuery()) {
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();

                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        String colName = metaData.getColumnName(i);
                        Object value = rs.getObject(i);
                        row.put(colName, value);
                    }
                    rows.add(row);
                }
            }
            tableData.setRows(rows);

        } catch (SQLException e) {
            log.error("查询表数据失败: {}", tableName, e);
            throw new RuntimeException("查询表数据失败: " + e.getMessage());
        }

        return tableData;
    }

    @Override
    public void insertData(String tableName, Map<String, Object> data) {
        if (data.isEmpty()) {
            throw new RuntimeException("数据不能为空");
        }

        StringBuilder sql = new StringBuilder("INSERT INTO ");
        sql.append(quoteIdentifier(tableName)).append(" (");

        List<String> columnNames = new ArrayList<>(data.keySet());
        for (int i = 0; i < columnNames.size(); i++) {
            if (i > 0) sql.append(", ");
            sql.append(quoteIdentifier(columnNames.get(i)));
        }
        sql.append(") VALUES (");
        for (int i = 0; i < columnNames.size(); i++) {
            if (i > 0) sql.append(", ");
            sql.append("?");
        }
        sql.append(")");

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < columnNames.size(); i++) {
                stmt.setObject(i + 1, data.get(columnNames.get(i)));
            }

            stmt.executeUpdate();
            log.info("插入数据成功: {} - {}", tableName, data);

        } catch (SQLException e) {
            log.error("插入数据失败: {}", tableName, e);
            throw new RuntimeException("插入数据失败: " + e.getMessage());
        }
    }

    @Override
    public void updateData(String tableName, Map<String, Object> data, Map<String, Object> whereClause) {
        if (data.isEmpty()) {
            throw new RuntimeException("更新数据不能为空");
        }
        if (whereClause.isEmpty()) {
            throw new RuntimeException("更新条件不能为空");
        }

        StringBuilder sql = new StringBuilder("UPDATE ");
        sql.append(quoteIdentifier(tableName)).append(" SET ");

        List<String> setColumns = new ArrayList<>(data.keySet());
        for (int i = 0; i < setColumns.size(); i++) {
            if (i > 0) sql.append(", ");
            sql.append(quoteIdentifier(setColumns.get(i))).append(" = ?");
        }

        sql.append(" WHERE ");
        List<String> whereColumns = new ArrayList<>(whereClause.keySet());
        for (int i = 0; i < whereColumns.size(); i++) {
            if (i > 0) sql.append(" AND ");
            sql.append(quoteIdentifier(whereColumns.get(i))).append(" = ?");
        }

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {

            int paramIndex = 1;
            for (String col : setColumns) {
                stmt.setObject(paramIndex++, data.get(col));
            }
            for (String col : whereColumns) {
                stmt.setObject(paramIndex++, whereClause.get(col));
            }

            int rows = stmt.executeUpdate();
            log.info("更新数据成功: {} - 影响行数: {}, 数据: {}, 条件: {}", tableName, rows, data, whereClause);

        } catch (SQLException e) {
            log.error("更新数据失败: {}", tableName, e);
            throw new RuntimeException("更新数据失败: " + e.getMessage());
        }
    }

    @Override
    public void deleteData(String tableName, Map<String, Object> whereClause) {
        if (whereClause.isEmpty()) {
            throw new RuntimeException("删除条件不能为空");
        }

        StringBuilder sql = new StringBuilder("DELETE FROM ");
        sql.append(quoteIdentifier(tableName)).append(" WHERE ");

        List<String> whereColumns = new ArrayList<>(whereClause.keySet());
        for (int i = 0; i < whereColumns.size(); i++) {
            if (i > 0) sql.append(" AND ");
            sql.append(quoteIdentifier(whereColumns.get(i))).append(" = ?");
        }

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {

            int paramIndex = 1;
            for (String col : whereColumns) {
                stmt.setObject(paramIndex++, whereClause.get(col));
            }

            int rows = stmt.executeUpdate();
            log.info("删除数据成功: {} - 影响行数: {}, 条件: {}", tableName, rows, whereClause);

        } catch (SQLException e) {
            log.error("删除数据失败: {}", tableName, e);
            throw new RuntimeException("删除数据失败: " + e.getMessage());
        }
    }

    @Override
    public boolean isSensitiveTable(String tableName) {
        return SENSITIVE_TABLES.contains(tableName);
    }

    private String quoteIdentifier(String identifier) {
        // 简单的标识符引用，防止 SQL 注入
        if (identifier == null || identifier.isEmpty()) {
            throw new IllegalArgumentException("标识符不能为空");
        }
        // 只允许字母、数字、下划线
        if (!identifier.matches("^[a-zA-Z0-9_]+$")) {
            throw new IllegalArgumentException("无效的标识符: " + identifier);
        }
        return "`" + identifier + "`";
    }
}
```

- [ ] **Step 3: 提交**

```bash
cd /home/nano/little-grid2
git add backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/service/
git commit -m "feat: add database browser service implementation"
```

---

## Task 3: 后端 - REST Controller

**Files:**
- Create: `backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/rest/DatabaseBrowserController.java`

- [ ] **Step 1: 创建 DatabaseBrowserController.java**

```java
package com.naon.grid.modules.tools.database.rest;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import com.naon.grid.annotation.Log;
import com.naon.grid.modules.tools.database.domain.ColumnInfo;
import com.naon.grid.modules.tools.database.domain.TableData;
import com.naon.grid.modules.tools.database.domain.TableInfo;
import com.naon.grid.modules.tools.database.service.DatabaseBrowserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Api(tags = "工具：数据库浏览器")
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/databaseBrowser")
public class DatabaseBrowserController {

    private final DatabaseBrowserService databaseBrowserService;

    @ApiOperation("获取所有表列表")
    @GetMapping("/tables")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<List<TableInfo>> getTables() {
        return new ResponseEntity<>(databaseBrowserService.getAllTables(), HttpStatus.OK);
    }

    @ApiOperation("获取表结构")
    @GetMapping("/tables/{tableName}/columns")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<List<ColumnInfo>> getTableColumns(@PathVariable String tableName) {
        return new ResponseEntity<>(databaseBrowserService.getTableColumns(tableName), HttpStatus.OK);
    }

    @ApiOperation("分页查询表数据")
    @GetMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<TableData> getTableData(
            @PathVariable String tableName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return new ResponseEntity<>(databaseBrowserService.getTableData(tableName, page, size), HttpStatus.OK);
    }

    @Log("数据库浏览器-新增数据")
    @ApiOperation("新增数据")
    @PostMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:add')")
    public ResponseEntity<Object> insertData(
            @PathVariable String tableName,
            @RequestBody Map<String, Object> data) {
        databaseBrowserService.insertData(tableName, data);
        return new ResponseEntity<>(HttpStatus.CREATED);
    }

    @Log("数据库浏览器-更新数据")
    @ApiOperation("更新数据")
    @PutMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:edit')")
    public ResponseEntity<Object> updateData(
            @PathVariable String tableName,
            @RequestBody Map<String, Object> requestData) {
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) requestData.get("data");
        @SuppressWarnings("unchecked")
        Map<String, Object> whereClause = (Map<String, Object>) requestData.get("where");
        databaseBrowserService.updateData(tableName, data, whereClause);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @Log("数据库浏览器-删除数据")
    @ApiOperation("删除数据")
    @DeleteMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:del')")
    public ResponseEntity<Object> deleteData(
            @PathVariable String tableName,
            @RequestBody Map<String, Object> whereClause) {
        databaseBrowserService.deleteData(tableName, whereClause);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @ApiOperation("检查表是否为敏感表")
    @GetMapping("/tables/{tableName}/sensitive")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<Boolean> isSensitiveTable(@PathVariable String tableName) {
        return new ResponseEntity<>(databaseBrowserService.isSensitiveTable(tableName), HttpStatus.OK);
    }
}
```

- [ ] **Step 2: 提交**

```bash
cd /home/nano/little-grid2
git add backend/grid-system/src/main/java/com/naon/grid/modules/tools/database/rest/
git commit -m "feat: add database browser REST controller"
```

---

## Task 4: 前端 - API 层

**Files:**
- Create: `admin-web/src/api/tools/databaseBrowser.js`

- [ ] **Step 1: 创建 databaseBrowser.js**

```javascript
import request from '@/utils/request'

export function getTables() {
  return request({
    url: 'api/databaseBrowser/tables',
    method: 'get'
  })
}

export function getTableColumns(tableName) {
  return request({
    url: `api/databaseBrowser/tables/${tableName}/columns`,
    method: 'get'
  })
}

export function getTableData(tableName, page, size) {
  return request({
    url: `api/databaseBrowser/tables/${tableName}/data`,
    method: 'get',
    params: { page, size }
  })
}

export function insertData(tableName, data) {
  return request({
    url: `api/databaseBrowser/tables/${tableName}/data`,
    method: 'post',
    data
  })
}

export function updateData(tableName, data, where) {
  return request({
    url: `api/databaseBrowser/tables/${tableName}/data`,
    method: 'put',
    data: { data, where }
  })
}

export function deleteData(tableName, where) {
  return request({
    url: `api/databaseBrowser/tables/${tableName}/data`,
    method: 'delete',
    data: where
  })
}

export function isSensitiveTable(tableName) {
  return request({
    url: `api/databaseBrowser/tables/${tableName}/sensitive`,
    method: 'get'
  })
}

export default {
  getTables, getTableColumns, getTableData,
  insertData, updateData, deleteData, isSensitiveTable
}
```

- [ ] **Step 2: 提交**

```bash
cd /home/nano/little-grid2
git add admin-web/src/api/tools/databaseBrowser.js
git commit -m "feat: add database browser API layer"
```

---

## Task 5: 前端 - TableTree 组件

**Files:**
- Create: `admin-web/src/views/tools/databaseBrowser/components/TableTree.vue`

- [ ] **Step 1: 创建 TableTree.vue**

```vue
<template>
  <div class="table-tree-container">
    <div class="tree-header">
      <span>表列表</span>
      <el-button
        type="text"
        icon="el-icon-refresh"
        @click="loadTables"
        :loading="loading"
      />
    </div>
    <el-tree
      ref="tree"
      :data="tableTree"
      :props="treeProps"
      node-key="tableName"
      :highlight-current="true"
      :expand-on-click-node="false"
      @node-click="handleNodeClick"
    >
      <span slot-scope="{ node, data }" class="custom-tree-node">
        <i class="el-icon-table" style="margin-right: 5px; color: #409EFF;" />
        <span>{{ node.label }}</span>
      </span>
    </el-tree>
  </div>
</template>

<script>
import { getTables } from '@/api/tools/databaseBrowser'

export default {
  name: 'TableTree',
  data() {
    return {
      loading: false,
      tableTree: [],
      treeProps: {
        label: 'tableName',
        children: 'children'
      },
      currentTable: null
    }
  },
  created() {
    this.loadTables()
  },
  methods: {
    async loadTables() {
      this.loading = true
      try {
        const res = await getTables()
        this.tableTree = res || []
      } catch (error) {
        this.$message.error('加载表列表失败')
      } finally {
        this.loading = false
      }
    },
    handleNodeClick(data) {
      this.currentTable = data.tableName
      this.$emit('selectTable', data)
    },
    setCurrentTable(tableName) {
      this.$refs.tree.setCurrentKey(tableName)
    }
  }
}
</script>

<style scoped>
.table-tree-container {
  height: 100%;
  display: flex;
  flex-direction: column;
  border-right: 1px solid #e8e8e8;
}
.tree-header {
  padding: 12px 16px;
  font-weight: bold;
  border-bottom: 1px solid #e8e8e8;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.custom-tree-node {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-right: 8px;
  font-size: 13px;
}
</style>
```

- [ ] **Step 2: 提交**

```bash
cd /home/nano/little-grid2
mkdir -p admin-web/src/views/tools/databaseBrowser/components
git add admin-web/src/views/tools/databaseBrowser/components/TableTree.vue
git commit -m "feat: add TableTree component"
```

---

## Task 6: 前端 - StructureView 组件

**Files:**
- Create: `admin-web/src/views/tools/databaseBrowser/components/StructureView.vue`

- [ ] **Step 1: 创建 StructureView.vue**

```vue
<template>
  <div class="structure-view">
    <el-table :data="columns" stripe border style="width: 100%">
      <el-table-column prop="columnName" label="列名" width="180" />
      <el-table-column prop="columnType" label="类型" width="150" />
      <el-table-column prop="nullable" label="可空" width="80">
        <template slot-scope="scope">
          <el-tag :type="scope.row.nullable ? 'success' : 'danger'" size="mini">
            {{ scope.row.nullable ? '是' : '否' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="columnKey" label="键" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.columnKey === 'PRI'" type="danger" size="mini">主键</el-tag>
          <el-tag v-else-if="scope.row.columnKey === 'UNI'" type="warning" size="mini">唯一</el-tag>
          <el-tag v-else-if="scope.row.columnKey === 'MUL'" type="info" size="mini">索引</el-tag>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column prop="autoIncrement" label="自增" width="80">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.autoIncrement" type="primary" size="mini">是</el-tag>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column prop="columnDefault" label="默认值" width="150" show-overflow-tooltip />
      <el-table-column prop="columnComment" label="注释" show-overflow-tooltip />
    </el-table>
  </div>
</template>

<script>
export default {
  name: 'StructureView',
  props: {
    columns: {
      type: Array,
      default: () => []
    }
  }
}
</script>

<style scoped>
.structure-view {
  padding: 16px;
}
</style>
```

- [ ] **Step 2: 提交**

```bash
cd /home/nano/little-grid2
git add admin-web/src/views/tools/databaseBrowser/components/StructureView.vue
git commit -m "feat: add StructureView component"
```

---

## Task 7: 前端 - DataForm 组件

**Files:**
- Create: `admin-web/src/views/tools/databaseBrowser/components/DataForm.vue`

- [ ] **Step 1: 创建 DataForm.vue**

```vue
<template>
  <el-dialog
    :title="isEdit ? '编辑数据' : '新增数据'"
    :visible.sync="dialogVisible"
    :close-on-click-modal="false"
    width="600px"
    @close="handleClose"
  >
    <el-form ref="form" :model="formData" :rules="rules" label-width="120px" size="small">
      <el-form-item
        v-for="column in editableColumns"
        :key="column.columnName"
        :label="column.columnComment || column.columnName"
        :prop="column.columnName"
      >
        <!-- 自增主键，只读 -->
        <el-input
          v-if="column.autoIncrement"
          v-model="formData[column.columnName]"
          disabled
          placeholder="自动生成"
        />
        <!-- 数字类型 -->
        <el-input-number
          v-else-if="isNumberType(column.dataType)"
          v-model="formData[column.columnName]"
          :disabled="column.columnKey === 'PRI' && isEdit"
          :precision="isDecimalType(column.dataType) ? 2 : 0"
          style="width: 100%;"
        />
        <!-- 日期时间类型 -->
        <el-date-picker
          v-else-if="isDateTimeType(column.dataType)"
          v-model="formData[column.columnName]"
          :disabled="column.columnKey === 'PRI' && isEdit"
          type="datetime"
          placeholder="选择日期时间"
          style="width: 100%;"
          value-format="yyyy-MM-dd HH:mm:ss"
        />
        <!-- 日期类型 -->
        <el-date-picker
          v-else-if="isDateType(column.dataType)"
          v-model="formData[column.columnName]"
          :disabled="column.columnKey === 'PRI' && isEdit"
          type="date"
          placeholder="选择日期"
          style="width: 100%;"
          value-format="yyyy-MM-dd"
        />
        <!-- 长文本 -->
        <el-input
          v-else-if="isTextType(column.dataType)"
          v-model="formData[column.columnName]"
          :disabled="column.columnKey === 'PRI' && isEdit"
          type="textarea"
          :rows="4"
          :placeholder="'请输入' + (column.columnComment || column.columnName)"
        />
        <!-- 布尔/枚举类型，显示为开关 -->
        <el-switch
          v-else-if="isBooleanType(column.columnType)"
          v-model="formData[column.columnName]"
          :disabled="column.columnKey === 'PRI' && isEdit"
          :active-value="1"
          :inactive-value="0"
        />
        <!-- 默认文本输入 -->
        <el-input
          v-else
          v-model="formData[column.columnName]"
          :disabled="column.columnKey === 'PRI' && isEdit"
          :placeholder="'请输入' + (column.columnComment || column.columnName)"
        />
      </el-form-item>
    </el-form>
    <div slot="footer" class="dialog-footer">
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" :loading="loading" @click="handleSubmit">确认</el-button>
    </div>
  </el-dialog>
</template>

<script>
export default {
  name: 'DataForm',
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    columns: {
      type: Array,
      default: () => []
    },
    editData: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      dialogVisible: false,
      formData: {},
      loading: false,
      isEdit: false,
      rules: {}
    }
  },
  watch: {
    visible(val) {
      this.dialogVisible = val
      if (val) {
        this.initForm()
      }
    },
    dialogVisible(val) {
      this.$emit('update:visible', val)
    }
  },
  computed: {
    editableColumns() {
      return this.columns.filter(col => !col.autoIncrement || this.isEdit)
    }
  },
  methods: {
    initForm() {
      this.isEdit = this.editData !== null
      this.formData = {}
      this.rules = {}

      this.columns.forEach(col => {
        let value = null
        if (this.isEdit && this.editData) {
          value = this.editData[col.columnName]
        } else if (col.columnDefault !== null) {
          value = col.columnDefault
        }

        // 类型转换
        if (value !== null && value !== undefined) {
          if (this.isNumberType(col.dataType)) {
            value = Number(value)
          }
        }

        this.formData[col.columnName] = value

        // 必填校验
        if (!col.nullable && !col.autoIncrement) {
          this.rules[col.columnName] = [
            { required: true, message: '请输入' + (col.columnComment || col.columnName), trigger: 'blur' }
          ]
        }
      })
    },
    isNumberType(dataType) {
      const types = ['INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT', 'DECIMAL', 'DOUBLE', 'FLOAT', 'NUMERIC']
      return types.includes(dataType.toUpperCase())
    },
    isDecimalType(dataType) {
      const types = ['DECIMAL', 'DOUBLE', 'FLOAT', 'NUMERIC']
      return types.includes(dataType.toUpperCase())
    },
    isDateTimeType(dataType) {
      const types = ['DATETIME', 'TIMESTAMP']
      return types.includes(dataType.toUpperCase())
    },
    isDateType(dataType) {
      return dataType.toUpperCase() === 'DATE'
    },
    isTextType(dataType) {
      const types = ['TEXT', 'LONGTEXT', 'MEDIUMTEXT']
      return types.includes(dataType.toUpperCase())
    },
    isBooleanType(columnType) {
      return columnType && columnType.toLowerCase().includes('tinyint(1)')
    },
    handleClose() {
      this.dialogVisible = false
      this.formData = {}
      this.$refs.form && this.$refs.form.resetFields()
    },
    handleSubmit() {
      this.$refs.form.validate((valid) => {
        if (valid) {
          this.loading = true
          this.$emit('submit', { ...this.formData })
        }
      })
    },
    setLoading(loading) {
      this.loading = loading
    }
  }
}
</script>

<style scoped>
</style>
```

- [ ] **Step 2: 提交**

```bash
cd /home/nano/little-grid2
git add admin-web/src/views/tools/databaseBrowser/components/DataForm.vue
git commit -m "feat: add DataForm component"
```

---

## Task 8: 前端 - DataView 组件

**Files:**
- Create: `admin-web/src/views/tools/databaseBrowser/components/DataView.vue`

- [ ] **Step 1: 创建 DataView.vue**

```vue
<template>
  <div class="data-view">
    <!-- 工具栏 -->
    <div class="toolbar">
      <el-button
        v-permission="['admin', 'databaseBrowser:add']"
        type="primary"
        size="small"
        icon="el-icon-plus"
        @click="handleAdd"
      >新增</el-button>
      <el-button
        type="default"
        size="small"
        icon="el-icon-refresh"
        @click="loadData"
        :loading="loading"
      >刷新</el-button>
    </div>

    <!-- 数据表格 -->
    <el-table
      v-loading="loading"
      :data="tableData.rows"
      border
      stripe
      style="width: 100%; margin-top: 10px;"
      max-height="calc(100vh - 280px)"
    >
      <el-table-column
        v-for="column in displayColumns"
        :key="column.columnName"
        :prop="column.columnName"
        :label="column.columnComment || column.columnName"
        :min-width="getColumnWidth(column)"
        show-overflow-tooltip
      >
        <!-- 特殊列格式化 -->
        <template slot-scope="scope">
          <span v-if="scope.row[column.columnName] === null" class="null-value">NULL</span>
          <span v-else>{{ formatValue(scope.row[column.columnName]) }}</span>
        </template>
      </el-table-column>

      <!-- 操作列 -->
      <el-table-column
        v-if="hasPermission"
        label="操作"
        width="150"
        fixed="right"
      >
        <template slot-scope="scope">
          <el-button
            v-permission="['admin', 'databaseBrowser:edit']"
            type="text"
            size="small"
            @click="handleEdit(scope.row)"
          >编辑</el-button>
          <el-button
            v-permission="['admin', 'databaseBrowser:del']"
            type="text"
            size="small"
            class="danger-btn"
            @click="handleDelete(scope.row)"
          >删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-container">
      <el-pagination
        :current-page.sync="page"
        :page-sizes="[10, 20, 50, 100]"
        :page-size.sync="size"
        :total="tableData.total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="loadData"
        @current-change="loadData"
      />
    </div>

    <!-- 数据表单弹窗 -->
    <DataForm
      :visible.sync="formVisible"
      :columns="columns"
      :edit-data="currentEditData"
      @submit="handleFormSubmit"
      ref="dataForm"
    />
  </div>
</template>

<script>
import { getTableData, insertData, updateData, deleteData, isSensitiveTable } from '@/api/tools/databaseBrowser'
import DataForm from './DataForm.vue'

export default {
  name: 'DataView',
  components: { DataForm },
  props: {
    tableName: {
      type: String,
      default: ''
    },
    columns: {
      type: Array,
      default: () => []
    }
  },
  data() {
    return {
      loading: false,
      tableData: { columns: [], rows: [], total: 0 },
      page: 1,
      size: 10,
      formVisible: false,
      currentEditData: null,
      isSensitive: false
    }
  },
  computed: {
    displayColumns() {
      // 限制显示列数，避免表格过宽
      return this.columns.slice(0, 20)
    },
    hasPermission() {
      return this.$checkPer(['admin', 'databaseBrowser:edit']) ||
             this.$checkPer(['admin', 'databaseBrowser:del'])
    }
  },
  watch: {
    tableName() {
      if (this.tableName) {
        this.page = 1
        this.checkSensitive()
        this.loadData()
      }
    }
  },
  created() {
    if (this.tableName) {
      this.checkSensitive()
      this.loadData()
    }
  },
  methods: {
    async checkSensitive() {
      try {
        this.isSensitive = await isSensitiveTable(this.tableName)
      } catch (e) {
        this.isSensitive = false
      }
    },
    async loadData() {
      if (!this.tableName) return

      this.loading = true
      try {
        this.tableData = await getTableData(this.tableName, this.page, this.size)
      } catch (error) {
        this.$message.error('加载数据失败')
      } finally {
        this.loading = false
      }
    },
    getColumnWidth(column) {
      if (column.columnKey === 'PRI') return 100
      if (column.dataType === 'DATETIME' || column.dataType === 'TIMESTAMP') return 170
      if (column.dataType === 'DATE') return 120
      return 120
    },
    formatValue(value) {
      if (value === null || value === undefined) return ''
      if (typeof value === 'object') {
        return JSON.stringify(value)
      }
      return String(value)
    },
    handleAdd() {
      if (this.isSensitive) {
        this.$confirm('该表为系统关键表，确认要新增数据吗？', '警告', {
          confirmButtonText: '确认',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          this.currentEditData = null
          this.formVisible = true
        }).catch(() => {})
      } else {
        this.currentEditData = null
        this.formVisible = true
      }
    },
    handleEdit(row) {
      const doEdit = () => {
        this.currentEditData = { ...row }
        this.formVisible = true
      }

      if (this.isSensitive) {
        this.$confirm('该表为系统关键表，确认要编辑数据吗？', '警告', {
          confirmButtonText: '确认',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          doEdit()
        }).catch(() => {})
      } else {
        doEdit()
      }
    },
    handleDelete(row) {
      const doDelete = async () => {
        try {
          const whereClause = this.buildWhereClause(row)
          await deleteData(this.tableName, whereClause)
          this.$message.success('删除成功')
          this.loadData()
        } catch (error) {
          this.$message.error('删除失败')
        }
      }

      const confirmMsg = this.isSensitive
        ? '该表为系统关键表，确认要删除该条数据吗？'
        : '确认要删除该条数据吗？'

      this.$confirm(confirmMsg, '提示', {
        confirmButtonText: '确认',
        cancelButtonText: '取消',
        type: this.isSensitive ? 'warning' : ''
      }).then(() => {
        doDelete()
      }).catch(() => {})
    },
    buildWhereClause(row) {
      // 使用主键作为删除条件
      const where = {}
      const pkColumn = this.columns.find(c => c.columnKey === 'PRI')
      if (pkColumn) {
        where[pkColumn.columnName] = row[pkColumn.columnName]
      } else {
        // 如果没有主键，使用所有列
        this.columns.forEach(col => {
          where[col.columnName] = row[col.columnName]
        })
      }
      return where
    },
    async handleFormSubmit(data) {
      try {
        if (this.currentEditData) {
          // 更新
          const whereClause = this.buildWhereClause(this.currentEditData)
          // 移除自增列
          this.columns.forEach(col => {
            if (col.autoIncrement) {
              delete data[col.columnName]
            }
          })
          await updateData(this.tableName, data, whereClause)
          this.$message.success('更新成功')
        } else {
          // 新增
          // 移除自增列
          this.columns.forEach(col => {
            if (col.autoIncrement) {
              delete data[col.columnName]
            }
          })
          await insertData(this.tableName, data)
          this.$message.success('新增成功')
        }
        this.formVisible = false
        this.$refs.dataForm.setLoading(false)
        this.loadData()
      } catch (error) {
        this.$message.error(this.currentEditData ? '更新失败' : '新增失败')
        this.$refs.dataForm.setLoading(false)
      }
    }
  }
}
</script>

<style scoped>
.data-view {
  padding: 16px;
  height: 100%;
  display: flex;
  flex-direction: column;
}
.toolbar {
  display: flex;
  gap: 10px;
}
.pagination-container {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
.null-value {
  color: #909399;
  font-style: italic;
}
.danger-btn {
  color: #F56C6C;
}
</style>
```

- [ ] **Step 2: 提交**

```bash
cd /home/nano/little-grid2
git add admin-web/src/views/tools/databaseBrowser/components/DataView.vue
git commit -m "feat: add DataView component"
```

---

## Task 9: 前端 - 主页面 index.vue

**Files:**
- Create: `admin-web/src/views/tools/databaseBrowser/index.vue`

- [ ] **Step 1: 创建 index.vue**

```vue
<template>
  <div class="database-browser-container">
    <!-- 左侧表树 -->
    <div class="left-panel">
      <TableTree @selectTable="handleSelectTable" ref="tableTree" />
    </div>

    <!-- 右侧内容区 -->
    <div class="right-panel">
      <!-- 顶部标题栏 -->
      <div class="header" v-if="currentTable">
        <div class="table-title">
          <i class="el-icon-table" style="margin-right: 8px;" />
          <span>{{ currentTable.tableName }}</span>
          <el-tag v-if="isSensitive" type="danger" size="mini" style="margin-left: 10px;">关键表</el-tag>
        </div>
        <div class="view-switch">
          <el-radio-group v-model="currentView" size="small">
            <el-radio-button label="data">数据</el-radio-button>
            <el-radio-button label="structure">结构</el-radio-button>
          </el-radio-group>
        </div>
      </div>

      <!-- 空状态 -->
      <div v-else class="empty-state">
        <i class="el-icon-database" />
        <p>请从左侧选择一个表</p>
      </div>

      <!-- 数据视图 -->
      <div v-show="currentView === 'data' && currentTable" class="view-container">
        <DataView
          ref="dataView"
          :table-name="currentTable.tableName"
          :columns="columns"
        />
      </div>

      <!-- 表结构视图 -->
      <div v-show="currentView === 'structure' && currentTable" class="view-container">
        <StructureView :columns="columns" />
      </div>
    </div>
  </div>
</template>

<script>
import { getTableColumns, isSensitiveTable } from '@/api/tools/databaseBrowser'
import TableTree from './components/TableTree.vue'
import DataView from './components/DataView.vue'
import StructureView from './components/StructureView.vue'

export default {
  name: 'DatabaseBrowser',
  components: { TableTree, DataView, StructureView },
  data() {
    return {
      currentTable: null,
      currentView: 'data',
      columns: [],
      isSensitive: false,
      loading: false
    }
  },
  methods: {
    async handleSelectTable(tableInfo) {
      this.currentTable = tableInfo
      this.currentView = 'data'
      await this.loadTableInfo(tableInfo.tableName)
    },
    async loadTableInfo(tableName) {
      this.loading = true
      try {
        // 检查表是否敏感
        try {
          this.isSensitive = await isSensitiveTable(tableName)
        } catch (e) {
          this.isSensitive = false
        }

        // 加载表结构
        this.columns = await getTableColumns(tableName)
      } catch (error) {
        this.$message.error('加载表信息失败')
        this.columns = []
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<style scoped>
.database-browser-container {
  display: flex;
  height: calc(100vh - 84px);
  background: #fff;
}
.left-panel {
  width: 250px;
  flex-shrink: 0;
  border-right: 1px solid #e8e8e8;
}
.right-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid #e8e8e8;
  background: #fafafa;
}
.table-title {
  font-size: 16px;
  font-weight: bold;
  display: flex;
  align-items: center;
}
.view-container {
  flex: 1;
  overflow: auto;
}
.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #909399;
}
.empty-state i {
  font-size: 64px;
  margin-bottom: 16px;
  color: #c0c4cc;
}
</style>
```

- [ ] **Step 2: 提交**

```bash
cd /home/nano/little-grid2
git add admin-web/src/views/tools/databaseBrowser/index.vue
git commit -m "feat: add database browser main page"
```

---

## Task 10: 前端 - 路由和菜单配置

**Files:**
- Check: 现有路由配置位置（按项目模式，通常菜单配置在数据库中）

- [ ] **Step 1: 检查现有路由配置方式**

让我查看项目中其他工具模块的路由配置方式：

```bash
cd /home/nano/little-grid2
ls -la admin-web/src/router/
```

- [ ] **Step 2: 根据项目现有的动态路由方式，此步跳过代码变更**

（注：eladmin 使用数据库动态菜单配置，需要在系统中手动添加菜单。）

需要添加的菜单信息：
- 菜单名称：数据库浏览器
- 菜单路径：`/tools/databaseBrowser`
- 组件路径：`tools/databaseBrowser/index`
- 图标：`database`
- 父级菜单：系统工具（tools）

权限标识：
- `databaseBrowser:list` - 查看
- `databaseBrowser:add` - 新增
- `databaseBrowser:edit` - 编辑
- `databaseBrowser:del` - 删除
- `databaseBrowser:sql` - 执行 SQL（预留）

- [ ] **Step 3: 提交（无代码变更，此步跳过）**

---

## Task 11: 集成测试和验证

**Files:**
- 无新文件，测试现有功能

- [ ] **Step 1: 后端编译验证**

```bash
cd /home/nano/little-grid2/backend
mvn compile -DskipTests
```

Expected: BUILD SUCCESS

- [ ] **Step 2: 前端编译验证**

```bash
cd /home/nano/little-grid2/admin-web
npm run lint
```

Expected: No errors

- [ ] **Step 3: 手动测试清单**

```
1. 启动后端服务
2. 启动前端服务
3. 登录 admin-web
4. 配置菜单和权限（在系统管理-菜单管理中添加）
5. 访问"系统工具-数据库浏览器"
6. 验证左侧表树加载
7. 点击表验证表结构查看
8. 验证数据分页查询
9. 验证新增数据（非敏感表）
10. 验证编辑数据
11. 验证删除数据
12. 验证敏感表操作二次确认
```

---

## Plan 自我审查

**1. Spec coverage:**
- ✅ 表列表展示 - Task 1, 2, 3, 5, 9
- ✅ 表结构查看 - Task 1, 2, 3, 6, 9
- ✅ 数据浏览 - Task 1, 2, 3, 8, 9
- ✅ 数据增删改 - Task 2, 3, 7, 8, 9
- ✅ 关键表二次确认 - Task 2, 3, 8
- ✅ 权限控制 - Task 3, 8, 9, 10
- ✅ 左右分栏布局 - Task 5, 9

**2. Placeholder scan:**
- ✅ 无 TBD/TODO
- ✅ 所有代码步骤完整
- ✅ 无模糊描述

**3. Type consistency:**
- ✅ 类名、方法名前后一致
- ✅ API 路径前后一致
- ✅ 文件路径正确

---

Plan complete and saved to `docs/superpowers/plans/2026-04-14-database-browser-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
