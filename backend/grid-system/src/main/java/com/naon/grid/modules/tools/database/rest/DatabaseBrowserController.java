/*
 *  Copyright 2019-2025 Zheng Jie
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
package com.naon.grid.modules.tools.database.rest;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import com.naon.grid.annotation.Log;
import com.naon.grid.modules.tools.database.domain.ColumnInfo;
import com.naon.grid.modules.tools.database.domain.TableData;
import com.naon.grid.modules.tools.database.domain.TableInfo;
import com.naon.grid.modules.tools.database.service.DatabaseBrowserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
* @author database-browser
* @date 2026-04-14
*/
@Api(tags = "系统工具：数据库浏览器")
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/database-browser")
public class DatabaseBrowserController {

    private final DatabaseBrowserService databaseBrowserService;

    @ApiOperation(value = "获取所有表列表")
    @GetMapping("/tables")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<List<TableInfo>> getAllTables() {
        return new ResponseEntity<>(databaseBrowserService.getAllTables(), HttpStatus.OK);
    }

    @ApiOperation(value = "获取表结构")
    @GetMapping("/tables/{tableName}/columns")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<List<ColumnInfo>> getTableColumns(@PathVariable String tableName) {
        return new ResponseEntity<>(databaseBrowserService.getTableColumns(tableName), HttpStatus.OK);
    }

    @ApiOperation(value = "分页查询表数据")
    @GetMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<TableData> getTableData(
            @PathVariable String tableName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return new ResponseEntity<>(databaseBrowserService.getTableData(tableName, page, size), HttpStatus.OK);
    }

    @Log("新增数据")
    @ApiOperation(value = "新增数据")
    @PostMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:add')")
    public ResponseEntity<Object> insertData(
            @PathVariable String tableName,
            @Validated @RequestBody Map<String, Object> data) {
        databaseBrowserService.insertData(tableName, data);
        return new ResponseEntity<>(HttpStatus.CREATED);
    }

    @Log("修改数据")
    @ApiOperation(value = "修改数据")
    @PutMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:edit')")
    public ResponseEntity<Object> updateData(
            @PathVariable String tableName,
            @RequestBody UpdateDataRequest request) {
        databaseBrowserService.updateData(tableName, request.getData(), request.getWhereClause());
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @Log("删除数据")
    @ApiOperation(value = "删除数据")
    @DeleteMapping("/tables/{tableName}/data")
    @PreAuthorize("@el.check('databaseBrowser:del')")
    public ResponseEntity<Object> deleteData(
            @PathVariable String tableName,
            @RequestBody Map<String, Object> whereClause) {
        databaseBrowserService.deleteData(tableName, whereClause);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @ApiOperation(value = "检查表是否为敏感表")
    @GetMapping("/tables/{tableName}/sensitive")
    @PreAuthorize("@el.check('databaseBrowser:list')")
    public ResponseEntity<Map<String, Boolean>> isSensitiveTable(@PathVariable String tableName) {
        return new ResponseEntity<>(Map.of("sensitive", databaseBrowserService.isSensitiveTable(tableName)), HttpStatus.OK);
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateDataRequest {
        private Map<String, Object> data;
        private Map<String, Object> whereClause;
    }
}
