package com.example.demo.services;

import com.example.demo.exceptions.PaymentDeclinedException;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
public class FakePaymentGatewayService {

    public String processPayment(String cardNumber, String cardHolder, String expirationDate, String cvv, BigDecimal amount) {
        // Validación básica de rechazo (simulación)
        if ("000".equals(cvv)) {
            throw new PaymentDeclinedException("Tarjeta rechazada por CVV inválido");
        }
        
        // Simulación de validación de fondos o estado (e.g. tarjetas que terminen en 0000)
        if (cardNumber != null && cardNumber.endsWith("0000")) {
            throw new PaymentDeclinedException("Fondos insuficientes o tarjeta bloqueada");
        }
        
        // Si todo va bien, generamos una referencia única de transacción
        return UUID.randomUUID().toString();
    }
}
