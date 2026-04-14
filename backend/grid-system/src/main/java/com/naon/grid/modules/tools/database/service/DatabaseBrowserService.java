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
