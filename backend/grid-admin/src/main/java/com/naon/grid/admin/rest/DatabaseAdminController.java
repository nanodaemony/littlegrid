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