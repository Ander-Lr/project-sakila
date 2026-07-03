package com.example.demo.services;

import com.example.demo.models.AppUser;
import com.example.demo.models.dto.AuthResponse;
import com.example.demo.repositories.AppUserRepository;
import com.example.demo.repositories.CustomerRepository;
import com.example.demo.repositories.StaffRepository;
import com.example.demo.repositories.StoreRepository;
import com.example.demo.repositories.AddressRepository;
import com.example.demo.models.Customer;
import com.example.demo.models.Staff;
import com.example.demo.models.Store;
import com.example.demo.models.Address;
import com.example.demo.security.GoogleTokenVerifier;
import com.example.demo.security.JwtTokenProvider;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import lombok.RequiredArgsConstructor;
import com.example.demo.models.dto.LocalLoginRequest;
import com.example.demo.models.dto.LocalRegisterRequest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.DisabledException;
import com.example.demo.security.PendingVerificationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);

    private final GoogleTokenVerifier googleTokenVerifier;
    private final AppUserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final com.example.demo.repositories.RevokedTokenRepository revokedTokenRepository;
    private final CustomerRepository customerRepository;
    private final StaffRepository staffRepository;
    private final StoreRepository storeRepository;
    private final AddressRepository addressRepository;
    private final AuditLogService auditLogService;

    private void assignRoleAndCreateProfile(AppUser user) {
        boolean isAdmin = user.getEmail() != null && user.getEmail().endsWith("@espe.edu.ec");
        
        user.setRole(isAdmin ? AppUser.Role.ADMIN : AppUser.Role.CUSTOMER);
        
        Store defaultStore = storeRepository.findById((short) 1)
                .orElseThrow(() -> new IllegalStateException("Store por defecto no encontrada"));
        Address defaultAddress = addressRepository.findById((short) 1)
                .orElseThrow(() -> new IllegalStateException("Address por defecto no encontrada"));
        
        String[] nameParts = user.getFullName().split(" ", 2);
        String firstName = nameParts[0];
        String lastName = nameParts.length > 1 ? nameParts[1] : "";
        
        if (isAdmin) {
            Staff staff = new Staff();
            staff.setFirstName(firstName);
            staff.setLastName(lastName);
            staff.setEmail(user.getEmail());
            String emailPrefix = user.getEmail().split("@")[0];
            staff.setUsername(emailPrefix.substring(0, Math.min(16, emailPrefix.length())));
            staff.setPassword("oauth2_dummy_password");
            staff.setStore(defaultStore);
            staff.setAddress(defaultAddress);
            staff = staffRepository.save(staff);
            user.setStaffId(staff.getStaffId());
        } else {
            Customer customer = new Customer();
            customer.setFirstName(firstName);
            customer.setLastName(lastName);
            customer.setEmail(user.getEmail());
            customer.setStore(defaultStore);
            customer.setAddress(defaultAddress);
            customer = customerRepository.save(customer);
            user.setCustomerId(customer.getCustomerId());
        }
    }

    private String generateVerificationCode() {
        Random random = new Random();
        int code = 100000 + random.nextInt(900000); // 6 dígitos
        return String.valueOf(code);
    }

    @Transactional
    public AuthResponse authenticateWithGoogle(String idTokenString) {
        try {
            GoogleIdToken.Payload payload = googleTokenVerifier.verify(idTokenString);

            String googleId = payload.getSubject();
            String email = payload.getEmail();
            String name = (String) payload.get("name");

            AppUser user = userRepository.findByGoogleId(googleId)
                    .orElseGet(() -> userRepository.findByEmail(email).orElse(null));

            if (user == null) {
                user = new AppUser();
                user.setGoogleId(googleId);
                user.setEmail(email);
                user.setFullName(name != null ? name : email);
                user.setAuthProvider(AppUser.AuthProvider.GOOGLE);
                user.setStatus(AppUser.Status.ACTIVE);
                
                assignRoleAndCreateProfile(user);
                
                user = userRepository.save(user);
            } else {
                if (!user.getActive()) {
                    auditLogService.logEvent("WARN", "LOGIN_FAILED", user.getId(), "/api/auth/google", "FAILURE", "Usuario desactivado");
                    throw new DisabledException("El usuario está desactivado");
                }
                
                if (user.getAuthProvider() == AppUser.AuthProvider.LOCAL && user.getStatus() == AppUser.Status.PENDING) {
                    user.setStatus(AppUser.Status.ACTIVE);
                    user.setVerificationCode(null);
                    user.setVerificationCodeExpiresAt(null);
                    user.setGoogleId(googleId);
                }

                if (user.getStatus() == AppUser.Status.PENDING) {
                    auditLogService.logEvent("WARN", "LOGIN_FAILED", user.getId(), "/api/auth/google", "FAILURE", "Usuario pendiente de verificación");
                    throw new PendingVerificationException("Usuario no verificado");
                }
                user.setLastLogin(LocalDateTime.now());
                if (user.getGoogleId() == null) {
                    user.setGoogleId(googleId);
                }
                userRepository.save(user);
                auditLogService.logEvent("INFO", "LOGIN_SUCCESS", user.getId(), "/api/auth/google", "SUCCESS", "Inicio de sesión exitoso con Google");
            }

            String token = jwtTokenProvider.generateToken(user);
            auditLogService.logEvent("INFO", "JWT_GENERATED", user.getId(), "/api/auth/google", "SUCCESS", "Token JWT generado");
            return new AuthResponse(token, user, "Login exitoso", "ACTIVE");

        } catch (DisabledException | PendingVerificationException e) {
            throw e;
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            throw e;
        } catch (Exception e) {
            auditLogService.logEvent("WARN", "LOGIN_FAILED", null, "/api/auth/google", "FAILURE", "Token de Google inválido");
            throw new BadCredentialsException("Token de Google inválido");
        }
    }

    @Transactional
    public AuthResponse registerLocal(LocalRegisterRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email is already registered");
        }

        AppUser user = new AppUser();
        user.setEmail(request.getEmail());
        user.setFullName(request.getFullName());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setAuthProvider(AppUser.AuthProvider.LOCAL);
        user.setStatus(AppUser.Status.PENDING);
        
        assignRoleAndCreateProfile(user);
        
        String code = generateVerificationCode();
        user.setVerificationCode(code);
        user.setVerificationCodeExpiresAt(LocalDateTime.now().plusMinutes(15));
        
        user = userRepository.save(user);
        
        emailService.sendVerificationCode(user.getEmail(), code);

        return new AuthResponse(null, user, "Registro exitoso. Por favor verifica tu correo electrónico.", "PENDING_VERIFICATION");
    }

    @Transactional
    public AuthResponse loginLocal(LocalLoginRequest request) {
        Optional<AppUser> userOpt = userRepository.findByEmail(request.getEmail());
        
        if (userOpt.isEmpty()) {
            auditLogService.logEvent("WARN", "LOGIN_FAILED", null, "/api/auth/login", "FAILURE", "Usuario no encontrado: " + request.getEmail());
            throw new BadCredentialsException("Credenciales inválidas");
        }

        AppUser user = userOpt.get();

        if (user.getAuthProvider() == AppUser.AuthProvider.GOOGLE) {
            auditLogService.logEvent("WARN", "LOGIN_FAILED", user.getId(), "/api/auth/login", "FAILURE", "Intento de login local en cuenta de Google");
            throw new BadCredentialsException("Esta cuenta usa inicio de sesión con Google");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            auditLogService.logEvent("WARN", "LOGIN_FAILED", user.getId(), "/api/auth/login", "FAILURE", "Contraseña incorrecta");
            throw new BadCredentialsException("Credenciales inválidas");
        }

        if (!user.getActive()) {
            auditLogService.logEvent("WARN", "LOGIN_FAILED", user.getId(), "/api/auth/login", "FAILURE", "Usuario desactivado");
            throw new DisabledException("El usuario está desactivado");
        }
        if (user.getStatus() == AppUser.Status.PENDING) {
            auditLogService.logEvent("WARN", "LOGIN_FAILED", user.getId(), "/api/auth/login", "FAILURE", "Usuario pendiente de verificación");
            throw new PendingVerificationException("Usuario no verificado");
        }

        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);
        
        auditLogService.logEvent("INFO", "LOGIN_SUCCESS", user.getId(), "/api/auth/login", "SUCCESS", "Inicio de sesión exitoso");

        String token = jwtTokenProvider.generateToken(user);
        auditLogService.logEvent("INFO", "JWT_GENERATED", user.getId(), "/api/auth/login", "SUCCESS", "Token JWT generado");
        return new AuthResponse(token, user, "Login exitoso", "ACTIVE");
    }

    @Transactional
    public AuthResponse verifyCode(com.example.demo.models.dto.VerifyCodeRequest request) {
        AppUser user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        if (user.getAuthProvider() == AppUser.AuthProvider.GOOGLE) {
            throw new IllegalArgumentException("Esta cuenta fue creada con Google y no requiere verificación por correo.");
        }

        if (user.getStatus() == AppUser.Status.ACTIVE) {
            throw new IllegalArgumentException("El usuario ya está verificado");
        }

        if (user.getVerificationCode() == null || !user.getVerificationCode().equals(request.getCode())) {
            throw new IllegalArgumentException("Código de verificación incorrecto");
        }

        if (user.getVerificationCodeExpiresAt() != null && LocalDateTime.now().isAfter(user.getVerificationCodeExpiresAt())) {
            throw new IllegalArgumentException("El código de verificación ha expirado");
        }

        user.setStatus(AppUser.Status.ACTIVE);
        user.setVerificationCode(null);
        user.setVerificationCodeExpiresAt(null);
        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);

        String token = jwtTokenProvider.generateToken(user);
        auditLogService.logEvent("INFO", "JWT_GENERATED", user.getId(), "/api/auth/verify", "SUCCESS", "Token JWT generado tras verificación");
        return new AuthResponse(token, user, "Correo verificado exitosamente", "ACTIVE");
    }

    @Transactional
    public void resendCode(com.example.demo.models.dto.ResendCodeRequest request) {
        AppUser user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        if (user.getAuthProvider() == AppUser.AuthProvider.GOOGLE) {
            throw new IllegalArgumentException("Esta cuenta fue creada con Google y no requiere verificación por correo.");
        }

        if (user.getStatus() == AppUser.Status.ACTIVE) {
            throw new IllegalArgumentException("El usuario ya está verificado");
        }

        String code = generateVerificationCode();
        user.setVerificationCode(code);
        user.setVerificationCodeExpiresAt(LocalDateTime.now().plusMinutes(15));
        userRepository.save(user);

        emailService.sendVerificationCode(user.getEmail(), code);
    }

    @Transactional
    public void logout(String token) {
        io.jsonwebtoken.Claims claims = jwtTokenProvider.getClaims(token);
        String jti = claims.getId();
        if (jti != null && !revokedTokenRepository.existsByJti(jti)) {
            Long userId = Long.valueOf(claims.getSubject());
            AppUser user = userRepository.findById(userId)
                    .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

            com.example.demo.models.RevokedToken revokedToken = new com.example.demo.models.RevokedToken();
            revokedToken.setJti(jti);
            revokedToken.setUser(user);
            
            java.time.LocalDateTime exp = claims.getExpiration().toInstant()
                    .atZone(java.time.ZoneId.systemDefault()).toLocalDateTime();
            revokedToken.setExpiresAt(exp);
            
            revokedTokenRepository.save(revokedToken);
            auditLogService.logEvent("INFO", "LOGOUT", userId, "/api/auth/logout", "SUCCESS", "Cierre de sesión");
            auditLogService.logEvent("INFO", "TOKEN_REVOKED", userId, "/api/auth/logout", "SUCCESS", "Token revocado exitosamente");
        }
    }

    @org.springframework.scheduling.annotation.Scheduled(cron = "0 0 * * * *") // Cada hora
    @Transactional
    public void cleanupExpiredRevokedTokens() {
        revokedTokenRepository.deleteByExpiresAtBefore(LocalDateTime.now());
    }
}
