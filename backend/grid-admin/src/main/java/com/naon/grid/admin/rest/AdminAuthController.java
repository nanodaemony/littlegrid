package com.naon.grid.admin.rest;

import com.naon.grid.admin.security.AdminTokenProvider;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Api(tags = "Admin：认证接口")
public class AdminAuthController {

    private final AdminTokenProvider adminTokenProvider;

    @Value("${admin.username:admin}")
    private String adminUsername;

    @Value("${admin.password:admin123}")
    private String adminPassword;

    @Data
    public static class LoginRequest {
        private String username;
        private String password;
    }

    @PostMapping("/login")
    @ApiOperation("Admin登录")
    public ResponseEntity<Map<String, Object>> login(@Validated @RequestBody LoginRequest request) {
        if (!adminUsername.equals(request.getUsername()) || !adminPassword.equals(request.getPassword())) {
            Map<String, Object> err = new HashMap<>();
            err.put("message", "用户名或密码错误");
            return ResponseEntity.status(401).body(err);
        }

        String token = adminTokenProvider.createToken(request.getUsername());
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("username", request.getUsername());
        return ResponseEntity.ok(result);
    }

    @GetMapping("/verify")
    @ApiOperation("验证Token")
    public ResponseEntity<Map<String, Object>> verify(@RequestHeader("Authorization") String authHeader) {
        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        if (!adminTokenProvider.validateToken(token)) {
            Map<String, Object> err = new HashMap<>();
            err.put("message", "Token无效或已过期");
            return ResponseEntity.status(401).body(err);
        }

        String username = adminTokenProvider.getUsernameFromToken(token);
        Map<String, Object> result = new HashMap<>();
        result.put("valid", true);
        result.put("username", username);
        return ResponseEntity.ok(result);
    }
}
