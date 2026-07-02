package com.example.demo.exceptions;

import org.springframework.http.HttpStatus;

public class DuplicateReturnException extends BusinessException {
    public DuplicateReturnException(String message) {
        super("DEVOLUCION_DUPLICADA", message, HttpStatus.CONFLICT);
    }
}
