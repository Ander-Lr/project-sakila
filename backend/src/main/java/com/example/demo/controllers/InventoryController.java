package com.example.demo.controllers;

import com.example.demo.models.InventoryAvailability;
import com.example.demo.models.dto.InventoryAvailabilityDTO;
import com.example.demo.models.dto.InventoryCreateDTO;
import com.example.demo.models.dto.InventoryDTO;
import com.example.demo.services.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<InventoryDTO>> getInventoryByFilmId(@RequestParam Short filmId) {
        return ResponseEntity.ok(inventoryService.getInventoryByFilmId(filmId));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<InventoryDTO> createInventory(@RequestBody InventoryCreateDTO dto) {
        return ResponseEntity.ok(inventoryService.createInventory(dto));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateInventoryStatus(@PathVariable Integer id, @RequestBody Map<String, Boolean> body) {
        Boolean status = body.get("active");
        if (status == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "El campo 'active' es requerido"));
        }
        inventoryService.updateInventoryStatus(id, status);
        return ResponseEntity.ok(Map.of("message", "Estado de inventario actualizado", "active", status));
    }

    @GetMapping("/{id}/availability")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<InventoryAvailabilityDTO> getInventoryAvailability(@PathVariable Integer id) {
        return ResponseEntity.ok(inventoryService.getInventoryAvailability(id));
    }
}
