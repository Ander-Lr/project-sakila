package com.example.demo.exceptions;

import org.springframework.http.HttpStatus;

public class InvalidAmountException extends BusinessException {
    public InvalidAmountException(String message) {
        super("CANTIDAD_INVALIDA", message, HttpStatus.BAD_REQUEST);
    }
    
    public InvalidAmountException(String errorCode, String message) {
        super(errorCode, message, HttpStatus.BAD_REQUEST);
    }
}
