package com.example.demo.controllers;

import com.example.demo.models.dto.FilmCreateDTO;
import com.example.demo.models.dto.FilmDTO;
import com.example.demo.services.FilmService;
import com.example.demo.services.InventoryService;
import com.example.demo.models.dto.InventoryAvailabilityDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.List;

@RestController
@RequestMapping("/api/films")
@RequiredArgsConstructor
public class FilmController {

    private final FilmService filmService;
    private final InventoryService inventoryService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CUSTOMER')")
    public ResponseEntity<Page<FilmDTO>> getFilms(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "filmId") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort.Direction direction = sortDir.equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        return ResponseEntity.ok(filmService.getAllFilms(pageable));
    }

    @GetMapping("/available")
    @PreAuthorize("hasAnyRole('ADMIN', 'CUSTOMER')")
    public ResponseEntity<Page<FilmDTO>> getAvailableFilms(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "filmId") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort.Direction direction = sortDir.equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        return ResponseEntity.ok(filmService.getAvailableFilms(pageable));
    }

    @GetMapping("/{id}/inventory")
    @PreAuthorize("hasAnyRole('ADMIN', 'CUSTOMER')")
    public ResponseEntity<List<InventoryAvailabilityDTO>> getAvailableInventoryByFilmId(@PathVariable Short id) {
        return ResponseEntity.ok(inventoryService.getAvailableInventoryByFilmId(id));
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'CUSTOMER')")
    public ResponseEntity<Page<FilmDTO>> searchFilms(
            @RequestParam String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "filmId") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort.Direction direction = sortDir.equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        return ResponseEntity.ok(filmService.searchFilms(q, pageable));
    }

    @GetMapping("/advanced-search")
    @PreAuthorize("hasAnyRole('ADMIN', 'CUSTOMER')")
    public ResponseEntity<Page<FilmDTO>> advancedSearch(
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) String rating,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "filmId") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort.Direction direction = sortDir.equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        return ResponseEntity.ok(filmService.advancedSearch(title, category, year, rating, pageable));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FilmDTO> createFilm(@RequestBody FilmCreateDTO dto) {
        return ResponseEntity.ok(filmService.createFilm(dto));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FilmDTO> updateFilm(@PathVariable Short id, @RequestBody FilmCreateDTO dto) {
        return ResponseEntity.ok(filmService.updateFilm(id, dto));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateFilmStatus(@PathVariable Short id, @RequestBody Map<String, Boolean> body) {
        Boolean status = body.get("active");
        if (status == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "El campo 'active' es requerido"));
        }
        filmService.updateFilmStatus(id, status);
        return ResponseEntity.ok(Map.of("message", "Estado actualizado", "active", status));
    }
}
