package com.example.demo.services;

import com.example.demo.models.Film;
import com.example.demo.models.Inventory;
import com.example.demo.models.InventoryAvailability;
import com.example.demo.models.dto.InventoryAvailabilityDTO;
import com.example.demo.models.dto.InventoryCreateDTO;
import com.example.demo.models.dto.InventoryDTO;
import com.example.demo.repositories.FilmRepository;
import com.example.demo.repositories.InventoryRepository;
import com.example.demo.repositories.InventoryAvailabilityRepository;
import com.example.demo.repositories.StoreRepository;
import com.example.demo.models.Store;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryRepository inventoryRepository;
    private final InventoryAvailabilityRepository availabilityRepository;
    private final FilmRepository filmRepository;
    private final StoreRepository storeRepository;
    private final AuditLogService auditLogService;

    private Long getCurrentUserId() {
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getName() != null && !auth.getName().equals("anonymousUser")) {
            try {
                return Long.parseLong(auth.getName());
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    @Transactional(readOnly = true)
    public List<InventoryDTO> getInventoryByFilmId(Short filmId) {
        return inventoryRepository.findByFilm_FilmId(filmId).stream()
                .map(InventoryDTO::new)
                .collect(Collectors.toList());
    }

    @Transactional
    public InventoryDTO createInventory(InventoryCreateDTO dto) {
        if (dto.getFilmId() == null || dto.getStoreId() == null) {
            throw new IllegalArgumentException("filmId y storeId son requeridos");
        }

        Film film = filmRepository.findById(dto.getFilmId())
                .orElseThrow(() -> new IllegalArgumentException("Película no encontrada"));

        Store store = storeRepository.findById(dto.getStoreId())
                .orElseThrow(() -> new IllegalArgumentException("Tienda no encontrada"));

        Inventory inventory = new Inventory();
        inventory.setFilm(film);
        inventory.setStore(store);
        
        if (dto.getActive() != null) {
            inventory.setActive(dto.getActive());
        }
        
        inventory.setLastUpdate(LocalDateTime.now());
        
        Inventory saved = inventoryRepository.save(inventory);
        auditLogService.logEvent("INFO", "RECORD_CREATED", getCurrentUserId(), "/api/admin/inventory", "SUCCESS", "Inventario creado: " + saved.getInventoryId());
        return new InventoryDTO(saved);
    }

    @Transactional
    public void updateInventoryStatus(Integer inventoryId, boolean status) {
        Inventory inventory = inventoryRepository.findById(inventoryId)
                .orElseThrow(() -> new IllegalArgumentException("Inventario no encontrado"));
        
        inventory.setActive(status);
        inventory.setLastUpdate(LocalDateTime.now());
        inventoryRepository.save(inventory);
        auditLogService.logEvent("INFO", "AVAILABILITY_CHANGED", getCurrentUserId(), "/api/admin/inventory/" + inventoryId + "/status", "SUCCESS", "Estado de inventario cambiado a " + status);
    }

    @Transactional(readOnly = true)
    public InventoryAvailabilityDTO getInventoryAvailability(Integer inventoryId) {
        InventoryAvailability availability = availabilityRepository.findById(inventoryId)
                .orElseThrow(() -> new IllegalArgumentException("Disponibilidad no encontrada"));
        return new InventoryAvailabilityDTO(availability);
    }

    @Transactional(readOnly = true)
    public List<InventoryAvailabilityDTO> getAvailableInventoryByFilmId(Short filmId) {
        return availabilityRepository.findByFilm_FilmIdAndAvailableTrue(filmId).stream()
                .map(InventoryAvailabilityDTO::new)
                .collect(Collectors.toList());
    }
}
