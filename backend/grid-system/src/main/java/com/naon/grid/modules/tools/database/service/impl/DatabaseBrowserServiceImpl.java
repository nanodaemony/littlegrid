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
