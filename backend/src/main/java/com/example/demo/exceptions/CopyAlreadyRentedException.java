package com.example.demo.exceptions;

import org.springframework.http.HttpStatus;

public class CopyAlreadyRentedException extends BusinessException {
    public CopyAlreadyRentedException(String message) {
        super("EJEMPLAR_YA_ALQUILADO", message, HttpStatus.CONFLICT);
    }
}
