package com.naon.grid.modules.app.feedback.service.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import java.util.List;

@Data
public class SubmitFeedbackDTO {

    @NotNull(message = "反馈类型不能为空")
    private String type;

    @NotBlank(message = "描述不能为空")
    @Size(max = 500, message = "描述最多500字")
    private String description;

    private List<String> screenshots;
}
