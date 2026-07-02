package com.example.demo.repositories;

import com.example.demo.models.InventoryAvailability;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InventoryAvailabilityRepository extends JpaRepository<InventoryAvailability, Integer> {
    List<InventoryAvailability> findByFilm_FilmIdAndAvailableTrue(Short filmId);
}
