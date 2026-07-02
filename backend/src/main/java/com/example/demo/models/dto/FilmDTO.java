package com.example.demo.models.dto;

import com.example.demo.models.Film;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Data
public class FilmDTO {
    private Short filmId;
    private String title;
    private String description;
    private Integer releaseYear;
    private String language;
    private Short languageId;
    private Short rentalDuration;
    private BigDecimal rentalRate;
    private Short length;
    private BigDecimal replacementCost;
    private String rating;
    private Boolean active;
    private List<String> actors;
    private List<String> categories;

    public FilmDTO(Film film) {
        this.filmId = film.getFilmId();
        this.title = film.getTitle();
        this.description = film.getDescription();
        this.releaseYear = film.getReleaseYear();
        this.language = film.getLanguage() != null ? film.getLanguage().getName() : null;
        this.languageId = film.getLanguage() != null ? film.getLanguage().getLanguageId() : null;
        this.rentalDuration = film.getRentalDuration();
        this.rentalRate = film.getRentalRate();
        this.length = film.getLength();
        this.replacementCost = film.getReplacementCost();
        this.rating = film.getRating();
        this.active = film.getActive();
        this.actors = film.getActors().stream()
                .map(a -> a.getFirstName() + " " + a.getLastName())
                .collect(Collectors.toList());
        this.categories = film.getCategories().stream()
                .map(c -> c.getName())
                .collect(Collectors.toList());
    }
}
