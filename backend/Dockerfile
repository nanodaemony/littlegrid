FROM maven:3.9-amazoncorretto-8 AS builder

WORKDIR /app

# 设置 Maven 使用阿里云镜像
COPY settings.xml /usr/share/maven/ref/settings.xml

# 复制所有文件
COPY pom.xml .
COPY grid-common grid-common
COPY grid-tools grid-tools
COPY grid-app grid-app
COPY grid-admin grid-admin

# 下载依赖 - 使用缓存挂载持久化 Maven 本地仓库
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B

# 构建项目 - 使用缓存挂载
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests

# 运行时镜像
FROM amazoncorretto:8-alpine

WORKDIR /app

# 安装时区
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata

# 复制 JAR 文件 - 使用 grid-app 作为主应用（exec classifier）
COPY --from=builder /app/grid-app/target/grid-app-2.7-exec.jar app.jar

# 创建日志目录
RUN mkdir -p /app/logs

EXPOSE 8000

# 设置 JVM 参数
ENV JAVA_OPTS="-Xms512m -Xmx1024m"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
