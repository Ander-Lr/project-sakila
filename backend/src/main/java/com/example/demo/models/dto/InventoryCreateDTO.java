package com.example.demo.models.dto;

import lombok.Data;

@Data
public class InventoryCreateDTO {
    private Short filmId;
    private Short storeId;
    private Boolean active;
}
