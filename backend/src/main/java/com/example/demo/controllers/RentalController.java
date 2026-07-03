package com.example.demo.controllers;

import com.example.demo.models.dto.RentalDTO;
import com.example.demo.services.RentalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.Authentication;
import com.example.demo.models.dto.RentalRequestDTO;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

@RestController
@RequestMapping("/api/rentals")
@RequiredArgsConstructor
public class RentalController {

    private final RentalService rentalService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<RentalDTO>> getAllRentals(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Short customerId,
            @RequestParam(required = false) Short filmId,
            @RequestParam(required = false) String date,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "rentalDate") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort.Direction direction = sortDir.equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        return ResponseEntity.ok(rentalService.getAllRentals(q, customerId, filmId, date, PageRequest.of(page, size, Sort.by(direction, sortBy))));
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<RentalDTO>> getMyRentals() {
        String userIdStr = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Long userId = Long.valueOf(userIdStr);
        return ResponseEntity.ok(rentalService.getMyRentals(userId));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('CUSTOMER', 'ADMIN')")
    public ResponseEntity<RentalDTO> createRental(@RequestBody RentalRequestDTO request) {
        String userIdStr = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Long userId = Long.valueOf(userIdStr);
        
        return ResponseEntity.ok(rentalService.createRental(request, userId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RentalDTO> getRentalById(@PathVariable Integer id) {
        return ResponseEntity.ok(rentalService.getRentalById(id));
    }

    @PostMapping("/{id}/return")
    @PreAuthorize("hasAnyRole('CUSTOMER', 'ADMIN')")
    public ResponseEntity<RentalDTO> returnRental(@PathVariable Integer id) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String userIdStr = (String) auth.getPrincipal();
        Long userId = Long.valueOf(userIdStr);
        
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
                
        return ResponseEntity.ok(rentalService.returnRental(id, userId, isAdmin));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteRental(@PathVariable Integer id) {
        String userIdStr = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Long userId = Long.valueOf(userIdStr);
        rentalService.deleteRental(id, userId);
        return ResponseEntity.noContent().build();
    }
}
