package com.naon.grid.admin.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
public class AdminTokenProvider implements InitializingBean {

    public static final String TOKEN_TYPE_KEY = "type";
    public static final String TOKEN_TYPE_ADMIN = "admin";

    private Key signingKey;
    private JwtParser jwtParser;

    @Value("${admin.auth.base64-secret:Y2Y3ZmI3MjdhN2ZmMjNhODViOTg1ZGE0NTBjMGM4NDA5NzYxMjdjOWMwYWRmZTBlZjlhNGY3ZTg4Y2U3YTE1ODVkZDU5Y2Y3OGYwZWE1NzUzNWQ2YjFjZDc0NGMxZWU2MmQ3MjY1NzJmNTE0MzI=}")
    private String base64Secret;

    @Value("${admin.auth.token-validity-in-seconds:86400}")
    private long tokenValidityInSeconds;

    @Override
    public void afterPropertiesSet() {
        byte[] keyBytes = Decoders.BASE64.decode(base64Secret);
        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
        this.jwtParser = Jwts.parserBuilder()
                .setSigningKey(signingKey)
                .build();
    }

    public String createToken(String username) {
        Map<String, Object> claims = new HashMap<>();
        claims.put(TOKEN_TYPE_KEY, TOKEN_TYPE_ADMIN);
        claims.put("username", username);

        Date now = new Date();
        Date expiration = new Date(now.getTime() + tokenValidityInSeconds * 1000);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(username)
                .setIssuedAt(now)
                .setExpiration(expiration)
                .signWith(signingKey, SignatureAlgorithm.HS512)
                .compact();
    }

    public Claims getClaims(String token) {
        return jwtParser.parseClaimsJws(token).getBody();
    }

    public String getUsernameFromToken(String token) {
        Claims claims = getClaims(token);
        return claims.get("username", String.class);
    }

    public boolean isTokenExpired(String token) {
        try {
            Claims claims = getClaims(token);
            Date expiration = claims.getExpiration();
            return expiration.before(new Date());
        } catch (ExpiredJwtException e) {
            return true;
        } catch (Exception e) {
            log.error("Token validation error", e);
            return true;
        }
    }

    public boolean validateToken(String token) {
        try {
            getClaims(token);
            return !isTokenExpired(token);
        } catch (ExpiredJwtException e) {
            log.warn("Token expired: {}", e.getMessage());
            return false;
        } catch (JwtException e) {
            log.warn("Invalid token: {}", e.getMessage());
            return false;
        }
    }
}
