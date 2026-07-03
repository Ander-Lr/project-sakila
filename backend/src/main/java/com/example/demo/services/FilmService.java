package com.example.demo.services;

import com.example.demo.models.Film;
import com.example.demo.models.Language;
import com.example.demo.models.dto.FilmCreateDTO;
import com.example.demo.models.dto.FilmDTO;
import com.example.demo.repositories.FilmRepository;
import com.example.demo.repositories.LanguageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

@Service
@RequiredArgsConstructor
public class FilmService {

    private final FilmRepository filmRepository;
    private final LanguageRepository languageRepository;
    private final AuditLogService auditLogService;

    private Long getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
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
    public Page<FilmDTO> getAllFilms(Pageable pageable) {
        return filmRepository.findAll(pageable).map(FilmDTO::new);
    }

    @Transactional(readOnly = true)
    public Page<FilmDTO> getAvailableFilms(Pageable pageable) {
        return filmRepository.findByActiveTrue(pageable).map(FilmDTO::new);
    }

    @Transactional(readOnly = true)
    public Page<FilmDTO> searchFilms(String query, Pageable pageable) {
        return filmRepository.searchFilms(query, pageable).map(FilmDTO::new);
    }

    @Transactional(readOnly = true)
    public Page<FilmDTO> advancedSearch(String title, String category, Integer year, String rating, Pageable pageable) {
        return filmRepository.advancedSearch(title, category, year, rating, pageable).map(FilmDTO::new);
    }

    @Transactional
    public FilmDTO createFilm(FilmCreateDTO dto) {
        Film film = new Film();
        film.setTitle(dto.getTitle());
        film.setDescription(dto.getDescription());
        film.setReleaseYear(dto.getReleaseYear());

        if (dto.getLanguageId() != null) {
            Language lang = languageRepository.findById(dto.getLanguageId())
                    .orElseThrow(() -> new IllegalArgumentException("Language no encontrado"));
            film.setLanguage(lang);
        } else {
            throw new IllegalArgumentException("Language ID es obligatorio");
        }

        if (dto.getRentalDuration() != null) film.setRentalDuration(dto.getRentalDuration());
        if (dto.getRentalRate() != null) film.setRentalRate(dto.getRentalRate());
        if (dto.getLength() != null) film.setLength(dto.getLength());
        if (dto.getReplacementCost() != null) film.setReplacementCost(dto.getReplacementCost());
        if (dto.getRating() != null) film.setRating(dto.getRating());
        if (dto.getActive() != null) film.setActive(dto.getActive());

        film.setLastUpdate(LocalDateTime.now());
        
        Film savedFilm = filmRepository.save(film);
        
        auditLogService.logEvent("INFO", "RECORD_CREATED", getCurrentUserId(), "/api/admin/films", "SUCCESS", "Película creada: " + savedFilm.getFilmId());
        return new FilmDTO(savedFilm);
    }

    @Transactional
    public FilmDTO updateFilm(Short id, FilmCreateDTO dto) {
        Film film = filmRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Película no encontrada"));

        if (dto.getTitle() != null) film.setTitle(dto.getTitle());
        if (dto.getDescription() != null) film.setDescription(dto.getDescription());
        if (dto.getReleaseYear() != null) film.setReleaseYear(dto.getReleaseYear());
        
        if (dto.getLanguageId() != null) {
            Language lang = languageRepository.findById(dto.getLanguageId())
                    .orElseThrow(() -> new IllegalArgumentException("Language no encontrado"));
            film.setLanguage(lang);
        }

        if (dto.getRentalDuration() != null) film.setRentalDuration(dto.getRentalDuration());
        if (dto.getRentalRate() != null) film.setRentalRate(dto.getRentalRate());
        if (dto.getLength() != null) film.setLength(dto.getLength());
        if (dto.getReplacementCost() != null) film.setReplacementCost(dto.getReplacementCost());
        if (dto.getRating() != null) film.setRating(dto.getRating());
        if (dto.getActive() != null) film.setActive(dto.getActive());

        film.setLastUpdate(LocalDateTime.now());

        Film savedFilm = filmRepository.save(film);
        auditLogService.logEvent("INFO", "RECORD_UPDATED", getCurrentUserId(), "/api/admin/films/" + id, "SUCCESS", "Película actualizada");
        return new FilmDTO(savedFilm);
    }

    @Transactional
    public void updateFilmStatus(Short id, boolean status) {
        Film film = filmRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Película no encontrada"));
        film.setActive(status);
        film.setLastUpdate(LocalDateTime.now());
        filmRepository.save(film);
        auditLogService.logEvent("INFO", "AVAILABILITY_CHANGED", getCurrentUserId(), "/api/admin/films/" + id + "/status", "SUCCESS", "Disponibilidad cambiada a " + status);
    }
}
