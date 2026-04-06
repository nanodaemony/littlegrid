# APP 用户注册登录系统实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现完整的 APP 用户注册登录系统，包括后端 grid-app 模块和客户端 API 集成。

**Architecture:** 采用 JWT + Redis 鉴权方案，独立 grid-app 模块管理 APP 用户数据，多端登录支持最多 3 台设备，与现有 Admin 系统分离。

**Tech Stack:** Spring Boot 2.7, Spring Security, JWT, Redis, MySQL, Flutter/Dart

---

## 前置阅读

开始实现前，请阅读以下文档：

1. **设计文档**: `docs/superpowers/specs/2025-04-05-app-auth-design.md`
   - 数据模型定义
   - API 接口规范
   - 架构设计说明

2. **现有代码参考**:
   - `backend/grid-system/src/main/java/com/naon/grid/modules/security/` - 现有安全模块
   - `backend/grid-app/pom.xml` - 已存在的模块结构

---

## 文件结构总览

### 后端 (backend/grid-app)

```
src/main/java/com/naon/grid/modules/app/
├── config/
│   └── AppSecurityConfig.java              # APP安全配置
├── domain/
│   └── GridUser.java                       # 用户实体
├── repository/
│   └── GridUserRepository.java             # 数据访问层
├── service/
│   ├── dto/
│   │   ├── RegisterDTO.java
│   │   ├── LoginDTO.java
│   │   ├── TokenDTO.java
│   │   ├── RefreshTokenDTO.java
│   │   └── AppUserDTO.java
│   ├── impl/
│   │   └── AppAuthServiceImpl.java
│   ├── AppAuthService.java
│   └── AppUserService.java
├── rest/
│   ├── AppAuthController.java              # 认证接口
│   └── AppUserController.java              # 用户接口
├── security/
│   ├── AppTokenProvider.java               # APP Token生成
│   ├── AppTokenFilter.java                 # Token过滤器
│   └── DeviceManager.java                  # 设备管理
└── enums/
    ├── AppErrorCode.java
    ├── AppUserStatus.java
    └── Gender.java
```

### 客户端 (app)

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart              # API端点配置
│   ├── models/
│   │   ├── user_model.dart
│   │   └── token_model.dart
│   └── services/
│       ├── api/
│       │   ├── app_auth_api.dart           # 认证API
│       │   └── app_user_api.dart
│       ├── http_service.dart
│       └── token_manager.dart
├── providers/
│   └── auth_provider.dart
└── pages/
    └── login/
        ├── login_page.dart
        ├── register_page.dart
        └── forgot_password_page.dart
```

---

## Task 列表

### Phase 1: 基础架构 (Foundation)

#### Task 1: 完善 grid-app 模块的 Maven 配置

**Files:**
- Modify: `backend/grid-app/pom.xml`

**Description:**
补充 grid-app 模块的依赖配置，确保可以引用 grid-system 和 grid-common 的安全组件。

- [ ] **Step 1: 添加必要依赖**

```xml
<!-- 在 dependencies 节点下添加 -->
<dependency>
    <groupId>com.naon.grid</groupId>
    <artifactId>grid-common</artifactId>
    <version>2.7</version>
</dependency>
<dependency>
    <groupId>com.naon.grid</groupId>
    <artifactId>grid-system</artifactId>
    <version>2.7</version>
</dependency>
```

- [ ] **Step 2: 验证配置**

Run: `cd backend && mvn clean compile -pl grid-app -am`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/grid-app/pom.xml
git commit -m "feat(grid-app): add module dependencies"
```

---

#### Task 2: 创建数据库表 grid_user

**Files:**
- Create: `backend/grid-app/src/main/resources/db/migration/V1__Create_grid_user_table.sql`

**Description:**
创建 grid_user 表，用于存储 APP 用户信息。

- [ ] **Step 1: 创建 SQL 文件**

```sql
CREATE TABLE IF NOT EXISTS `grid_user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(100) NOT NULL COMMENT '密码（BCrypt加密）',
    `phone` VARCHAR(20) NOT NULL COMMENT '手机号',
    `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    `nickname` VARCHAR(50) DEFAULT NULL COMMENT '昵称',
    `avatar` VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
    `gender` TINYINT DEFAULT 0 COMMENT '性别：0-未知 1-男 2-女',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0-禁用 1-正常',
    `register_ip` VARCHAR(50) DEFAULT NULL COMMENT '注册IP',
    `last_login_time` DATETIME DEFAULT NULL COMMENT '最后登录时间',
    `last_login_ip` VARCHAR(50) DEFAULT NULL COMMENT '最后登录IP',
    `wx_openid` VARCHAR(50) DEFAULT NULL COMMENT '微信openid',
    `wx_unionid` VARCHAR(50) DEFAULT NULL COMMENT '微信unionid',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_phone` (`phone`),
    KEY `idx_wx_openid` (`wx_openid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='APP用户表';
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-app/src/main/resources/db/migration/
git commit -m "feat(grid-app): create grid_user table"
```

---

### Phase 2: 数据层实现 (Data Layer)

#### Task 3: 创建 GridUser 实体类

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/domain/GridUser.java`

**Description:**
创建 APP 用户实体类，映射 grid_user 表。

- [ ] **Step 1: 创建实体类**

```java
package com.naon.grid.modules.app.domain;

import com.naon.grid.base.BaseEntity;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import java.io.Serializable;
import java.util.Date;

/**
 * APP用户实体
 */
@Entity
@Getter
@Setter
@Table(name = "grid_user")
public class GridUser extends BaseEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "用户名不能为空")
    @Column(name = "username", nullable = false, unique = true, length = 50)
    private String username;

    @NotBlank(message = "密码不能为空")
    @Column(name = "password", nullable = false, length = 100)
    private String password;

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    @Column(name = "phone", nullable = false, unique = true, length = 20)
    private String phone;

    @Email(message = "邮箱格式不正确")
    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "nickname", length = 50)
    private String nickname;

    @Column(name = "avatar", length = 500)
    private String avatar;

    @Column(name = "gender")
    private Integer gender = 0;

    @NotNull
    @Column(name = "status", nullable = false)
    private Integer status = 1;

    @Column(name = "register_ip", length = 50)
    private String registerIp;

    @Column(name = "last_login_time")
    private Date lastLoginTime;

    @Column(name = "last_login_ip", length = 50)
    private String lastLoginIp;

    @Column(name = "wx_openid", length = 50)
    private String wxOpenid;

    @Column(name = "wx_unionid", length = 50)
    private String wxUnionid;
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/domain/
git commit -m "feat(grid-app): add GridUser entity"
```

---

#### Task 4: 创建 GridUserRepository

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/repository/GridUserRepository.java`

**Description:**
创建数据访问层，提供查询用户的方法。

- [ ] **Step 1: 创建 Repository**

```java
package com.naon.grid.modules.app.repository;

import com.naon.grid.modules.app.domain.GridUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * APP用户数据访问层
 */
@Repository
public interface GridUserRepository extends JpaRepository<GridUser, Long>, JpaSpecificationExecutor<GridUser> {

    /**
     * 根据用户名查询用户
     */
    Optional<GridUser> findByUsername(String username);

    /**
     * 根据手机号查询用户
     */
    Optional<GridUser> findByPhone(String phone);

    /**
     * 根据用户名判断是否存在
     */
    boolean existsByUsername(String username);

    /**
     * 根据手机号判断是否存在
     */
    boolean existsByPhone(String phone);

    /**
     * 根据邮箱查询用户
     */
    Optional<GridUser> findByEmail(String email);
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/repository/
git commit -m "feat(grid-app): add GridUserRepository"
```

---

#### Task 5: 创建枚举类

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/enums/AppUserStatus.java`
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/enums/Gender.java`
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/enums/AppErrorCode.java`

**Description:**
创建 APP 模块专用枚举类。

- [ ] **Step 1: 创建 AppUserStatus 枚举**

```java
package com.naon.grid.modules.app.enums;

import lombok.Getter;

/**
 * APP用户状态
 */
@Getter
public enum AppUserStatus {

    DISABLED(0, "禁用"),
    ENABLED(1, "正常");

    private final Integer code;
    private final String description;

    AppUserStatus(Integer code, String description) {
        this.code = code;
        this.description = description;
    }
}
```

- [ ] **Step 2: 创建 Gender 枚举**

```java
package com.naon.grid.modules.app.enums;

import lombok.Getter;

/**
 * 性别
 */
@Getter
public enum Gender {

    UNKNOWN(0, "未知"),
    MALE(1, "男"),
    FEMALE(2, "女");

    private final Integer code;
    private final String description;

    Gender(Integer code, String description) {
        this.code = code;
        this.description = description;
    }
}
```

- [ ] **Step 3: 创建 AppErrorCode 枚举**

```java
package com.naon.grid.modules.app.enums;

import lombok.Getter;

/**
 * APP模块错误码
 */
@Getter
public enum AppErrorCode {

    // 认证相关 1000-1099
    USERNAME_EXISTS(1000, "用户名已存在"),
    PHONE_EXISTS(1001, "手机号已注册"),
    INVALID_CREDENTIALS(1002, "手机号或密码错误"),
    USER_DISABLED(1003, "账号已被禁用"),
    TOKEN_EXPIRED(1004, "Token已过期"),
    TOKEN_INVALID(1005, "无效的Token"),
    DEVICE_LIMIT_EXCEEDED(1006, "设备数量超出限制"),

    // 参数错误 1100-1199
    INVALID_PHONE(1100, "手机号格式错误"),
    INVALID_PASSWORD(1101, "密码格式错误"),

    // 系统错误 5000-5999
    SYSTEM_ERROR(5000, "系统繁忙，请稍后重试");

    private final int code;
    private final String message;

    AppErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/enums/
git commit -m "feat(grid-app): add enums for user status, gender and error codes"
```

---

### Phase 3: DTO 定义 (DTOs)

#### Task 6: 创建请求/响应 DTO

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/RegisterDTO.java`
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/LoginDTO.java`
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/TokenDTO.java`
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/AppUserDTO.java`
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/DeviceInfoDTO.java`

**Description:**
创建数据传输对象，用于前后端数据交互。

- [ ] **Step 1: 创建 RegisterDTO**

```java
package com.naon.grid.modules.app.service.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * 注册请求DTO
 */
@Data
public class RegisterDTO {

    @NotBlank(message = "用户名不能为空")
    @Pattern(regexp = "^[a-zA-Z0-9_]{3,20}$", message = "用户名只能包含3-20位字母、数字或下划线")
    @ApiModelProperty(value = "用户名", required = true)
    private String username;

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
```

- [ ] **Step 2: 创建 LoginDTO**

```java
package com.naon.grid.modules.app.service.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * 登录请求DTO
 */
@Data
public class LoginDTO {

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    @ApiModelProperty(value = "手机号", required = true)
    private String phone;

    @NotBlank(message = "密码不能为空")
    @ApiModelProperty(value = "密码（RSA加密）", required = true)
    private String password;

    @NotBlank(message = "设备ID不能为空")
    @ApiModelProperty(value = "设备ID", required = true)
    private String deviceId;

    @ApiModelProperty(value = "设备信息")
    private DeviceInfoDTO deviceInfo;
}
```

- [ ] **Step 3: 创建 DeviceInfoDTO**

```java
package com.naon.grid.modules.app.service.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

/**
 * 设备信息DTO
 */
@Data
public class DeviceInfoDTO {

    @ApiModelProperty(value = "操作系统")
    private String os;

    @ApiModelProperty(value = "系统版本")
    private String version;

    @ApiModelProperty(value = "设备型号")
    private String model;

    @ApiModelProperty(value = "应用版本")
    private String appVersion;
}
```

- [ ] **Step 4: 创建 TokenDTO**

```java
package com.naon.grid.modules.app.service.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

/**
 * Token响应DTO
 */
@Data
public class TokenDTO {

    @ApiModelProperty(value = "访问Token")
    private String token;

    @ApiModelProperty(value = "刷新Token")
    private String refreshToken;

    @ApiModelProperty(value = "过期时间（秒）")
    private Long expiresIn;

    @ApiModelProperty(value = "用户信息")
    private AppUserDTO user;
}
```

- [ ] **Step 5: 创建 AppUserDTO**

```java
package com.naon.grid.modules.app.service.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import java.util.Date;

/**
 * APP用户信息DTO
 */
@Data
public class AppUserDTO {

    @ApiModelProperty(value = "用户ID")
    private Long id;

    @ApiModelProperty(value = "用户名")
    private String username;

    @ApiModelProperty(value = "昵称")
    private String nickname;

    @ApiModelProperty(value = "手机号（脱敏）")
    private String phone;

    @ApiModelProperty(value = "邮箱")
    private String email;

    @ApiModelProperty(value = "头像URL")
    private String avatar;

    @ApiModelProperty(value = "性别：0-未知 1-男 2-女")
    private Integer gender;

    @ApiModelProperty(value = "状态：0-禁用 1-正常")
    private Integer status;

    @ApiModelProperty(value = "创建时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    private Date createdAt;
}
```

- [ ] **Step 6: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/service/dto/
git commit -m "feat(grid-app): add DTOs for auth requests and responses"
```

---

### Phase 4: 业务层实现 (Service Layer)

#### Task 7: 创建 DeviceManager 设备管理

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/security/DeviceManager.java`

**Description:**
管理用户设备登录，限制最多3台设备同时在线。

- [ ] **Step 1: 创建设备管理类**

```java
package com.naon.grid.modules.app.security;

import com.naon.grid.utils.RedisUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * APP设备管理器
 * 管理用户多设备登录，支持最多3台设备同时在线
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DeviceManager {

    private final RedisUtils redisUtils;

    @Value("${app.auth.max-devices:3}")
    private int maxDevices;

    @Value("${app.auth.token-validity-in-seconds:604800}")
    private long tokenValidityInSeconds;

    private static final String DEVICE_SET_KEY_PREFIX = "app:devices:";
    private static final String TOKEN_KEY_PREFIX = "app:token:";

    /**
     * 检查用户是否已达到设备上限
     */
    public boolean isDeviceLimitExceeded(Long userId) {
        String deviceSetKey = DEVICE_SET_KEY_PREFIX + userId;
        Set<Object> devices = redisUtils.sGet(deviceSetKey);
        return devices != null && devices.size() >= maxDevices;
    }

    /**
     * 注册设备登录
     * 如果超过设备限制，踢出最早登录的设备
     */
    public void registerDevice(Long userId, String deviceId, String token) {
        String deviceSetKey = DEVICE_SET_KEY_PREFIX + userId;
        String tokenKey = TOKEN_KEY_PREFIX + userId + ":" + deviceId;

        // 检查设备数是否超限
        if (isDeviceLimitExceeded(userId)) {
            // 踢出最早登录的设备
            kickOutOldestDevice(userId);
        }

        // 添加到设备集合
        redisUtils.sSetAndTime(deviceSetKey, tokenValidityInSeconds, deviceId);

        // 保存token
        redisUtils.set(tokenKey, token, tokenValidityInSeconds, TimeUnit.SECONDS);

        log.info("用户 {} 设备 {} 登录成功", userId, deviceId);
    }

    /**
     * 移除设备登录
     */
    public void removeDevice(Long userId, String deviceId) {
        String deviceSetKey = DEVICE_SET_KEY_PREFIX + userId;
        String tokenKey = TOKEN_KEY_PREFIX + userId + ":" + deviceId;

        redisUtils.setRemove(deviceSetKey, deviceId);
        redisUtils.del(tokenKey);

        log.info("用户 {} 设备 {} 已退出", userId, deviceId);
    }

    /**
     * 踢出最早登录的设备
     */
    private void kickOutOldestDevice(Long userId) {
        String deviceSetKey = DEVICE_SET_KEY_PREFIX + userId;
        Set<Object> devices = redisUtils.sGet(deviceSetKey);

        if (devices == null || devices.isEmpty()) {
            return;
        }

        // 找到最早过期的设备（这里简化为随机踢出一个）
        // 更精确的做法是为每个设备记录登录时间
        Object oldestDevice = devices.iterator().next();
        removeDevice(userId, (String) oldestDevice);

        log.info("用户 {} 设备 {} 被踢出（超出设备限制）", userId, oldestDevice);
    }

    /**
     * 判断设备是否在线
     */
    public boolean isDeviceOnline(Long userId, String deviceId) {
        String deviceSetKey = DEVICE_SET_KEY_PREFIX + userId;
        return redisUtils.sHasKey(deviceSetKey, deviceId);
    }

    /**
     * 获取用户的所有在线设备
     */
    public Set<Object> getUserDevices(Long userId) {
        String deviceSetKey = DEVICE_SET_KEY_PREFIX + userId;
        return redisUtils.sGet(deviceSetKey);
    }

    /**
     * 用户退出所有设备
     */
    public void clearAllDevices(Long userId) {
        String deviceSetKey = DEVICE_SET_KEY_PREFIX + userId;
        Set<Object> devices = redisUtils.sGet(deviceSetKey);

        if (devices != null) {
            for (Object deviceId : devices) {
                String tokenKey = TOKEN_KEY_PREFIX + userId + ":" + deviceId;
                redisUtils.del(tokenKey);
            }
        }

        redisUtils.del(deviceSetKey);
        log.info("用户 {} 所有设备已退出", userId);
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/security/DeviceManager.java
git commit -m "feat(grid-app): add DeviceManager for multi-device login control"
```

---

#### Task 8: 创建 AppAuthService 服务层

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/AppAuthService.java`
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/service/impl/AppAuthServiceImpl.java`

**Description:**
实现注册、登录、退出等核心业务逻辑。

- [ ] **Step 1: 创建 Service 接口**

```java
package com.naon.grid.modules.app.service;

import com.naon.grid.modules.app.service.dto.LoginDTO;
import com.naon.grid.modules.app.service.dto.RegisterDTO;
import com.naon.grid.modules.app.service.dto.TokenDTO;

import javax.servlet.http.HttpServletRequest;

/**
 * APP认证服务接口
 */
public interface AppAuthService {

    /**
     * 用户注册
     */
    TokenDTO register(RegisterDTO registerDTO, HttpServletRequest request);

    /**
     * 用户登录
     */
    TokenDTO login(LoginDTO loginDTO, HttpServletRequest request);

    /**
     * 用户退出
     */
    void logout(Long userId, String deviceId);

    /**
     * 刷新Token
     */
    TokenDTO refreshToken(String refreshToken);
}
```

- [ ] **Step 2: 创建 Service 实现**

```java
package com.naon.grid.modules.app.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import com.naon.grid.config.properties.RsaProperties;
import com.naon.grid.exception.BadRequestException;
import com.naon.grid.modules.app.domain.GridUser;
import com.naon.grid.modules.app.enums.AppErrorCode;
import com.naon.grid.modules.app.enums.AppUserStatus;
import com.naon.grid.modules.app.enums.Gender;
import com.naon.grid.modules.app.repository.GridUserRepository;
import com.naon.grid.modules.app.security.DeviceManager;
import com.naon.grid.modules.app.service.AppAuthService;
import com.naon.grid.modules.app.service.dto.*;
import com.naon.grid.modules.security.security.TokenProvider;
import com.naon.grid.utils.RsaUtils;
import com.naon.grid.utils.RedisUtils;
import com.naon.grid.utils.StringUtils;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletRequest;
import java.util.Date;
import java.util.concurrent.TimeUnit;

/**
 * APP认证服务实现
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AppAuthServiceImpl implements AppAuthService {

    private final GridUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenProvider tokenProvider;
    private final DeviceManager deviceManager;
    private final RedisUtils redisUtils;

    @Value("${app.auth.token-validity-in-seconds:604800}")
    private long tokenValidityInSeconds;

    @Value("${app.auth.refresh-token-validity-in-seconds:2592000}")
    private long refreshTokenValidityInSeconds;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public TokenDTO register(RegisterDTO registerDTO, HttpServletRequest request) {
        // 检查用户名是否已存在
        if (userRepository.existsByUsername(registerDTO.getUsername())) {
            throw new BadRequestException(AppErrorCode.USERNAME_EXISTS.getMessage());
        }

        // 检查手机号是否已注册
        if (userRepository.existsByPhone(registerDTO.getPhone())) {
            throw new BadRequestException(AppErrorCode.PHONE_EXISTS.getMessage());
        }

        // 解密密码
        String decryptedPassword;
        try {
            decryptedPassword = RsaUtils.decryptByPrivateKey(RsaProperties.privateKey, registerDTO.getPassword());
        } catch (Exception e) {
            throw new BadRequestException("密码解密失败");
        }

        // 创建用户
        GridUser user = new GridUser();
        user.setUsername(registerDTO.getUsername());
        user.setPassword(passwordEncoder.encode(decryptedPassword));
        user.setPhone(registerDTO.getPhone());
        user.setEmail(registerDTO.getEmail());
        user.setNickname(StrUtil.isNotBlank(registerDTO.getNickname()) ? registerDTO.getNickname() : registerDTO.getUsername());
        user.setGender(Gender.UNKNOWN.getCode());
        user.setStatus(AppUserStatus.ENABLED.getCode());
        user.setRegisterIp(StringUtils.getIp(request));

        userRepository.save(user);

        // 生成Token
        return generateToken(user, registerDTO.getDeviceId());
    }

    @Override
    public TokenDTO login(LoginDTO loginDTO, HttpServletRequest request) {
        // 查询用户
        GridUser user = userRepository.findByPhone(loginDTO.getPhone())
                .orElseThrow(() -> new BadRequestException(AppErrorCode.INVALID_CREDENTIALS.getMessage()));

        // 检查用户状态
        if (AppUserStatus.DISABLED.getCode().equals(user.getStatus())) {
            throw new BadRequestException(AppErrorCode.USER_DISABLED.getMessage());
        }

        // 解密密码
        String decryptedPassword;
        try {
            decryptedPassword = RsaUtils.decryptByPrivateKey(RsaProperties.privateKey, loginDTO.getPassword());
        } catch (Exception e) {
            throw new BadRequestException("密码解密失败");
        }

        // 验证密码
        if (!passwordEncoder.matches(decryptedPassword, user.getPassword())) {
            throw new BadRequestException(AppErrorCode.INVALID_CREDENTIALS.getMessage());
        }

        // 更新登录信息
        user.setLastLoginTime(new Date());
        user.setLastLoginIp(StringUtils.getIp(request));
        userRepository.save(user);

        // 生成Token
        return generateToken(user, loginDTO.getDeviceId());
    }

    @Override
    public void logout(Long userId, String deviceId) {
        deviceManager.removeDevice(userId, deviceId);
    }

    @Override
    public TokenDTO refreshToken(String refreshToken) {
        // 解析refresh token
        Claims claims;
        try {
            claims = tokenProvider.getClaims(refreshToken);
        } catch (Exception e) {
            throw new BadRequestException(AppErrorCode.TOKEN_INVALID.getMessage());
        }

        // 检查是否过期
        if (claims.getExpiration().before(new Date())) {
            throw new BadRequestException(AppErrorCode.TOKEN_EXPIRED.getMessage());
        }

        Long userId = claims.get(AppTokenProvider.AUTHORITIES_UID_KEY, Long.class);
        String deviceId = claims.get(AppTokenProvider.DEVICE_ID_KEY, String.class);

        // 验证用户是否存在
        GridUser user = userRepository.findById(userId)
                .orElseThrow(() -> new BadRequestException("用户不存在"));

        // 检查用户状态
        if (AppUserStatus.DISABLED.getCode().equals(user.getStatus())) {
            throw new BadRequestException(AppErrorCode.USER_DISABLED.getMessage());
        }

        // 生成新Token
        return generateToken(user, deviceId);
    }

    /**
     * 生成Token
     */
    private TokenDTO generateToken(GridUser user, String deviceId) {
        // 生成Token
        String token = AppTokenProvider.createToken(user.getId(), user.getUsername(), deviceId);
        String refreshToken = AppTokenProvider.createRefreshToken(user.getId(), user.getUsername(), deviceId);

        // 注册设备
        deviceManager.registerDevice(user.getId(), deviceId, token);

        // 构建返回
        TokenDTO tokenDTO = new TokenDTO();
        tokenDTO.setToken(AppTokenProvider.TOKEN_PREFIX + token);
        tokenDTO.setRefreshToken(refreshToken);
        tokenDTO.setExpiresIn(tokenValidityInSeconds);
        tokenDTO.setUser(convertToDTO(user));

        return tokenDTO;
    }

    /**
     * 转换为DTO
     */
    private AppUserDTO convertToDTO(GridUser user) {
        AppUserDTO dto = new AppUserDTO();
        BeanUtil.copyProperties(user, dto);

        // 手机号脱敏
        if (StrUtil.isNotBlank(user.getPhone())) {
            dto.setPhone(user.getPhone().replaceAll("(\\d{3})\\d{4}(\\d{4})", "$1****$2"));
        }

        return dto;
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/service/
git commit -m "feat(grid-app): add AppAuthService with register and login logic"
```

---

#### Task 9: 创建 AppTokenProvider Token 生成器

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/security/AppTokenProvider.java`

**Description:**
创建 APP 专用的 Token 生成器，支持 Access Token 和 Refresh Token。

- [ ] **Step 1: 创建 AppTokenProvider**

```java
package com.naon.grid.modules.app.security;

import cn.hutool.core.date.DateField;
import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.IdUtil;
import com.naon.grid.modules.security.config.SecurityProperties;
import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * APP Token 提供者
 * 负责生成和验证 Access Token 和 Refresh Token
 */
@Slf4j
@Component
public class AppTokenProvider implements InitializingBean {

    public static final String TOKEN_PREFIX = "Bearer ";
    public static final String AUTHORITIES_UID_KEY = "uid";
    public static final String DEVICE_ID_KEY = "did";
    public static final String TOKEN_TYPE_KEY = "type";
    public static final String TOKEN_TYPE_ACCESS = "access";
    public static final String TOKEN_TYPE_REFRESH = "refresh";

    private Key signingKey;
    private JwtParser jwtParser;

    private final SecurityProperties properties;

    public AppTokenProvider(SecurityProperties properties) {
        this.properties = properties;
    }

    @Override
    public void afterPropertiesSet() {
        byte[] keyBytes = Decoders.BASE64.decode(properties.getBase64Secret());
        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
        this.jwtParser = Jwts.parserBuilder()
                .setSigningKey(signingKey)
                .build();
    }

    /**
     * 创建 Access Token
     */
    public static String createToken(Long userId, String username, String deviceId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put(AUTHORITIES_UID_KEY, userId);
        claims.put(DEVICE_ID_KEY, deviceId);
        claims.put(TOKEN_TYPE_KEY, TOKEN_TYPE_ACCESS);
        claims.put("jti", IdUtil.simpleUUID());

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(username)
                .setIssuedAt(new Date())
                .signWith(signingKey, SignatureAlgorithm.HS512)
                .compact();
    }

    /**
     * 创建 Refresh Token
     */
    public static String createRefreshToken(Long userId, String username, String deviceId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put(AUTHORITIES_UID_KEY, userId);
        claims.put(DEVICE_ID_KEY, deviceId);
        claims.put(TOKEN_TYPE_KEY, TOKEN_TYPE_REFRESH);
        claims.put("jti", IdUtil.simpleUUID());

        Date now = new Date();
        Date validity = DateUtil.offset(now, DateField.SECOND, (int) refreshTokenValidityInSeconds);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(username)
                .setIssuedAt(now)
                .setExpiration(validity)
                .signWith(signingKey, SignatureAlgorithm.HS512)
                .compact();
    }

    /**
     * 解析 Token
     */
    public Claims getClaims(String token) {
        return jwtParser.parseClaimsJws(token).getBody();
    }

    /**
     * 验证 Access Token 是否有效
     */
    public boolean isAccessTokenValid(String token) {
        try {
            Claims claims = getClaims(token);
            return TOKEN_TYPE_ACCESS.equals(claims.get(TOKEN_TYPE_KEY));
        } catch (Exception e) {
            log.error("Token 验证失败: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 从 Token 中提取用户ID
     */
    public Long getUserIdFromToken(String token) {
        Claims claims = getClaims(token);
        return claims.get(AUTHORITIES_UID_KEY, Long.class);
    }

    /**
     * 从 Token 中提取设备ID
     */
    public String getDeviceIdFromToken(String token) {
        Claims claims = getClaims(token);
        return claims.get(DEVICE_ID_KEY, String.class);
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/security/AppTokenProvider.java
git commit -m "feat(grid-app): add AppTokenProvider for JWT generation"
```

---

#### Task 10: 创建 AppAuthController REST 接口

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/rest/AppAuthController.java`

**Description:**
创建认证相关的 REST 接口，包括注册、登录、退出等。

- [ ] **Step 1: 创建 Controller**

```java
package com.naon.grid.modules.app.rest;

import com.naon.grid.annotation.Log;
import com.naon.grid.annotation.rest.AnonymousPostMapping;
import com.naon.grid.modules.app.service.AppAuthService;
import com.naon.grid.modules.app.service.dto.LoginDTO;
import com.naon.grid.modules.app.service.dto.RegisterDTO;
import com.naon.grid.modules.app.service.dto.TokenDTO;
import com.naon.grid.utils.SecurityUtils;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;

/**
 * APP认证接口
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/app/auth")
@Api(tags = "APP：认证接口")
public class AppAuthController {

    private final AppAuthService appAuthService;

    @Log("APP用户注册")
    @ApiOperation("用户注册")
    @AnonymousPostMapping("/register")
    public ResponseEntity<TokenDTO> register(@Validated @RequestBody RegisterDTO registerDTO,
                                              HttpServletRequest request) {
        TokenDTO tokenDTO = appAuthService.register(registerDTO, request);
        return ResponseEntity.ok(tokenDTO);
    }

    @Log("APP用户登录")
    @ApiOperation("用户登录")
    @AnonymousPostMapping("/login")
    public ResponseEntity<TokenDTO> login(@Validated @RequestBody LoginDTO loginDTO,
                                           HttpServletRequest request) {
        TokenDTO tokenDTO = appAuthService.login(loginDTO, request);
        return ResponseEntity.ok(tokenDTO);
    }

    @Log("APP用户退出")
    @ApiOperation("退出登录")
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestParam String deviceId) {
        Long userId = SecurityUtils.getCurrentUserId();
        appAuthService.logout(userId, deviceId);
        return ResponseEntity.ok().build();
    }

    @ApiOperation("刷新Token")
    @PostMapping("/refresh")
    public ResponseEntity<TokenDTO> refreshToken(@RequestParam String refreshToken) {
        TokenDTO tokenDTO = appAuthService.refreshToken(refreshToken);
        return ResponseEntity.ok(tokenDTO);
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/rest/AppAuthController.java
git commit -m "feat(grid-app): add AppAuthController with register and login endpoints"
```

---

### Phase 5: 安全配置 (Security)

#### Task 11: 创建 AppSecurityConfig 安全配置

**Files:**
- Create: `backend/grid-app/src/main/java/com/naon/grid/modules/app/config/AppSecurityConfig.java`

**Description:**
配置 APP 接口的安全策略，允许匿名访问注册登录接口。

- [ ] **Step 1: 创建 SecurityConfig**

```java
package com.naon.grid.modules.app.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.config.http.SessionCreationPolicy;

/**
 * APP模块安全配置
 * 优先级高于主配置，处理 /api/app/** 路径
 */
@Configuration
@EnableWebSecurity
@Order(101) // 确保在系统安全配置之前
@RequiredArgsConstructor
public class AppSecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            // 只处理 /api/app 路径
            .requestMatchers()
            .antMatchers("/api/app/**")
            .and()
            // 禁用 CSRF（APP使用Token，不需要CSRF）
            .csrf().disable()
            // 无状态会话
            .sessionManagement()
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            // 配置请求权限
            .authorizeRequests()
            // 允许匿名访问的接口
            .antMatchers("/api/app/auth/register").anonymous()
            .antMatchers("/api/app/auth/login").anonymous()
            .antMatchers("/api/app/auth/refresh").anonymous()
            // 其他接口需要认证
            .anyRequest().authenticated();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/grid-app/src/main/java/com/naon/grid/modules/app/config/AppSecurityConfig.java
git commit -m "feat(grid-app): add AppSecurityConfig for API security"
```

---

### Phase 6: 客户端实现 (Client Implementation)

#### Task 12: 创建 Dart API 常量配置

**Files:**
- Create: `app/lib/core/constants/api_constants.dart`

**Description:**
定义 API 端点常量。

- [ ] **Step 1: 创建 API 常量**

```dart
// app/lib/core/constants/api_constants.dart

class ApiConstants {
  // 基础配置
  static const String baseUrl = 'http://localhost:8080'; // 开发环境
  // static const String baseUrl = 'https://api.yourdomain.com'; // 生产环境

  static const String apiPrefix = '/api';
  static const String appApiPrefix = '$apiPrefix/app';

  // 认证相关
  static const String register = '$appApiPrefix/auth/register';
  static const String login = '$appApiPrefix/auth/login';
  static const String logout = '$appApiPrefix/auth/logout';
  static const String refreshToken = '$appApiPrefix/auth/refresh';

  // 用户相关
  static const String userProfile = '$appApiPrefix/user/profile';
  static const String updateProfile = '$appApiPrefix/user/profile';
  static const String updatePassword = '$appApiPrefix/user/password';

  // 超时配置
  static const int connectTimeout = 15000; // 15秒
  static const int receiveTimeout = 15000; // 15秒
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/core/constants/api_constants.dart
git commit -m "feat(app): add API constants configuration"
```

---

#### Task 13: 创建 TokenManager

**Files:**
- Create: `app/lib/core/services/token_manager.dart`

**Description:**
管理 Token 的存储、获取和刷新。

- [ ] **Step 1: 创建 TokenManager**

```dart
// app/lib/core/services/token_manager.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'token_expires_at';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // 单例模式
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  /// 保存 Token
  Future<void> saveToken({
    required String token,
    required String refreshToken,
    required int expiresIn,
    required String userId,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    await Future.wait([
      _secureStorage.write(key: _tokenKey, value: token),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(key: _userIdKey, value: userId),
      _saveExpiresAt(expiresAt.millisecondsSinceEpoch),
    ]);
  }

  /// 获取 Token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// 获取用户ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// 检查 Token 是否过期
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (expiresAt == null) return true;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    return DateTime.now().isAfter(expiryDate);
  }

  /// 检查是否需要刷新 Token（距离过期还有1天时）
  Future<bool> shouldRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (expiresAt == null) return false;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    final oneDayBeforeExpiry = expiryDate.subtract(const Duration(days: 1));

    return DateTime.now().isAfter(oneDayBeforeExpiry);
  }

  /// 清除所有 Token
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userIdKey),
      _deleteExpiresAt(),
    ]);
  }

  /// 保存过期时间
  Future<void> _saveExpiresAt(int millisecondsSinceEpoch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expiresAtKey, millisecondsSinceEpoch);
  }

  /// 删除过期时间
  Future<void> _deleteExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiresAtKey);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/core/services/token_manager.dart
git commit -m "feat(app): add TokenManager for secure token storage"
```

---

### Phase 7: 集成与测试 (Integration & Testing)

#### Task 14: 集成测试验证

**Files:**
- Test: `backend/grid-app/src/test/java/com/naon/grid/modules/app/rest/AppAuthControllerTest.java`

**Description:**
编写集成测试，验证注册登录流程。

- [ ] **Step 1: 创建测试类**

```java
package com.naon.grid.modules.app.rest;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.naon.grid.modules.app.service.dto.LoginDTO;
import com.naon.grid.modules.app.service.dto.RegisterDTO;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class AppAuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testRegister() throws Exception {
        // 生成唯一的用户名和手机号
        String timestamp = String.valueOf(System.currentTimeMillis());
        String username = "test" + timestamp.substring(7);
        String phone = "138" + timestamp.substring(5);

        RegisterDTO registerDTO = new RegisterDTO();
        registerDTO.setUsername(username);
        registerDTO.setPassword("encrypted_password"); // 需要RSA加密
        registerDTO.setPhone(phone);
        registerDTO.setDeviceId("test-device-001");

        mockMvc.perform(post("/api/app/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.token").exists())
                .andExpect(jsonPath("$.data.user.username").value(username));
    }

    @Test
    void testLogin() throws Exception {
        LoginDTO loginDTO = new LoginDTO();
        loginDTO.setPhone("13800138000");
        loginDTO.setPassword("encrypted_password");
        loginDTO.setDeviceId("test-device-001");

        mockMvc.perform(post("/api/app/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
    }
}
```

- [ ] **Step 2: Run 测试**

```bash
cd backend && mvn test -pl grid-app
```

Expected: 测试通过

- [ ] **Step 3: Commit**

```bash
git add backend/grid-app/src/test/
git commit -m "test(grid-app): add integration tests for auth endpoints"
```

---

## 总结

完整的实现计划已创建，包含以下主要任务：

### Phase 1: 基础架构
- Task 1: Maven 配置
- Task 2: 数据库表创建

### Phase 2: 数据层
- Task 3: GridUser 实体类
- Task 4: GridUserRepository

### Phase 3: DTOs
- Task 5-6: 各种 DTO 类

### Phase 4: 业务层
- Task 7: DeviceManager
- Task 8: AppAuthService
- Task 9: AppTokenProvider

### Phase 5: 接口层
- Task 10: AppAuthController

### Phase 6: 安全配置
- Task 11: AppSecurityConfig

### Phase 7: 客户端
- Task 12: API 常量
- Task 13: TokenManager

### Phase 8: 测试
- Task 14: 集成测试

---

**计划文档路径**: `docs/superpowers/plans/2025-04-05-app-auth-implementation.md`

**设计文档路径**: `docs/superpowers/specs/2025-04-05-app-auth-design.md`

---

计划已完成。接下来可以选择：

1. **Subagent-Driven (推荐)** - 使用 superpowers:subagent-driven-development，为每个 Task 派遣独立的子代理执行
2. **Inline Execution** - 在当前会话使用 superpowers:executing-plans 批量执行

哪种方式更适合你的需求？