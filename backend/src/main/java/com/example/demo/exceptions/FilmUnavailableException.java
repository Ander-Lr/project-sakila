package com.example.demo.exceptions;

import org.springframework.http.HttpStatus;

public class FilmUnavailableException extends BusinessException {
    public FilmUnavailableException(String message) {
        super("PELICULA_NO_DISPONIBLE", message, HttpStatus.CONFLICT);
    }
}
