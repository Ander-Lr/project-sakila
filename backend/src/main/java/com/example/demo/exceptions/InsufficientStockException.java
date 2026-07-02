package com.example.demo.exceptions;

import org.springframework.http.HttpStatus;

public class InsufficientStockException extends BusinessException {
    public InsufficientStockException(String message) {
        super("STOCK_INSUFICIENTE", message, HttpStatus.CONFLICT);
    }
}
