package com.example.demo.controllers;

import com.example.demo.models.dto.AuditLogDTO;
import com.example.demo.models.dto.DashboardStatsDTO;
import com.example.demo.services.AuditLogService;
import com.example.demo.repositories.FilmRepository;
import com.example.demo.repositories.InventoryRepository;
import com.example.demo.repositories.RentalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AuditLogService auditLogService;
    private final FilmRepository filmRepository;
    private final InventoryRepository inventoryRepository;
    private final RentalRepository rentalRepository;

    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<DashboardStatsDTO> getDashboardStats() {
        long totalFilms = filmRepository.count();
        long totalCopies = inventoryRepository.count();
        long activeRentals = rentalRepository.countByReturnDateIsNull();
        long returnedRentals = rentalRepository.countByReturnDateIsNotNull();
        
        DashboardStatsDTO stats = new DashboardStatsDTO(totalFilms, totalCopies, activeRentals, returnedRentals);
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/logs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<AuditLogDTO>> getLogs(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String eventType,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String date,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "eventTime") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort.Direction direction = sortDir.equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        return ResponseEntity.ok(auditLogService.getLogs(q, eventType, userId, date, PageRequest.of(page, size, Sort.by(direction, sortBy))));
    }
}
