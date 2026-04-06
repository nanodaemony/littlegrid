# APP 用户注册登录系统设计文档

**版本**: v1.0  
**日期**: 2025-04-05  
**状态**: 已确认，待实施

---

## 1. 概述

### 1.1 背景
LittleGrid APP 当前已有登录注册界面，但后端未实现对应的注册登录接口，导致用户点击注册按钮后一直转圈。本设计旨在实现完整的 APP 用户注册登录系统。

### 1.2 目标
- 实现 APP 用户注册、登录、登出功能
- 支持多端登录（最多 3 台设备）
- 预留微信登录、邮箱登录扩展能力
- 与现有 Admin 系统分离，独立管理

### 1.3 非目标
- 本设计不包含短信验证码功能（后续迭代）
- 不包含微信登录实现（后续迭代）

---

## 2. 架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    APP (Flutter)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │ 登录/注册页面 │  │  Auth API   │  │  SecureStorage  │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼ RSA + HTTPS
┌─────────────────────────────────────────────────────────┐
│                   Backend (Spring Boot)                  │
│  ┌──────────────────────────────────────────────────┐   │
│  │  grid-app 模块 (新)                               │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │   │
│  │  │AppAuthController│ │AppUserService│ │GridUserRepository│  │   │
│  │  └──────────┘ └──────────┘ └──────────────────┘  │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  grid-system 模块 (复用)                          │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │   │
│  │  │TokenProvider│ │RedisUtils   │ │RSAUtils        │  │   │
│  │  └──────────┘ └──────────┘ └──────────────────┘  │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              MySQL (grid_user 表)    Redis (Token)       │
└─────────────────────────────────────────────────────────┘
```

### 2.2 模块职责

| 模块 | 职责 | 复用/新建 |
|------|------|----------|
| grid-app | APP用户认证、用户管理 | **新建** |
| grid-system | Token生成、Redis操作、RSA工具 | 复用 |
| grid-common | 基础工具类、异常处理 | 复用 |

---

## 3. 数据模型

### 3.1 数据库表

**表名: `grid_user`**

| 字段 | 类型 | 可空 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | 否 | AUTO_INCREMENT | 主键 |
| username | VARCHAR(50) | 否 | - | 用户名，唯一索引 |
| password | VARCHAR(100) | 否 | - | BCrypt加密后的密码 |
| phone | VARCHAR(20) | 否 | - | 手机号，唯一索引 |
| email | VARCHAR(100) | 是 | NULL | 邮箱 |
| nickname | VARCHAR(50) | 是 | NULL | 昵称 |
| avatar | VARCHAR(500) | 是 | NULL | 头像URL |
| gender | TINYINT | 是 | 0 | 性别：0-未知 1-男 2-女 |
| status | TINYINT | 否 | 1 | 状态：0-禁用 1-正常 |
| register_ip | VARCHAR(50) | 是 | NULL | 注册IP |
| last_login_time | DATETIME | 是 | NULL | 最后登录时间 |
| last_login_ip | VARCHAR(50) | 是 | NULL | 最后登录IP |
| wx_openid | VARCHAR(50) | 是 | NULL | 微信openid（预留） |
| wx_unionid | VARCHAR(50) | 是 | NULL | 微信unionid（预留） |
| created_at | DATETIME | 否 | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | 否 | CURRENT_TIMESTAMP | 更新时间 |

**索引：**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_username` (`username`)
- UNIQUE KEY `uk_phone` (`phone`)
- KEY `idx_wx_openid` (`wx_openid`)

### 3.2 Redis Key 设计

| Key 模式 | 类型 | TTL | 说明 |
|----------|------|-----|------|
| `app:online:{userId}:{deviceId}` | String | 7天 | 用户在线状态，value为token |
| `app:token:{userId}:{deviceId}` | Hash | 7天 | Token详情：token、refreshToken、deviceInfo |
| `app:devices:{userId}` | Set | 永久 | 用户设备列表，member为deviceId |
| `app:login:fail:{phone}` | String | 5分钟 | 登录失败次数限制 |

---

## 4. API 接口设计

### 4.1 接口概览

| 端点 | 方法 | 描述 | 鉴权 |
|------|------|------|------|
| `/api/app/auth/register` | POST | 用户注册 | 否 |
| `/api/app/auth/login` | POST | 用户登录 | 否 |
| `/api/app/auth/logout` | POST | 退出登录 | 是 |
| `/api/app/auth/refresh` | POST | 刷新Token | 是（Refresh Token） |
| `/api/app/user/profile` | GET | 获取用户信息 | 是 |
| `/api/app/user/profile` | PUT | 更新用户信息 | 是 |
| `/api/app/user/password` | PUT | 修改密码 | 是 |

### 4.2 接口详情

#### 4.2.1 用户注册

```http
POST /api/app/auth/register
Content-Type: application/json

{
  "username": "zhangsan",      // 必填，3-20位字母数字下划线
  "password": "Base64(RSA(明文密码))",  // 必填，前端RSA加密
  "phone": "13800138000",      // 必填，11位手机号
  "email": "xxx@example.com",  // 可选
  "nickname": "张三",          // 可选，默认使用username
  "deviceId": "uuid-string",   // 必填，设备唯一标识
  "deviceInfo": {              // 可选，设备信息
    "os": "iOS",
    "version": "17.0",
    "model": "iPhone15,2"
  }
}

Response 200:
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "token": "Bearer eyJhbGciOiJIUzUxMiJ9...",
    "refreshToken": "...",
    "expiresIn": 604800,
    "user": {
      "id": 1,
      "username": "zhangsan",
      "nickname": "张三",
      "phone": "138****8000",
      "avatar": null
    }
  }
}

Error Response:
{
  "code": 400,
  "message": "用户名已存在"
}
```

#### 4.2.2 用户登录

```http
POST /api/app/auth/login
Content-Type: application/json

{
  "phone": "13800138000",      // 必填，11位手机号
  "password": "Base64(RSA(明文密码))",  // 必填，前端RSA加密
  "deviceId": "uuid-string",   // 必填，设备唯一标识
  "deviceInfo": {              // 可选
    "os": "iOS",
    "version": "17.0",
    "model": "iPhone15,2"
  }
}

Response 200:
同注册接口

Error Response:
{
  "code": 401,
  "message": "手机号或密码错误"
}
```

#### 4.2.3 退出登录

```http
POST /api/app/auth/logout
Authorization: Bearer {token}

Response 200:
{
  "code": 200,
  "message": "退出成功"
}
```

#### 4.2.4 刷新 Token

```http
POST /api/app/auth/refresh
Authorization: Bearer {refreshToken}

Response 200:
{
  "code": 200,
  "data": {
    "token": "Bearer eyJhbGciOiJIUzUxMiJ9...",
    "refreshToken": "...",
    "expiresIn": 604800
  }
}
```

#### 4.2.5 获取用户信息

```http
GET /api/app/user/profile
Authorization: Bearer {token}

Response 200:
{
  "code": 200,
  "data": {
    "id": 1,
    "username": "zhangsan",
    "nickname": "张三",
    "phone": "138****8000",
    "email": "xxx@example.com",
    "avatar": "https://...",
    "gender": 1,
    "createdAt": "2024-01-01T00:00:00"
  }
}
```

### 4.3 错误码定义

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（Token无效或过期） |
| 403 | 禁止访问 |
| 404 | 资源不存在 |
| 409 | 资源冲突（如用户名已存在） |
| 429 | 请求过于频繁 |
| 500 | 服务器内部错误 |

---

## 5. 后端模块结构

```
grid-app/
├── pom.xml
└── src/main/java/com/naon/grid/modules/app/
    ├── config/
    │   └── AppSecurityConfig.java          # APP安全配置
    ├── domain/
    │   └── GridUser.java                    # 用户实体
    ├── repository/
    │   └── GridUserRepository.java          # 数据访问
    ├── service/
    │   ├── dto/
    │   │   ├── RegisterDTO.java
    │   │   ├── LoginDTO.java
    │   │   ├── TokenDTO.java
    │   │   └── AppUserDTO.java
    │   ├── impl/
    │   │   └── AppAuthServiceImpl.java
    │   └── AppAuthService.java
    ├── rest/
    │   ├── AppAuthController.java           # 认证接口
    │   └── AppUserController.java           # 用户接口
    └── enums/
        ├── AppErrorCode.java
        └── AppUserStatus.java
```

---

## 6. 客户端实现要点

### 6.1 需要实现的 API 调用

```dart
// lib/core/services/api/app_auth_api.dart
class AppAuthApi {
  // 注册
  Future<AuthResult> register(RegisterRequest request);
  
  // 登录
  Future<AuthResult> login(LoginRequest request);
  
  // 退出
  Future<void> logout();
  
  // 刷新Token
  Future<TokenResult> refreshToken(String refreshToken);
  
  // 获取用户信息
  Future<UserInfo> getUserInfo();
}
```

### 6.2 Token 管理

```dart
// lib/core/services/token_manager.dart
class TokenManager {
  // 存储Token到SecureStorage
  Future<void> saveToken(String token, String refreshToken);
  
  // 获取Token
  Future<String?> getToken();
  
  // 清除Token（退出登录）
  Future<void> clearToken();
  
  // 自动刷新Token
  Future<String?> refreshIfNeeded();
}
```

### 6.3 需要修改的页面

| 页面路径 | 修改内容 |
|----------|----------|
| `pages/login/register_page.dart` | 调用注册API，处理注册成功跳转 |
| `pages/login/login_page.dart` | 调用登录API，处理登录成功跳转 |
| `pages/profile_page.dart` | 调用获取用户信息API，显示用户信息 |

---

## 7. 配置项

### 7.1 后端配置 (application.yml)

```yaml
# APP认证配置
app:
  auth:
    # Token有效期（秒），默认7天
    token-validity-in-seconds: 604800
    # 刷新Token有效期（秒），默认30天
    refresh-token-validity-in-seconds: 2592000
    # 最大设备数
    max-devices: 3
    # 自动续期阈值（毫秒），剩余1天时续期
    renew-threshold: 86400000
```

### 7.2 前端配置

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://api.littlegrid.com';
  static const String appApiPrefix = '/api/app';
  
  // 认证相关
  static const String register = '$appApiPrefix/auth/register';
  static const String login = '$appApiPrefix/auth/login';
  static const String logout = '$appApiPrefix/auth/logout';
  static const String refresh = '$appApiPrefix/auth/refresh';
  
  // 用户相关
  static const String profile = '$appApiPrefix/user/profile';
}
```

---

## 8. 测试要点

### 8.1 单元测试

- 密码加密解密测试
- Token生成与解析测试
- 设备数量限制逻辑测试

### 8.2 集成测试

- 完整注册流程
- 登录成功后Token返回
- 多设备登录踢人策略
- Token过期后自动刷新

### 8.3 安全测试

- 密码明文传输检查（应使用RSA加密）
- SQL注入测试
- 暴力登录限制测试

---

## 9. 附录

### 9.1 术语表

| 术语 | 说明 |
|------|------|
| APP用户 | 指使用LittleGrid APP的终端用户 |
| Admin用户 | 指使用管理后台的用户 |
| Device ID | 设备唯一标识，用于多设备管理 |
| Refresh Token | 用于刷新Access Token的长期凭证 |

### 9.2 参考文档

- [Spring Security官方文档](https://spring.io/projects/spring-security)
- [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
- [OAuth 2.0协议](https://oauth.net/2/)

### 9.3 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| v1.0 | 2025-04-05 | 初始版本 | Claude |

---

**文档结束**
