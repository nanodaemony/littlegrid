package com.naon.grid.modules.app.treehole.service.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Data
public class CreateReplyDTO {

    @NotBlank(message = "内容不能为空")
    @Size(max = 300, message = "内容最多300字")
    private String content;

    private Long parentId;
}
