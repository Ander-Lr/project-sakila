package com.example.demo.security;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationEntryPoint.class);

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException, ServletException {
        
        String jwtError = (String) request.getAttribute("jwt_error");
        
        String errorCode = "ACCESO_SIN_AUTENTICACION";
        String message = "No se proporcionó un token de autenticación válido.";
        
        if (jwtError != null) {
            if (jwtError.equals("Token revocado")) {
                errorCode = "TOKEN_REVOCADO";
                message = "El token ha sido revocado.";
            } else if (jwtError.equals("Token vencido")) {
                errorCode = "TOKEN_VENCIDO";
                message = "El token ha expirado.";
            } else {
                errorCode = "TOKEN_INVALIDO";
                message = "El token es inválido o su formato es incorrecto.";
            }
        }
        
        String timestampForLog = ZonedDateTime.now(ZoneId.of("UTC")).format(DateTimeFormatter.ISO_INSTANT);
        System.out.printf("%s WARN %s user=null %s%n", timestampForLog, errorCode, request.getRequestURI());
        
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String timestamp = ZonedDateTime.now(ZoneId.of("UTC")).format(DateTimeFormatter.ISO_INSTANT);
        String json = String.format("{\"timestamp\": \"%s\", \"status\": 401, \"error\": \"%s\", \"message\": \"%s\", \"path\": \"%s\"}",
                timestamp, errorCode, message, request.getRequestURI());
        
        response.getWriter().write(json);
    }
}
