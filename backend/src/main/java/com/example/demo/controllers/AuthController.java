package com.example.demo.controllers;

import com.example.demo.models.AppUser;
import com.example.demo.models.dto.AuthResponse;
import com.example.demo.models.dto.TokenRequest;
import com.example.demo.repositories.AppUserRepository;
import com.example.demo.services.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.example.demo.models.dto.LocalLoginRequest;
import com.example.demo.models.dto.LocalRegisterRequest;
import com.example.demo.models.dto.VerifyCodeRequest;
import com.example.demo.models.dto.ResendCodeRequest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.access.AccessDeniedException;
import com.example.demo.security.PendingVerificationException;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final AppUserRepository userRepository;

    @PostMapping("/google")
    public ResponseEntity<?> authenticateWithGoogle(@RequestBody TokenRequest tokenRequest) {
        try {
            AuthResponse response = authService.authenticateWithGoogle(tokenRequest.getIdToken());
            if (response.getToken() == null) {
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            }
            return ResponseEntity.ok(response);

        } catch (org.springframework.security.authentication.DisabledException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "DISABLED");
            error.put("message", "User account is disabled");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        } catch (PendingVerificationException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "PENDING_VERIFICATION");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        } catch (AccessDeniedException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "FORBIDDEN");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            // Manejar caso de carrera: dos peticiones simultáneas intentan crear el usuario.
            // Si falla por unique constraint, reintentamos la lectura.
            try {
                AuthResponse response = authService.authenticateWithGoogle(tokenRequest.getIdToken());
                if (response.getToken() == null) {
                    return ResponseEntity.status(HttpStatus.CREATED).body(response);
                }
                return ResponseEntity.ok(response);
            } catch (Exception ex) {
                Map<String, String> error = new HashMap<>();
                error.put("status", "CONFLICT");
                error.put("message", "Error procesando registro simultáneo");
                return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
            }
        } catch (BadCredentialsException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "UNAUTHORIZED");
            error.put("message", "Token de Google inválido");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "INTERNAL_SERVER_ERROR");
            error.put("message", "Error interno procesando token");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerLocal(@RequestBody LocalRegisterRequest request) {
        try {
            AuthResponse response = authService.registerLocal(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException | org.springframework.dao.DataIntegrityViolationException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "CONFLICT");
            error.put("message", "Este correo ya está registrado");
            return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "INTERNAL_SERVER_ERROR");
            error.put("message", "Error during registration");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> loginLocal(@RequestBody LocalLoginRequest request) {
        try {
            AuthResponse response = authService.loginLocal(request);
            return ResponseEntity.ok(response);
        } catch (BadCredentialsException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "UNAUTHORIZED");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        } catch (org.springframework.security.authentication.DisabledException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "DISABLED");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        } catch (PendingVerificationException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "PENDING_VERIFICATION");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        } catch (AccessDeniedException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "FORBIDDEN");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "UNAUTHORIZED");
            error.put("message", "Invalid credentials");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verifyCode(@RequestBody VerifyCodeRequest request) {
        try {
            AuthResponse response = authService.verifyCode(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "BAD_REQUEST");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "INTERNAL_SERVER_ERROR");
            error.put("message", "Error verifying code");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<?> resendCode(@RequestBody ResendCodeRequest request) {
        try {
            authService.resendCode(request);
            Map<String, String> response = new HashMap<>();
            response.put("status", "SUCCESS");
            response.put("message", "Código reenviado exitosamente");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "BAD_REQUEST");
            error.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "INTERNAL_SERVER_ERROR");
            error.put("message", "Error resending code");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(jakarta.servlet.http.HttpServletRequest request) {
        try {
            String token = getJwtFromRequest(request);
            if (token != null) {
                authService.logout(token);
            }
            Map<String, String> response = new HashMap<>();
            response.put("status", "SUCCESS");
            response.put("message", "Sesión cerrada exitosamente");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "INTERNAL_SERVER_ERROR");
            error.put("message", "Error cerrando sesión");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    private String getJwtFromRequest(jakarta.servlet.http.HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (org.springframework.util.StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
