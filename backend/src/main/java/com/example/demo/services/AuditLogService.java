package com.example.demo.services;

import com.example.demo.models.AuditLog;
import com.example.demo.models.AppUser;
import com.example.demo.models.dto.AuditLogDTO;
import com.example.demo.repositories.AuditLogRepository;
import com.example.demo.repositories.AppUserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.stream.Collectors;
import java.time.format.DateTimeFormatter;
import java.time.ZoneId;
import java.time.ZonedDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;
    private final AppUserRepository appUserRepository;

    @Transactional(readOnly = true)
    public Page<AuditLogDTO> getLogs(String q, String eventType, Long userId, String date, Pageable pageable) {
        return auditLogRepository.findWithFilters(eventType, userId, date, q, pageable)
                .map(AuditLogDTO::new);
    }

    @Transactional
    public void logEvent(String level, String eventType, Long userId, String module, String result, String message) {
        try {
            AuditLog auditLog = new AuditLog();
            auditLog.setLevel(level);
            auditLog.setEventType(eventType);
            auditLog.setModule(module);
            auditLog.setResult(result);
            auditLog.setMessage(message);
            
            String userStr = "null";
            if (userId != null) {
                AppUser user = appUserRepository.findById(userId).orElse(null);
                auditLog.setUser(user);
                userStr = String.valueOf(userId);
            }
            
            auditLogRepository.save(auditLog);
            
            String timestamp = ZonedDateTime.now(ZoneId.of("UTC")).format(DateTimeFormatter.ISO_INSTANT);
            // Format: 2026-07-01T15:30:00Z INFO PURCHASE_CREATED user=25 order=103
            System.out.printf("%s %s %s user=%s %s%n", timestamp, level, eventType, userStr, message);
        } catch (Exception e) {
            log.error("Failed to save audit log: {}", e.getMessage());
        }
    }
}
