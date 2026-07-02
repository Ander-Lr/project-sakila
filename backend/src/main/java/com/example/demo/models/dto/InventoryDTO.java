package com.example.demo.models.dto;

import com.example.demo.models.Inventory;
import lombok.Data;

@Data
public class InventoryDTO {
    private Integer inventoryId;
    private Short filmId;
    private String filmTitle;
    private Short storeId;
    private String storeAddress;
    private Boolean active;

    public InventoryDTO(Inventory inventory) {
        this.inventoryId = inventory.getInventoryId();
        this.filmId = inventory.getFilm().getFilmId();
        this.filmTitle = inventory.getFilm().getTitle();
        this.storeId = inventory.getStore().getStoreId();
        this.storeAddress = inventory.getStore().getAddress().getAddress() + ", " + inventory.getStore().getAddress().getCity().getCity();
        this.active = inventory.getActive();
    }
}
