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
