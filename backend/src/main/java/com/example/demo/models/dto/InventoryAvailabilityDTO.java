package com.example.demo.models.dto;

import com.example.demo.models.InventoryAvailability;
import lombok.Data;

@Data
public class InventoryAvailabilityDTO {
    private Integer inventoryId;
    private Short filmId;
    private String filmTitle;
    private Short storeId;
    private String storeAddress;
    private Boolean available;

    public InventoryAvailabilityDTO(InventoryAvailability availability) {
        this.inventoryId = availability.getInventoryId();
        this.filmId = availability.getFilm().getFilmId();
        this.filmTitle = availability.getFilm().getTitle();
        this.storeId = availability.getStore().getStoreId();
        this.storeAddress = availability.getStore().getAddress().getAddress() + ", " + availability.getStore().getAddress().getCity().getCity();
        this.available = availability.getAvailable();
    }
}
