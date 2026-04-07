package com.naon.grid.modules.app.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@RequiredArgsConstructor
public class AppSecurityConfig {

    @Bean
    @Order(1)  // 优先级高于主SecurityConfig
    public SecurityFilterChain appSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/api/app/**")
            .csrf().disable()
            .sessionManagement()
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeRequests()
            .antMatchers("/api/app/auth/register").permitAll()
            .antMatchers("/api/app/auth/login").permitAll()
            .anyRequest().authenticated();

        return http.build();
    }
}