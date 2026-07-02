package com.example.demo.models;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;
import lombok.Getter;
import org.hibernate.annotations.Immutable;

import org.hibernate.annotations.Subselect;

@Entity
@Subselect("SELECT * FROM inventory_availability")
@Immutable
@Getter
public class InventoryAvailability {

    @Id
    @Column(name = "inventory_id")
    private Integer inventoryId;

    @ManyToOne
    @JoinColumn(name = "film_id")
    private Film film;

    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;

    @Column(name = "available")
    private Boolean available;
}
