package com.naon.grid.admin.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
@Order(1)
public class AdminSecurityConfig {

    @Bean
    public SecurityFilterChain adminFilterChain(HttpSecurity httpSecurity) throws Exception {
        return httpSecurity
                .antMatcher("/api/admin/**")
                .csrf().disable()
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                .authorizeRequests()
                .antMatchers("/api/admin/login").permitAll()
                .antMatchers("/api/admin/**").authenticated()
                .and().build();
    }
}
