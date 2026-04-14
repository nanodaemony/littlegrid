package com.naon.grid.modules.app.treehole.service.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Data
public class CreatePostDTO {

    @NotBlank(message = "内容不能为空")
    @Size(max = 500, message = "内容最多500字")
    private String content;

    @NotBlank(message = "标签不能为空")
    @Size(max = 20, message = "标签最多20字")
    private String tag;
}
