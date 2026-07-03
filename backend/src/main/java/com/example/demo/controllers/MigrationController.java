package com.example.demo.controllers;

import com.example.demo.services.MigrationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class MigrationController {

    private final MigrationService migrationService;

    @PostMapping("/migrate-users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> migrateUsers() {
        int count = migrationService.migrateUsers();
        return ResponseEntity.ok("Migración completada. Usuarios actualizados/creados: " + count);
    }
}
