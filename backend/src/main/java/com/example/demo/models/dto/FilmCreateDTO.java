package com.example.demo.models.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class FilmCreateDTO {
    private String title;
    private String description;
    private Integer releaseYear;
    private Short languageId;
    private Short rentalDuration;
    private BigDecimal rentalRate;
    private Short length;
    private BigDecimal replacementCost;
    private String rating;
    private Boolean active;
}
