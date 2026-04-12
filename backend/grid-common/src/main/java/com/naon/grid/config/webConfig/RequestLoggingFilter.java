package com.naon.grid.config.webConfig;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Enumeration;

/**
 * 请求日志过滤器 - 打印所有请求详情
 */
@Slf4j
@Component
public class RequestLoggingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        long startTime = System.currentTimeMillis();

        // 打印请求信息
        String requestUri = request.getRequestURI();
        String method = request.getMethod();
        String remoteAddr = getClientIpAddress(request);

        log.info("========== 收到请求 ==========");
        log.info("请求方式: {} {}", method, requestUri);
        log.info("客户端IP: {}", remoteAddr);
        log.info("RemoteAddr: {}", request.getRemoteAddr());
        log.info("RemoteHost: {}", request.getRemoteHost());
        log.info("RemotePort: {}", request.getRemotePort());

        // 打印请求头
        Enumeration<String> headerNames = request.getHeaderNames();
        StringBuilder headers = new StringBuilder();
        while (headerNames.hasMoreElements()) {
            String headerName = headerNames.nextElement();
            String headerValue = request.getHeader(headerName);
            headers.append(headerName).append("=").append(headerValue).append(", ");
        }
        log.info("请求头: {}", headers);

        // 继续处理请求
        try {
            filterChain.doFilter(request, response);
        } finally {
            long duration = System.currentTimeMillis() - startTime;
            log.info("响应状态: {}, 耗时: {}ms", response.getStatus(), duration);
            log.info("========== 请求处理完成 ==========");
        }
    }

    /**
     * 获取客户端真实IP地址
     */
    private String getClientIpAddress(HttpServletRequest request) {
        String[] headers = {
            "X-Forwarded-For",
            "X-Real-IP",
            "Proxy-Client-IP",
            "WL-Proxy-Client-IP",
            "HTTP_X_FORWARDED_FOR",
            "HTTP_X_FORWARDED",
            "HTTP_X_CLUSTER_CLIENT_IP",
            "HTTP_CLIENT_IP",
            "HTTP_FORWARDED_FOR",
            "HTTP_FORWARDED"
        };

        for (String header : headers) {
            String ip = request.getHeader(header);
            if (ip != null && !ip.isEmpty() && !"unknown".equalsIgnoreCase(ip)) {
                // 多个代理时，第一个IP是客户端真实IP
                int index = ip.indexOf(',');
                if (index != -1) {
                    return ip.substring(0, index).trim();
                }
                return ip;
            }
        }
        return request.getRemoteAddr();
    }
}
