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
