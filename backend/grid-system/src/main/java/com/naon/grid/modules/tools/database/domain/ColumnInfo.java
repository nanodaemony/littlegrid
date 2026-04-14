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
