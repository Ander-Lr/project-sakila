package com.example.demo.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import com.example.demo.repositories.RevokedTokenRepository;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.SignatureException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final JwtTokenProvider tokenProvider;
    private final RevokedTokenRepository revokedTokenRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String token = getJwtFromRequest(request);

        if (StringUtils.hasText(token)) {
            try {
                Claims claims = tokenProvider.getClaims(token);

                String jti = claims.getId();
                if (jti != null && revokedTokenRepository.existsByJti(jti)) {
                    logger.warn("AUDIT_LOG: Token revocado (jti: {})", jti);
                    request.setAttribute("jwt_error", "Token revocado");
                } else {
                    String roleStr = claims.get("role", String.class);
                    String idStr = claims.getSubject();

                    GrantedAuthority authority = new SimpleGrantedAuthority("ROLE_" + roleStr);
                    List<GrantedAuthority> authorities = Collections.singletonList(authority);

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            idStr, null, authorities);

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }

            } catch (ExpiredJwtException ex) {
                logger.warn("AUDIT_LOG: Token vencido");
                request.setAttribute("jwt_error", "Token vencido");
            } catch (SignatureException ex) {
                logger.warn("AUDIT_LOG: Firma de token inválida o alterada");
                request.setAttribute("jwt_error", "Firma de token inválida");
            } catch (MalformedJwtException | UnsupportedJwtException | IllegalArgumentException ex) {
                logger.warn("AUDIT_LOG: Formato de token roto o inválido: {}", ex.getMessage());
                request.setAttribute("jwt_error", "Formato de token inválido");
            } catch (Exception ex) {
                logger.warn("AUDIT_LOG: Error procesando token: {}", ex.getMessage());
                request.setAttribute("jwt_error", "Error interno con el token");
            }
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
