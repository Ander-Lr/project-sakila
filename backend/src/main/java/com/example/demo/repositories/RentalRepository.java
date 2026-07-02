package com.example.demo.repositories;

import com.example.demo.models.Rental;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

@Repository
public interface RentalRepository extends JpaRepository<Rental, Integer> {
    
    @Query("SELECT r FROM Rental r WHERE " +
           "(:customerId IS NULL OR r.customer.customerId = :customerId) AND " +
           "(:filmId IS NULL OR r.inventory.film.filmId = :filmId) AND " +
           "(:rentalDate IS NULL OR CAST(r.rentalDate AS DATE) = CAST(:rentalDate AS DATE))")
    List<Rental> findWithFilters(@Param("customerId") Short customerId, 
                                 @Param("filmId") Short filmId, 
                                 @Param("rentalDate") String rentalDate);

    @Query("SELECT r FROM Rental r WHERE " +
           "(:customerId IS NULL OR r.customer.customerId = :customerId) AND " +
           "(:filmId IS NULL OR r.inventory.film.filmId = :filmId) AND " +
           "(:rentalDate IS NULL OR :rentalDate = '' OR CAST(r.rentalDate AS DATE) = CAST(:rentalDate AS DATE)) AND " +
           "(:q IS NULL OR :q = '' OR LOWER(r.customer.firstName) LIKE LOWER(CONCAT('%', :q, '%')) " +
           "OR LOWER(r.customer.lastName) LIKE LOWER(CONCAT('%', :q, '%')) " +
           "OR LOWER(r.inventory.film.title) LIKE LOWER(CONCAT('%', :q, '%')))")
    Page<Rental> findWithFiltersPaginated(@Param("customerId") Short customerId, 
                                          @Param("filmId") Short filmId, 
                                          @Param("rentalDate") String rentalDate,
                                          @Param("q") String q,
                                          Pageable pageable);

    List<Rental> findByReturnDateIsNotNull();

    long countByReturnDateIsNull();
    long countByReturnDateIsNotNull();
}
