package com.naon.grid.modules.app.service;

import com.naon.grid.modules.app.service.dto.AppUserDTO;
import com.naon.grid.modules.app.service.dto.LoginDTO;
import com.naon.grid.modules.app.service.dto.RegisterDTO;
import com.naon.grid.modules.app.service.dto.TokenDTO;
import com.naon.grid.modules.app.service.dto.UpdateUserDTO;

import javax.servlet.http.HttpServletRequest;

public interface AppAuthService {
    TokenDTO register(RegisterDTO registerDTO, HttpServletRequest request);
    TokenDTO login(LoginDTO loginDTO, HttpServletRequest request);
    void logout(Long userId, String deviceId);
    TokenDTO refreshToken(String refreshToken);
    AppUserDTO updateUser(Long userId, UpdateUserDTO updateUserDTO);
}
