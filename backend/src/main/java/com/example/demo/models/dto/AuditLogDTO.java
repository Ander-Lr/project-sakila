package com.example.demo.models.dto;

import com.example.demo.models.AuditLog;
import lombok.Data;
import java.time.LocalDateTime;

@Data
public class AuditLogDTO {
    private Long logId;
    private LocalDateTime eventTime;
    private String level;
    private String eventType;
    private Long userId;
    private String module;
    private String result;
    private String message;

    public AuditLogDTO(AuditLog log) {
        this.logId = log.getLogId();
        this.eventTime = log.getEventTime();
        this.level = log.getLevel();
        this.eventType = log.getEventType();
        this.userId = log.getUser() != null ? log.getUser().getId() : null;
        this.module = log.getModule();
        this.result = log.getResult();
        this.message = log.getMessage();
    }
}
