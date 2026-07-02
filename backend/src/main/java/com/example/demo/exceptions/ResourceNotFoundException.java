package com.example.demo.exceptions;

import org.springframework.http.HttpStatus;

public class ResourceNotFoundException extends BusinessException {
    public ResourceNotFoundException(String message) {
        super("REGISTRO_INEXISTENTE", message, HttpStatus.NOT_FOUND);
    }
}
