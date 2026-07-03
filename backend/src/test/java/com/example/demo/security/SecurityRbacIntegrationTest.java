package com.example.demo.security;

import com.example.demo.models.AppUser;
import com.example.demo.models.RevokedToken;
import com.example.demo.repositories.AppUserRepository;
import com.example.demo.repositories.RevokedTokenRepository;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
public class SecurityRbacIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private RevokedTokenRepository revokedTokenRepository;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Value("${jwt.secret}")
    private String jwtSecret;

    private String adminToken;
    private String customerToken;
    private String revokedToken;
    
    private AppUser customer;

    @BeforeEach
    void setUp() {
        // Limpiar para asegurar estado aislado
        revokedTokenRepository.deleteAll();

        // 1. Crear un Administrador
        AppUser admin = userRepository.findByEmail("admin_test@test.com").orElseGet(() -> {
            AppUser u = new AppUser();
            u.setEmail("admin_test@test.com");
            u.setPasswordHash(passwordEncoder.encode("1234"));
            u.setRole(AppUser.Role.ADMIN);
            u.setFullName("Admin Test");
            u.setActive(true);
            return userRepository.save(u);
        });
        adminToken = jwtTokenProvider.generateToken(admin);

        // 2. Crear un Cliente
        customer = userRepository.findByEmail("customer_test@test.com").orElseGet(() -> {
            AppUser u = new AppUser();
            u.setEmail("customer_test@test.com");
            u.setPasswordHash(passwordEncoder.encode("1234"));
            u.setRole(AppUser.Role.CUSTOMER);
            u.setFullName("Customer Test");
            u.setActive(true);
            return userRepository.save(u);
        });
        customerToken = jwtTokenProvider.generateToken(customer);

        // 3. Crear un token que luego será revocado
        revokedToken = jwtTokenProvider.generateToken(customer);
        String jti = jwtTokenProvider.getClaims(revokedToken).getId();
        
        RevokedToken rt = new RevokedToken();
        rt.setJti(jti);
        rt.setUser(customer);
        rt.setRevokedAt(LocalDateTime.now());
        rt.setExpiresAt(LocalDateTime.now().plusHours(1));
        revokedTokenRepository.save(rt);
    }

    // 1. Acceso permitido para el administrador (a ruta de admin)
    @Test
    void testAdminAccessToAdminRoute() throws Exception {
        mockMvc.perform(get("/api/admin/logs")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    // 2. Acceso permitido para el cliente (a ruta de cliente compartida)
    @Test
    void testCustomerAccessToSharedRoute() throws Exception {
        mockMvc.perform(get("/api/films")
                .header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    // 3. Rechazo de una solicitud sin token
    @Test
    void testAccessWithoutToken() throws Exception {
        mockMvc.perform(get("/api/films")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized()); // 401
    }

    // 4. Rechazo de un token inválido
    @Test
    void testAccessWithInvalidToken() throws Exception {
        mockMvc.perform(get("/api/films")
                .header("Authorization", "Bearer this.is.an.invalid.token")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized()); // 401
    }

    // 5. Rechazo de un token vencido
    @Test
    void testAccessWithExpiredToken() throws Exception {
        // Generar un token con tiempo de expiración en el pasado
        String expiredToken = Jwts.builder()
                .setSubject(customer.getId().toString())
                .claim("role", "CUSTOMER")
                .setId(UUID.randomUUID().toString())
                .setIssuedAt(new Date(System.currentTimeMillis() - 20000))
                .setExpiration(new Date(System.currentTimeMillis() - 10000))
                .signWith(Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8)), SignatureAlgorithm.HS256)
                .compact();

        mockMvc.perform(get("/api/films")
                .header("Authorization", "Bearer " + expiredToken)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized()); // 401
    }

    // 6. Rechazo de un token revocado
    @Test
    void testAccessWithRevokedToken() throws Exception {
        mockMvc.perform(get("/api/films")
                .header("Authorization", "Bearer " + revokedToken)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized()); // 401
    }

    // 7. Rechazo de un cliente que intente utilizar una ruta administrativa
    @Test
    void testCustomerAccessToAdminRoute() throws Exception {
        mockMvc.perform(get("/api/admin/logs")
                .header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden()); // 403 Forbidden (RBAC)
    }

    // 8. Rechazo de un administrador cuando intente acceder a una operación de cliente
    @Test
    void testAdminAccessToCustomerOnlyRoute() throws Exception {
        // /api/rentals/mine is exclusive for CUSTOMER
        mockMvc.perform(get("/api/rentals/mine")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden()); // 403 Forbidden (RBAC)
    }
}
