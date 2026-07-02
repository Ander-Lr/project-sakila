package com.example.demo.security;

public class PendingVerificationException extends RuntimeException {
    public PendingVerificationException(String message) {
        super(message);
    }
}
