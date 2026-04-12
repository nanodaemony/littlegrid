package com.naon.grid.modules.app.service.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Data
public class RegisterDTO {
    @NotBlank(message = "密码不能为空")
    @ApiModelProperty(value = "密码（RSA加密）", required = true)
    private String password;

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    @ApiModelProperty(value = "手机号", required = true)
    private String phone;

    @ApiModelProperty(value = "邮箱")
    private String email;

    @ApiModelProperty(value = "昵称")
    private String nickname;

    @NotBlank(message = "设备ID不能为空")
    @ApiModelProperty(value = "设备ID", required = true)
    private String deviceId;

    @ApiModelProperty(value = "设备信息")
    private DeviceInfoDTO deviceInfo;
}
