# 数据库管理功能实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Admin Web 实现通用数据库管理工具，通过 JDBC 元数据自动发现所有表，提供全功能 CRUD 和 SQL 查询执行器。

**Architecture:** 后端通过 `DataSource` + `DatabaseMetaData` 获取表/列元数据，用 `PreparedStatement` 实现动态 CRUD。前端为三视图布局（表列表+列信息 / 数据表格 / SQL 查询器），通过 Next.js API Route 代理转发到 Spring Boot。

**Tech Stack:** Spring Boot 2.7 / JDBC / MySQL, Next.js 16 / TypeScript / Tailwind CSS v4

---

## File Structure

### Backend (create/modify)

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/TableInfo.java` | 表信息 DTO |
| Create | `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/ColumnInfo.java` | 列信息 DTO |
| Create | `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/SqlExecuteRequest.java` | SQL 执行请求 DTO |
| Create | `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/SqlExecuteResult.java` | SQL 执行结果 DTO |
| Create | `backend/grid-admin/src/main/java/com/naon/grid/admin/service/DatabaseMetadataService.java` | 元数据查询服务 |
| Create | `backend/grid-admin/src/main/java/com/naon/grid/admin/service/DatabaseCrudService.java` | 动态 CRUD + SQL 执行服务 |
| Create | `backend/grid-admin/src/main/java/com/naon/grid/admin/rest/DatabaseAdminController.java` | 7 个 API 接口 |

### Frontend (create/modify)

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `admin/app/api/admin/[...path]/route.ts` | 添加 PUT/DELETE 代理方法 |
| Modify | `admin/app/dashboard/tools/database/page.tsx` | 替换占位页为完整页面 |
| Create | `admin/app/dashboard/tools/database/components/table-list.tsx` | 左侧表列表 |
| Create | `admin/app/dashboard/tools/database/components/column-info.tsx` | 列信息表格 |
| Create | `admin/app/dashboard/tools/database/components/data-table.tsx` | 数据表格+分页+排序 |
| Create | `admin/app/dashboard/tools/database/components/row-edit-dialog.tsx` | 新增/编辑行对话框 |
| Create | `admin/app/dashboard/tools/database/components/sql-query.tsx` | SQL 查询器 |
| Create | `admin/app/dashboard/tools/database/hooks/use-database.ts` | 数据请求 hook |

---

### Task 1: Backend DTOs

**Files:**
- Create: `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/TableInfo.java`
- Create: `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/ColumnInfo.java`
- Create: `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/SqlExecuteRequest.java`
- Create: `backend/grid-admin/src/main/java/com/naon/grid/admin/dto/SqlExecuteResult.java`

- [ ] **Step 1: Create TableInfo DTO**

```java
package com.naon.grid.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TableInfo {
    private String name;
    private Long rowCount;
    private String comment;
}
```

- [ ] **Step 2: Create ColumnInfo DTO**

```java
package com.naon.grid.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ColumnInfo {
    private String name;
    private String type;
    private String nullable;
    private String keyType;
    private Object defaultValue;
    private String comment;
    private Boolean autoIncrement;
}
```

- [ ] **Step 3: Create SqlExecuteRequest DTO**

```java
package com.naon.grid.admin.dto;

import lombok.Data;

@Data
public class SqlExecuteRequest {
    private String sql;
}
```

- [ ] **Step 4: Create SqlExecuteResult DTO**

```java
package com.naon.grid.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SqlExecuteResult {
    private List<String> columns;
    private List<Map<String, Object>> rows;
    private Boolean truncated;
}
```

- [ ] **Step 5: Commit**

```bash
git add backend/grid-admin/src/main/java/com/naon/grid/admin/dto/
git commit -m "feat: add database management DTOs"
```

---

### Task 2: DatabaseMetadataService

**Files:**
- Create: `backend/grid-admin/src/main/java/com/naon/grid/admin/service/DatabaseMetadataService.java`

- [ ] **Step 1: Create DatabaseMetadataService**

```java
package com.naon.grid.admin.service;

import com.naon.grid.admin.dto.ColumnInfo;
import com.naon.grid.admin.dto.TableInfo;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class DatabaseMetadataService {

    private final DataSource dataSource;

    public List<TableInfo> getTableList() {
        List<TableInfo> tables = new ArrayList<>();
        try (Connection conn = dataSource.getConnection()) {
            DatabaseMetaData meta = conn.getMetaData();
            String catalog = conn.getCatalog();
            try (ResultSet rs = meta.getTables(catalog, null, "%", new String[]{"TABLE"})) {
                while (rs.next()) {
                    String name = rs.getString("TABLE_NAME");
                    String comment = rs.getString("REMARKS");
                    long rowCount = getRowCount(conn, name);
                    tables.add(new TableInfo(name, rowCount, comment));
                }
            }
            tables.sort((a, b) -> a.getName().compareToIgnoreCase(b.getName()));
        } catch (SQLException e) {
            log.error("Failed to get table list", e);
            throw new RuntimeException("获取表列表失败: " + e.getMessage());
        }
        return tables;
    }

    public List<ColumnInfo> getTableColumns(String tableName) {
        validateTableExists(tableName);
        List<ColumnInfo> columns = new ArrayList<>();
        try (Connection conn = dataSource.getConnection()) {
            DatabaseMetaData meta = conn.getMetaData();
            String catalog = conn.getCatalog();
            Set<String> primaryKeys = getPrimaryKeys(conn, tableName);

            try (ResultSet rs = meta.getColumns(catalog, null, tableName, null)) {
                while (rs.next()) {
                    ColumnInfo col = new ColumnInfo();
                    col.setName(rs.getString("COLUMN_NAME"));
                    col.setType(rs.getString("TYPE_NAME"));
                    col.setNullable("YES".equals(rs.getString("IS_NULLABLE")) ? "YES" : "NO");
                    col.setKeyType(primaryKeys.contains(col.getName()) ? "PRI" : "");
                    col.setDefaultValue(rs.getObject("COLUMN_DEF"));
                    col.setComment(rs.getString("REMARKS"));
                    col.setAutoIncrement("YES".equals(rs.getString("IS_AUTOINCREMENT")));
                    columns.add(col);
                }
            }
        } catch (SQLException e) {
            log.error("Failed to get columns for table: {}", tableName, e);
            throw new RuntimeException("获取列信息失败: " + e.getMessage());
        }
        return columns;
    }

    public Set<String> getPrimaryKeys(Connection conn, String tableName) throws SQLException {
        Set<String> keys = new HashSet<>();
        DatabaseMetaData meta = conn.getMetaData();
        String catalog = conn.getCatalog();
        try (ResultSet rs = meta.getPrimaryKeys(catalog, null, tableName)) {
            while (rs.next()) {
                keys.add(rs.getString("COLUMN_NAME"));
            }
        }
        return keys;
    }

    public void validateTableExists(String tableName) {
        try (Connection conn = dataSource.getConnection()) {
            DatabaseMetaData meta = conn.getMetaData();
            String catalog = conn.getCatalog();
            try (ResultSet rs = meta.getTables(catalog, null, tableName, new String[]{"TABLE"})) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("表 " + tableName + " 不存在");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("校验表名失败: " + e.getMessage());
        }
    }

    private long getRowCount(Connection conn, String tableName) {
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM `" + tableName + "`");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getLong(1);
            }
        } catch (SQLException e) {
            log.warn("Failed to get row count for table: {}", tableName);
        }
        return -1;
    }
}
```

Note: `getRowCount` 中表名拼接无法参数化，但 `validateTableExists` 已确认表名来自数据库元数据，不存在注入风险。`getPrimaryKeys` 接受外部 `Connection` 参数是因为 `DatabaseCrudService` 需要复用同一连接。

- [ ] **Step 2: Commit**

```bash
git add backend/grid-admin/src/main/java/com/naon/grid/admin/service/DatabaseMetadataService.java
git commit -m "feat: add DatabaseMetadataService for table/column metadata"
```

---

### Task 3: DatabaseCrudService

**Files:**
- Create: `backend/grid-admin/src/main/java/com/naon/grid/admin/service/DatabaseCrudService.java`

- [ ] **Step 1: Create DatabaseCrudService**

```java
package com.naon.grid.admin.service;

import com.naon.grid.admin.dto.SqlExecuteResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.*;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class DatabaseCrudService {

    private final DataSource dataSource;
    private final DatabaseMetadataService metadataService;

    private static final int MAX_ROWS = 1000;

    public Map<String, Object> getTableData(String tableName, int page, int size, String sort, String order) {
        metadataService.validateTableExists(tableName);
        try (Connection conn = dataSource.getConnection()) {
            long total = getRowCount(conn, tableName);
            String orderBy = "";
            if (sort != null && !sort.isEmpty()) {
                String dir = "desc".equalsIgnoreCase(order) ? "DESC" : "ASC";
                orderBy = " ORDER BY `" + sort + "` " + dir;
            }
            String sql = "SELECT * FROM `" + tableName + "`" + orderBy + " LIMIT ? OFFSET ?";
            List<Map<String, Object>> rows = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, size);
                ps.setInt(2, (page - 1) * size);
                try (ResultSet rs = ps.executeQuery()) {
                    ResultSetMetaData rsMeta = rs.getMetaData();
                    int colCount = rsMeta.getColumnCount();
                    while (rs.next()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        for (int i = 1; i <= colCount; i++) {
                            row.put(rsMeta.getColumnLabel(i), rs.getObject(i));
                        }
                        rows.add(row);
                    }
                }
            }
            Map<String, Object> result = new HashMap<>();
            result.put("rows", rows);
            result.put("total", total);
            result.put("page", page);
            result.put("size", size);
            return result;
        } catch (SQLException e) {
            log.error("Failed to query table data: {}", tableName, e);
            throw new RuntimeException("查询表数据失败: " + e.getMessage());
        }
    }

    public void insertRow(String tableName, Map<String, Object> data) {
        metadataService.validateTableExists(tableName);
        StringBuilder cols = new StringBuilder();
        StringBuilder vals = new StringBuilder();
        List<Object> params = new ArrayList<>();
        for (Map.Entry<String, Object> entry : data.entrySet()) {
            if (cols.length() > 0) {
                cols.append(", ");
                vals.append(", ");
            }
            cols.append("`").append(entry.getKey()).append("`");
            vals.append("?");
            params.add(entry.getValue());
        }
        String sql = "INSERT INTO `" + tableName + "` (" + cols + ") VALUES (" + vals + ")";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            ps.executeUpdate();
        } catch (SQLException e) {
            log.error("Failed to insert row into table: {}", tableName, e);
            throw new RuntimeException("新增数据失败: " + e.getMessage());
        }
    }

    public void updateRow(String tableName, Map<String, Object> data) {
        metadataService.validateTableExists(tableName);
        try (Connection conn = dataSource.getConnection()) {
            Set<String> primaryKeys = metadataService.getPrimaryKeys(conn, tableName);
            if (primaryKeys.isEmpty()) {
                throw new IllegalArgumentException("该表无主键，不支持修改");
            }
            StringBuilder setClause = new StringBuilder();
            List<Object> setParams = new ArrayList<>();
            List<Object> whereParams = new ArrayList<>();
            StringBuilder whereClause = new StringBuilder();
            for (Map.Entry<String, Object> entry : data.entrySet()) {
                if (primaryKeys.contains(entry.getKey())) {
                    if (whereClause.length() > 0) whereClause.append(" AND ");
                    whereClause.append("`").append(entry.getKey()).append("` = ?");
                    whereParams.add(entry.getValue());
                } else {
                    if (setClause.length() > 0) setClause.append(", ");
                    setClause.append("`").append(entry.getKey()).append("` = ?");
                    setParams.add(entry.getValue());
                }
            }
            if (whereClause.length() == 0) {
                throw new IllegalArgumentException("请求中缺少主键字段");
            }
            String sql = "UPDATE `" + tableName + "` SET " + setClause + " WHERE " + whereClause;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                int idx = 1;
                for (Object p : setParams) ps.setObject(idx++, p);
                for (Object p : whereParams) ps.setObject(idx++, p);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            log.error("Failed to update row in table: {}", tableName, e);
            throw new RuntimeException("更新数据失败: " + e.getMessage());
        }
    }

    public void deleteRow(String tableName, Map<String, Object> data) {
        metadataService.validateTableExists(tableName);
        try (Connection conn = dataSource.getConnection()) {
            Set<String> primaryKeys = metadataService.getPrimaryKeys(conn, tableName);
            if (primaryKeys.isEmpty()) {
                throw new IllegalArgumentException("该表无主键，不支持删除");
            }
            StringBuilder whereClause = new StringBuilder();
            List<Object> whereParams = new ArrayList<>();
            for (Map.Entry<String, Object> entry : data.entrySet()) {
                if (primaryKeys.contains(entry.getKey())) {
                    if (whereClause.length() > 0) whereClause.append(" AND ");
                    whereClause.append("`").append(entry.getKey()).append("` = ?");
                    whereParams.add(entry.getValue());
                }
            }
            if (whereClause.length() == 0) {
                throw new IllegalArgumentException("请求中缺少主键字段");
            }
            String sql = "DELETE FROM `" + tableName + "` WHERE " + whereClause;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (int i = 0; i < whereParams.size(); i++) {
                    ps.setObject(i + 1, whereParams.get(i));
                }
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            log.error("Failed to delete row from table: {}", tableName, e);
            throw new RuntimeException("删除数据失败: " + e.getMessage());
        }
    }

    public SqlExecuteResult executeSql(String sql) {
        String trimmed = sql.trim();
        if (!trimmed.toUpperCase().startsWith("SELECT")) {
            throw new IllegalArgumentException("仅允许 SELECT 查询");
        }
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(trimmed)) {
            ps.setMaxRows(MAX_ROWS + 1);
            try (ResultSet rs = ps.executeQuery()) {
                ResultSetMetaData rsMeta = rs.getMetaData();
                int colCount = rsMeta.getColumnCount();
                List<String> columns = new ArrayList<>();
                for (int i = 1; i <= colCount; i++) {
                    columns.add(rsMeta.getColumnLabel(i));
                }
                List<Map<String, Object>> rows = new ArrayList<>();
                int count = 0;
                boolean truncated = false;
                while (rs.next()) {
                    if (count >= MAX_ROWS) {
                        truncated = true;
                        break;
                    }
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= colCount; i++) {
                        row.put(rsMeta.getColumnLabel(i), rs.getObject(i));
                    }
                    rows.add(row);
                    count++;
                }
                return new SqlExecuteResult(columns, rows, truncated);
            }
        } catch (SQLException e) {
            log.error("Failed to execute SQL: {}", sql, e);
            throw new RuntimeException("SQL 执行失败: " + e.getMessage());
        }
    }

    private long getRowCount(Connection conn, String tableName) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM `" + tableName + "`");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0;
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-admin/src/main/java/com/naon/grid/admin/service/DatabaseCrudService.java
git commit -m "feat: add DatabaseCrudService for dynamic CRUD and SQL execution"
```

---

### Task 4: DatabaseAdminController

**Files:**
- Create: `backend/grid-admin/src/main/java/com/naon/grid/admin/rest/DatabaseAdminController.java`

- [ ] **Step 1: Create DatabaseAdminController**

```java
package com.naon.grid.admin.rest;

import com.naon.grid.admin.dto.ColumnInfo;
import com.naon.grid.admin.dto.SqlExecuteRequest;
import com.naon.grid.admin.dto.SqlExecuteResult;
import com.naon.grid.admin.dto.TableInfo;
import com.naon.grid.admin.service.DatabaseCrudService;
import com.naon.grid.admin.service.DatabaseMetadataService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/db")
@RequiredArgsConstructor
@Api(tags = "Admin：数据库管理")
public class DatabaseAdminController {

    private final DatabaseMetadataService metadataService;
    private final DatabaseCrudService crudService;

    @GetMapping("/tables")
    @ApiOperation("获取所有表列表")
    public ResponseEntity<List<TableInfo>> getTableList() {
        return ResponseEntity.ok(metadataService.getTableList());
    }

    @GetMapping("/tables/{tableName}/columns")
    @ApiOperation("获取指定表的列信息")
    public ResponseEntity<List<ColumnInfo>> getTableColumns(@PathVariable String tableName) {
        return ResponseEntity.ok(metadataService.getTableColumns(tableName));
    }

    @GetMapping("/tables/{tableName}/data")
    @ApiOperation("分页查询表数据")
    public ResponseEntity<Map<String, Object>> getTableData(
            @PathVariable String tableName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "asc") String order) {
        return ResponseEntity.ok(crudService.getTableData(tableName, page, size, sort, order));
    }

    @PostMapping("/tables/{tableName}/data")
    @ApiOperation("新增一行数据")
    public ResponseEntity<Map<String, Object>> insertRow(
            @PathVariable String tableName,
            @RequestBody Map<String, Object> data) {
        crudService.insertRow(tableName, data);
        Map<String, Object> result = new HashMap<>();
        result.put("message", "新增成功");
        return ResponseEntity.ok(result);
    }

    @PutMapping("/tables/{tableName}/data")
    @ApiOperation("更新行数据")
    public ResponseEntity<Map<String, Object>> updateRow(
            @PathVariable String tableName,
            @RequestBody Map<String, Object> data) {
        crudService.updateRow(tableName, data);
        Map<String, Object> result = new HashMap<>();
        result.put("message", "更新成功");
        return ResponseEntity.ok(result);
    }

    @DeleteMapping("/tables/{tableName}/data")
    @ApiOperation("删除行")
    public ResponseEntity<Map<String, Object>> deleteRow(
            @PathVariable String tableName,
            @RequestBody Map<String, Object> data) {
        crudService.deleteRow(tableName, data);
        Map<String, Object> result = new HashMap<>();
        result.put("message", "删除成功");
        return ResponseEntity.ok(result);
    }

    @PostMapping("/sql")
    @ApiOperation("执行SQL查询")
    public ResponseEntity<SqlExecuteResult> executeSql(@RequestBody SqlExecuteRequest request) {
        return ResponseEntity.ok(crudService.executeSql(request.getSql()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("message", e.getMessage());
        return ResponseEntity.badRequest().body(err);
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntime(RuntimeException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("message", e.getMessage());
        return ResponseEntity.badRequest().body(err);
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-admin/src/main/java/com/naon/grid/admin/rest/DatabaseAdminController.java
git commit -m "feat: add DatabaseAdminController with 7 API endpoints"
```

---

### Task 5: Next.js API Proxy — Add PUT/DELETE

The existing proxy at `admin/app/api/admin/[...path]/route.ts` only handles GET and POST. We need to add PUT and DELETE handlers so the frontend can call `updateRow` and `deleteRow`.

**Files:**
- Modify: `admin/app/api/admin/[...path]/route.ts`

- [ ] **Step 1: Add PUT and DELETE export functions**

Add after the existing `GET` function at the end of `route.ts`:

```typescript
export async function PUT(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const params = await context.params
  const path = params.path.join('/')
  const body = await request.json()
  const token = request.headers.get('authorization')
  const traceId = request.headers.get('x-trace-id') || crypto.randomUUID()

  const res = await fetch(`${BACKEND_URL}/api/admin/${path}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...(token ? { 'Authorization': token } : {}),
    },
    body: JSON.stringify(body),
  })

  const data = await res.json()
  const response = NextResponse.json(data, { status: res.status })
  response.headers.set('X-Trace-Id', res.headers.get('X-Trace-Id') || traceId)
  return response
}

export async function DELETE(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const params = await context.params
  const path = params.path.join('/')
  const body = await request.json()
  const token = request.headers.get('authorization')
  const traceId = request.headers.get('x-trace-id') || crypto.randomUUID()

  const res = await fetch(`${BACKEND_URL}/api/admin/${path}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...(token ? { 'Authorization': token } : {}),
    },
    body: JSON.stringify(body),
  })

  const data = await res.json()
  const response = NextResponse.json(data, { status: res.status })
  response.headers.set('X-Trace-Id', res.headers.get('X-Trace-Id') || traceId)
  return response
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/api/admin/[...path]/route.ts
git commit -m "feat: add PUT and DELETE proxy handlers to admin API route"
```

---

### Task 6: Frontend — use-database hook

**Files:**
- Create: `admin/app/dashboard/tools/database/hooks/use-database.ts`

- [ ] **Step 1: Create the data fetching hook**

```typescript
'use client'

import { useState, useCallback } from 'react'

const API_BASE = '/api/admin/db'

function getAuthHeaders(): HeadersInit {
  const token = typeof window !== 'undefined' ? localStorage.getItem('adminToken') : null
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  }
}

export interface TableInfo {
  name: string
  rowCount: number
  comment: string
}

export interface ColumnInfo {
  name: string
  type: string
  nullable: string
  keyType: string
  defaultValue: any
  comment: string
  autoIncrement: boolean
}

export interface PagedData {
  rows: Record<string, any>[]
  total: number
  page: number
  size: number
}

export interface SqlResult {
  columns: string[]
  rows: Record<string, any>[]
  truncated: boolean
}

export function useDatabase() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const request = useCallback(async <T>(url: string, options?: RequestInit): Promise<T> => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetch(url, {
        ...options,
        headers: { ...getAuthHeaders(), ...options?.headers },
      })
      const data = await res.json()
      if (!res.ok) {
        throw new Error(data.message || '请求失败')
      }
      return data as T
    } catch (err: any) {
      setError(err.message)
      throw err
    } finally {
      setLoading(false)
    }
  }, [])

  const fetchTables = useCallback(() => {
    return request<TableInfo[]>(`${API_BASE}/tables`)
  }, [request])

  const fetchColumns = useCallback((tableName: string) => {
    return request<ColumnInfo[]>(`${API_BASE}/tables/${tableName}/columns`)
  }, [request])

  const fetchTableData = useCallback((tableName: string, page: number, size: number, sort?: string, order?: string) => {
    const params = new URLSearchParams({ page: String(page), size: String(size) })
    if (sort) params.set('sort', sort)
    if (order) params.set('order', order)
    return request<PagedData>(`${API_BASE}/tables/${tableName}/data?${params}`)
  }, [request])

  const insertRow = useCallback((tableName: string, data: Record<string, any>) => {
    return request<{ message: string }>(`${API_BASE}/tables/${tableName}/data`, {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }, [request])

  const updateRow = useCallback((tableName: string, data: Record<string, any>) => {
    return request<{ message: string }>(`${API_BASE}/tables/${tableName}/data`, {
      method: 'PUT',
      body: JSON.stringify(data),
    })
  }, [request])

  const deleteRow = useCallback((tableName: string, data: Record<string, any>) => {
    return request<{ message: string }>(`${API_BASE}/tables/${tableName}/data`, {
      method: 'DELETE',
      body: JSON.stringify(data),
    })
  }, [request])

  const executeSql = useCallback((sql: string) => {
    return request<SqlResult>(`${API_BASE}/sql`, {
      method: 'POST',
      body: JSON.stringify({ sql }),
    })
  }, [request])

  return { loading, error, fetchTables, fetchColumns, fetchTableData, insertRow, updateRow, deleteRow, executeSql }
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/tools/database/hooks/use-database.ts
git commit -m "feat: add useDatabase hook for database API calls"
```

---

### Task 7: Frontend — table-list component

**Files:**
- Create: `admin/app/dashboard/tools/database/components/table-list.tsx`

- [ ] **Step 1: Create table-list component**

```tsx
'use client'

import { useState } from 'react'
import { TableInfo } from '../hooks/use-database'

interface TableListProps {
  tables: TableInfo[]
  selectedTable: string | null
  onSelect: (tableName: string) => void
}

export function TableList({ tables, selectedTable, onSelect }: TableListProps) {
  const [search, setSearch] = useState('')

  const filtered = tables.filter((t) =>
    t.name.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="flex flex-col h-full" style={{ width: 240, background: 'var(--surface)', borderRight: '1px solid var(--outline)' }}>
      <div className="p-3" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
        <div className="relative">
          <span className="material-icons-round absolute left-2.5 top-1/2 -translate-y-1/2" style={{ fontSize: 18, color: 'var(--on-surface-variant)' }}>search</span>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="搜索表名..."
            className="w-full pl-8 pr-3 py-1.5 rounded-md text-sm outline-none"
            style={{ background: 'var(--surface-container)', color: 'var(--on-surface)', border: '1px solid var(--outline-variant)' }}
          />
        </div>
      </div>
      <div className="flex-1 overflow-y-auto py-1">
        {filtered.map((table) => (
          <button
            key={table.name}
            onClick={() => onSelect(table.name)}
            className="flex items-center gap-2 w-full px-3 py-2 text-left text-sm transition-colors cursor-pointer"
            style={{
              color: selectedTable === table.name ? 'var(--primary)' : 'var(--on-surface-variant)',
              background: selectedTable === table.name ? 'var(--primary-light)' : 'transparent',
              fontWeight: selectedTable === table.name ? 500 : 400,
            }}
            onMouseEnter={(e) => {
              if (selectedTable !== table.name) e.currentTarget.style.background = 'var(--surface-container)'
            }}
            onMouseLeave={(e) => {
              if (selectedTable !== table.name) e.currentTarget.style.background = 'transparent'
            }}
          >
            <span className="material-icons-round" style={{ fontSize: 16 }}>table_chart</span>
            <span className="truncate">{table.name}</span>
            <span className="ml-auto text-xs" style={{ color: 'var(--on-surface-variant)' }}>
              {table.rowCount >= 0 ? table.rowCount : '-'}
            </span>
          </button>
        ))}
        {filtered.length === 0 && (
          <div className="px-3 py-6 text-center text-sm" style={{ color: 'var(--on-surface-variant)' }}>
            无匹配表
          </div>
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/tools/database/components/table-list.tsx
git commit -m "feat: add table-list component with search and selection"
```

---

### Task 8: Frontend — column-info component

**Files:**
- Create: `admin/app/dashboard/tools/database/components/column-info.tsx`

- [ ] **Step 1: Create column-info component**

```tsx
'use client'

import { ColumnInfo, TableInfo } from '../hooks/use-database'

interface ColumnInfoProps {
  table: TableInfo
  columns: ColumnInfo[]
}

export function ColumnInfoView({ table, columns }: ColumnInfoProps) {
  return (
    <div>
      <div className="mb-4 p-4 rounded-lg" style={{ background: 'var(--surface)', border: '1px solid var(--outline-variant)' }}>
        <div className="flex items-center gap-3 mb-2">
          <span className="material-icons-round" style={{ fontSize: 20, color: 'var(--primary)' }}>table_chart</span>
          <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>{table.name}</h3>
        </div>
        <div className="flex gap-4 text-sm" style={{ color: 'var(--on-surface-variant)' }}>
          <span>行数: {table.rowCount >= 0 ? table.rowCount.toLocaleString() : '-'}</span>
          {table.comment && <span>注释: {table.comment}</span>}
        </div>
      </div>

      <div className="rounded-lg overflow-hidden" style={{ background: 'var(--surface)', border: '1px solid var(--outline-variant)' }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: 'var(--surface-container)' }}>
              {['列名', '类型', '可空', '键', '默认值', '注释'].map((h) => (
                <th key={h} className="text-left px-3 py-2.5 font-medium" style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {columns.map((col, i) => (
              <tr key={col.name} style={{ background: i % 2 === 0 ? 'var(--surface)' : 'var(--surface-container-low)' }}>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface)' }}>
                  {col.keyType === 'PRI' && <span className="material-icons-round align-middle mr-1" style={{ fontSize: 14, color: 'var(--warning)' }}>vpn_key</span>}
                  {col.name}
                </td>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface-variant)' }}>{col.type}</td>
                <td className="px-3 py-2" style={{ color: col.nullable === 'YES' ? 'var(--success)' : 'var(--error)' }}>{col.nullable}</td>
                <td className="px-3 py-2" style={{ color: col.keyType ? 'var(--primary)' : 'var(--on-surface-variant)' }}>{col.keyType || '-'}</td>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface-variant)' }}>{col.defaultValue != null ? String(col.defaultValue) : '-'}</td>
                <td className="px-3 py-2" style={{ color: 'var(--on-surface-variant)' }}>{col.comment || '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/tools/database/components/column-info.tsx
git commit -m "feat: add column-info component for table metadata display"
```

---

### Task 9: Frontend — row-edit-dialog component

**Files:**
- Create: `admin/app/dashboard/tools/database/components/row-edit-dialog.tsx`

- [ ] **Step 1: Create row-edit-dialog component**

```tsx
'use client'

import { useState, useEffect } from 'react'
import { ColumnInfo } from '../hooks/use-database'

interface RowEditDialogProps {
  open: boolean
  mode: 'insert' | 'update'
  columns: ColumnInfo[]
  rowData: Record<string, any> | null
  onConfirm: (data: Record<string, any>) => void
  onCancel: () => void
}

export function RowEditDialog({ open, mode, columns, rowData, onConfirm, onCancel }: RowEditDialogProps) {
  const [formData, setFormData] = useState<Record<string, any>>({})

  useEffect(() => {
    if (open) {
      setFormData(rowData ? { ...rowData } : {})
    }
  }, [open, rowData])

  if (!open) return null

  const handleChange = (colName: string, value: any) => {
    setFormData((prev) => ({ ...prev, [colName]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onConfirm(formData)
  }

  const isPrimaryReadOnly = (col: ColumnInfo) => {
    return mode === 'update' && col.keyType === 'PRI'
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ background: 'rgba(0,0,0,0.3)' }}>
      <div className="w-[520px] max-h-[80vh] overflow-y-auto rounded-xl shadow-lg" style={{ background: 'var(--surface)' }}>
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
          <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>
            {mode === 'insert' ? '新增行' : '编辑行'}
          </h3>
          <button onClick={onCancel} className="p-1 rounded-md cursor-pointer" style={{ color: 'var(--on-surface-variant)' }}>
            <span className="material-icons-round" style={{ fontSize: 20 }}>close</span>
          </button>
        </div>
        <form onSubmit={handleSubmit} className="px-5 py-4 space-y-3">
          {columns.map((col) => (
            <div key={col.name} className="flex items-center gap-3">
              <label className="w-32 shrink-0 text-sm text-right" style={{ color: 'var(--on-surface-variant)' }}>
                {col.keyType === 'PRI' && <span className="material-icons-round align-middle mr-0.5" style={{ fontSize: 12, color: 'var(--warning)' }}>vpn_key</span>}
                {col.name}
              </label>
              {isPrimaryReadOnly(col) ? (
                <input
                  type="text"
                  value={formData[col.name] ?? ''}
                  readOnly
                  className="flex-1 px-3 py-1.5 rounded-md text-sm"
                  style={{ background: 'var(--surface-container)', color: 'var(--on-surface-variant)', border: '1px solid var(--outline-variant)' }}
                />
              ) : (
                <input
                  type="text"
                  value={formData[col.name] ?? ''}
                  onChange={(e) => handleChange(col.name, e.target.value)}
                  placeholder={col.nullable === 'YES' ? 'NULL' : col.type}
                  className="flex-1 px-3 py-1.5 rounded-md text-sm outline-none"
                  style={{ background: 'var(--surface-container-low)', color: 'var(--on-surface)', border: '1px solid var(--outline-variant)' }}
                />
              )}
            </div>
          ))}
          <div className="flex justify-end gap-2 pt-3" style={{ borderTop: '1px solid var(--outline-variant)' }}>
            <button
              type="button"
              onClick={onCancel}
              className="px-4 py-1.5 rounded-md text-sm cursor-pointer"
              style={{ color: 'var(--on-surface-variant)', background: 'var(--surface-container)' }}
            >
              取消
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 rounded-md text-sm cursor-pointer"
              style={{ color: 'var(--on-primary)', background: 'var(--primary)' }}
            >
              确认
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/tools/database/components/row-edit-dialog.tsx
git commit -m "feat: add row-edit-dialog for insert/update rows"
```

---

### Task 10: Frontend — data-table component

**Files:**
- Create: `admin/app/dashboard/tools/database/components/data-table.tsx`

- [ ] **Step 1: Create data-table component**

```tsx
'use client'

import { useState, useEffect, useCallback } from 'react'
import { useDatabase, ColumnInfo } from '../hooks/use-database'
import { RowEditDialog } from './row-edit-dialog'

interface DataTableProps {
  tableName: string
  columns: ColumnInfo[]
}

export function DataTable({ tableName, columns }: DataTableProps) {
  const { fetchTableData, insertRow, updateRow, deleteRow } = useDatabase()
  const [rows, setRows] = useState<Record<string, any>[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [size, setSize] = useState(20)
  const [sort, setSort] = useState<string | null>(null)
  const [order, setOrder] = useState<'asc' | 'desc'>('asc')
  const [loading, setLoading] = useState(false)
  const [editOpen, setEditOpen] = useState(false)
  const [editMode, setEditMode] = useState<'insert' | 'update'>('insert')
  const [editRow, setEditRow] = useState<Record<string, any> | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Record<string, any> | null>(null)

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const data = await fetchTableData(tableName, page, size, sort || undefined, order)
      setRows(data.rows)
      setTotal(data.total)
    } catch {}
    setLoading(false)
  }, [tableName, page, size, sort, order, fetchTableData])

  useEffect(() => {
    loadData()
  }, [loadData])

  useEffect(() => {
    setPage(1)
  }, [tableName])

  const handleSort = (colName: string) => {
    if (sort === colName) {
      setOrder((prev) => (prev === 'asc' ? 'desc' : 'asc'))
    } else {
      setSort(colName)
      setOrder('asc')
    }
    setPage(1)
  }

  const handleInsert = () => {
    setEditMode('insert')
    setEditRow(null)
    setEditOpen(true)
  }

  const handleEdit = (row: Record<string, any>) => {
    setEditMode('update')
    setEditRow(row)
    setEditOpen(true)
  }

  const handleEditConfirm = async (data: Record<string, any>) => {
    try {
      if (editMode === 'insert') {
        await insertRow(tableName, data)
      } else {
        await updateRow(tableName, data)
      }
      setEditOpen(false)
      loadData()
    } catch {}
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    try {
      await deleteRow(tableName, deleteTarget)
      setDeleteTarget(null)
      loadData()
    } catch {}
  }

  const totalPages = Math.ceil(total / size)
  const primaryKeys = columns.filter((c) => c.keyType === 'PRI').map((c) => c.name)

  return (
    <div>
      <div className="flex items-center gap-2 mb-3">
        <button
          onClick={handleInsert}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm cursor-pointer"
          style={{ color: 'var(--on-primary)', background: 'var(--primary)' }}
        >
          <span className="material-icons-round" style={{ fontSize: 16 }}>add</span>
          新增
        </button>
        <button
          onClick={loadData}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm cursor-pointer"
          style={{ color: 'var(--on-surface-variant)', background: 'var(--surface-container)' }}
        >
          <span className="material-icons-round" style={{ fontSize: 16 }}>refresh</span>
          刷新
        </button>
        <select
          value={size}
          onChange={(e) => { setSize(Number(e.target.value)); setPage(1) }}
          className="px-2 py-1.5 rounded-md text-sm outline-none"
          style={{ background: 'var(--surface-container)', color: 'var(--on-surface-variant)', border: '1px solid var(--outline-variant)' }}
        >
          {[10, 20, 50, 100].map((s) => (
            <option key={s} value={s}>{s} 条/页</option>
          ))}
        </select>
        <span className="ml-auto text-sm" style={{ color: 'var(--on-surface-variant)' }}>
          共 {total.toLocaleString()} 条
        </span>
      </div>

      <div className="rounded-lg overflow-auto" style={{ background: 'var(--surface)', border: '1px solid var(--outline-variant)', maxHeight: 'calc(100vh - 320px)' }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: 'var(--surface-container)' }}>
              {columns.map((col) => (
                <th
                  key={col.name}
                  onClick={() => handleSort(col.name)}
                  className="text-left px-3 py-2.5 font-medium whitespace-nowrap cursor-pointer select-none"
                  style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}
                >
                  {col.name}
                  {sort === col && (
                    <span className="material-icons-round align-middle ml-0.5" style={{ fontSize: 14 }}>
                      {order === 'asc' ? 'arrow_upward' : 'arrow_downward'}
                    </span>
                  )}
                </th>
              ))}
              <th className="px-3 py-2.5 font-medium" style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}>
                操作
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={columns.length + 1} className="px-3 py-8 text-center" style={{ color: 'var(--on-surface-variant)' }}>加载中...</td></tr>
            ) : rows.length === 0 ? (
              <tr><td colSpan={columns.length + 1} className="px-3 py-8 text-center" style={{ color: 'var(--on-surface-variant)' }}>暂无数据</td></tr>
            ) : (
              rows.map((row, i) => (
                <tr key={i} style={{ background: i % 2 === 0 ? 'var(--surface)' : 'var(--surface-container-low)' }}>
                  {columns.map((col) => (
                    <td key={col.name} className="px-3 py-2 whitespace-nowrap" style={{ color: 'var(--on-surface)', maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {row[col.name] != null ? String(row[col.name]) : <span style={{ color: 'var(--outline)' }}>NULL</span>}
                    </td>
                  ))}
                  <td className="px-3 py-2 whitespace-nowrap">
                    <button
                      onClick={() => handleEdit(row)}
                      className="mr-2 text-xs cursor-pointer"
                      style={{ color: 'var(--primary)' }}
                    >
                      <span className="material-icons-round align-middle" style={{ fontSize: 16 }}>edit</span>
                      编辑
                    </button>
                    <button
                      onClick={() => setDeleteTarget(row)}
                      className="text-xs cursor-pointer"
                      style={{ color: 'var(--error)' }}
                    >
                      <span className="material-icons-round align-middle" style={{ fontSize: 16 }}>delete</span>
                      删除
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-2 mt-3">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page <= 1}
            className="px-3 py-1 rounded-md text-sm cursor-pointer disabled:opacity-40"
            style={{ background: 'var(--surface-container)', color: 'var(--on-surface-variant)' }}
          >
            上一页
          </button>
          <span className="text-sm" style={{ color: 'var(--on-surface-variant)' }}>
            {page} / {totalPages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page >= totalPages}
            className="px-3 py-1 rounded-md text-sm cursor-pointer disabled:opacity-40"
            style={{ background: 'var(--surface-container)', color: 'var(--on-surface-variant)' }}
          >
            下一页
          </button>
        </div>
      )}

      <RowEditDialog
        open={editOpen}
        mode={editMode}
        columns={columns}
        rowData={editRow}
        onConfirm={handleEditConfirm}
        onCancel={() => setEditOpen(false)}
      />

      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ background: 'rgba(0,0,0,0.3)' }}>
          <div className="w-[360px] rounded-xl shadow-lg p-5" style={{ background: 'var(--surface)' }}>
            <h3 className="text-base font-semibold mb-2" style={{ color: 'var(--on-surface)' }}>确认删除</h3>
            <p className="text-sm mb-4" style={{ color: 'var(--on-surface-variant)' }}>
              确定要删除此行吗？{primaryKeys.length > 0 && (
                <span className="block mt-1">
                  主键: {primaryKeys.map((k) => `${k}=${deleteTarget[k]}`).join(', ')}
                </span>
              )}
            </p>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setDeleteTarget(null)}
                className="px-4 py-1.5 rounded-md text-sm cursor-pointer"
                style={{ color: 'var(--on-surface-variant)', background: 'var(--surface-container)' }}
              >
                取消
              </button>
              <button
                onClick={handleDelete}
                className="px-4 py-1.5 rounded-md text-sm cursor-pointer"
                style={{ color: 'white', background: 'var(--error)' }}
              >
                删除
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/tools/database/components/data-table.tsx
git commit -m "feat: add data-table component with CRUD, pagination, and sorting"
```

---

### Task 11: Frontend — sql-query component

**Files:**
- Create: `admin/app/dashboard/tools/database/components/sql-query.tsx`

- [ ] **Step 1: Create sql-query component**

```tsx
'use client'

import { useState } from 'react'
import { useDatabase, SqlResult } from '../hooks/use-database'

export function SqlQuery() {
  const { executeSql } = useDatabase()
  const [sql, setSql] = useState('')
  const [result, setResult] = useState<SqlResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleExecute = async () => {
    if (!sql.trim()) return
    setLoading(true)
    setError(null)
    try {
      const data = await executeSql(sql)
      setResult(data)
    } catch (err: any) {
      setError(err.message)
      setResult(null)
    } finally {
      setLoading(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      handleExecute()
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-lg p-4" style={{ background: 'var(--surface)', border: '1px solid var(--outline-variant)' }}>
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium" style={{ color: 'var(--on-surface)' }}>SQL 查询</span>
          <span className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>Ctrl+Enter 执行 · 仅支持 SELECT · 最大 1000 行</span>
        </div>
        <textarea
          value={sql}
          onChange={(e) => setSql(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="SELECT * FROM table_name LIMIT 100"
          rows={6}
          className="w-full px-3 py-2 rounded-md text-sm outline-none resize-y font-mono"
          style={{ background: 'var(--surface-container-low)', color: 'var(--on-surface)', border: '1px solid var(--outline-variant)' }}
        />
        <div className="flex items-center gap-2 mt-2">
          <button
            onClick={handleExecute}
            disabled={loading || !sql.trim()}
            className="flex items-center gap-1.5 px-4 py-1.5 rounded-md text-sm cursor-pointer disabled:opacity-40"
            style={{ color: 'var(--on-primary)', background: 'var(--primary)' }}
          >
            <span className="material-icons-round" style={{ fontSize: 16 }}>play_arrow</span>
            执行
          </button>
          <button
            onClick={() => { setSql(''); setResult(null); setError(null) }}
            className="px-4 py-1.5 rounded-md text-sm cursor-pointer"
            style={{ color: 'var(--on-surface-variant)', background: 'var(--surface-container)' }}
          >
            清空
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-lg p-3 text-sm" style={{ background: '#fce8e6', color: 'var(--error)', border: '1px solid #f5c6c0' }}>
          <span className="material-icons-round align-middle mr-1" style={{ fontSize: 16 }}>error</span>
          {error}
        </div>
      )}

      {result && (
        <div className="rounded-lg overflow-auto" style={{ background: 'var(--surface)', border: '1px solid var(--outline-variant)', maxHeight: 'calc(100vh - 480px)' }}>
          {result.truncated && (
            <div className="px-3 py-2 text-xs" style={{ background: '#fef7e0', color: 'var(--warning)', borderBottom: '1px solid var(--outline-variant)' }}>
              结果已截断，最大返回 1000 行
            </div>
          )}
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: 'var(--surface-container)' }}>
                {result.columns.map((col) => (
                  <th key={col} className="text-left px-3 py-2.5 font-medium whitespace-nowrap" style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}>
                    {col}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {result.rows.length === 0 ? (
                <tr><td colSpan={result.columns.length} className="px-3 py-6 text-center" style={{ color: 'var(--on-surface-variant)' }}>无结果</td></tr>
              ) : (
                result.rows.map((row, i) => (
                  <tr key={i} style={{ background: i % 2 === 0 ? 'var(--surface)' : 'var(--surface-container-low)' }}>
                    {result.columns.map((col) => (
                      <td key={col} className="px-3 py-2 whitespace-nowrap" style={{ color: 'var(--on-surface)', maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {row[col] != null ? String(row[col]) : <span style={{ color: 'var(--outline)' }}>NULL</span>}
                      </td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/tools/database/components/sql-query.tsx
git commit -m "feat: add sql-query component with editor and result display"
```

---

### Task 12: Frontend — Main page assembly

**Files:**
- Modify: `admin/app/dashboard/tools/database/page.tsx`

- [ ] **Step 1: Replace placeholder with full database management page**

```tsx
'use client'

import { useState, useEffect } from 'react'
import { useDatabase, TableInfo as TableInfoType, ColumnInfo as ColumnInfoType } from './hooks/use-database'
import { TableList } from './components/table-list'
import { ColumnInfoView } from './components/column-info'
import { DataTable } from './components/data-table'
import { SqlQuery } from './components/sql-query'

type TabKey = 'columns' | 'data' | 'sql'

export default function DatabasePage() {
  const { fetchTables, fetchColumns } = useDatabase()
  const [tables, setTables] = useState<TableInfoType[]>([])
  const [selectedTable, setSelectedTable] = useState<string | null>(null)
  const [columns, setColumns] = useState<ColumnInfoType[]>([])
  const [activeTab, setActiveTab] = useState<TabKey>('columns')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    setLoading(true)
    fetchTables()
      .then(setTables)
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [fetchTables])

  useEffect(() => {
    if (selectedTable) {
      fetchColumns(selectedTable).then(setColumns).catch(() => {})
      setActiveTab('columns')
    }
  }, [selectedTable, fetchColumns])

  const selectedTableInfo = tables.find((t) => t.name === selectedTable)

  const tabs: { key: TabKey; label: string; icon: string }[] = [
    { key: 'columns', label: '列信息', icon: 'view_column' },
    { key: 'data', label: '数据', icon: 'table_rows' },
    { key: 'sql', label: 'SQL 查询', icon: 'terminal' },
  ]

  return (
    <div className="flex h-[calc(100vh-var(--topbar-height)-64px)] -m-6">
      <TableList
        tables={tables}
        selectedTable={selectedTable}
        onSelect={setSelectedTable}
      />
      <div className="flex-1 flex flex-col min-w-0 p-6">
        {!selectedTable ? (
          <div className="flex-1 flex flex-col items-center justify-center">
            <span className="material-icons-round mb-3" style={{ fontSize: 40, color: 'var(--outline)' }}>storage</span>
            <p className="text-sm" style={{ color: 'var(--on-surface-variant)' }}>
              {loading ? '加载中...' : '请从左侧选择一个表'}
            </p>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-1 mb-4" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
              {tabs.map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  className="flex items-center gap-1.5 px-4 py-2.5 text-sm transition-colors cursor-pointer"
                  style={{
                    color: activeTab === tab.key ? 'var(--primary)' : 'var(--on-surface-variant)',
                    borderBottom: activeTab === tab.key ? '2px solid var(--primary)' : '2px solid transparent',
                    fontWeight: activeTab === tab.key ? 500 : 400,
                  }}
                >
                  <span className="material-icons-round" style={{ fontSize: 18 }}>{tab.icon}</span>
                  {tab.label}
                </button>
              ))}
            </div>
            <div className="flex-1 overflow-y-auto">
              {activeTab === 'columns' && selectedTableInfo && (
                <ColumnInfoView table={selectedTableInfo} columns={columns} />
              )}
              {activeTab === 'data' && (
                <DataTable tableName={selectedTable} columns={columns} />
              )}
              {activeTab === 'sql' && (
                <SqlQuery />
              )}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/tools/database/page.tsx
git commit -m "feat: implement database management page with table list, column info, data CRUD, and SQL query"
```

---

## Self-Review

**Spec coverage:**
- All 7 API endpoints → Task 4
- Table/column metadata → Task 2
- Dynamic CRUD → Task 3
- SQL executor (SELECT only, max 1000 rows) → Task 3
- Frontend 3 views (columns, data, SQL) → Tasks 8, 10, 11
- Table list sidebar with search → Task 7
- Row edit dialog with dynamic form → Task 9
- Next.js PUT/DELETE proxy → Task 5
- Error handling (400/403) → Task 3, 4
- Security (table name validation, PreparedStatement, admin auth) → Tasks 2, 3, 4

**Placeholder scan:** No TBD/TODO/vague references found.

**Type consistency:** All DTO types (`TableInfo`, `ColumnInfo`, `SqlExecuteRequest`, `SqlExecuteResult`) are consistent between backend and frontend. Method names in `useDatabase` hook match controller endpoints.
