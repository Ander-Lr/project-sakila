package com.example.demo.models.dto;

import lombok.Data;

@Data
public class RentalRequestDTO {
    private Integer filmId;
    private Integer inventoryId;
    private String cardNumber;
    private String cardHolder;
    private String expirationDate;
    private String cvv;
}
