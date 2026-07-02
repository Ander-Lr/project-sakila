package com.example.demo.repositories;

import com.example.demo.models.Film;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface FilmRepository extends JpaRepository<Film, Short> {

    @Query("SELECT DISTINCT f FROM Film f " +
           "LEFT JOIN f.actors a " +
           "LEFT JOIN f.categories c " +
           "WHERE LOWER(f.title) LIKE LOWER(CONCAT('%', :q, '%')) " +
           "OR LOWER(c.name) LIKE LOWER(CONCAT('%', :q, '%')) " +
           "OR LOWER(a.firstName) LIKE LOWER(CONCAT('%', :q, '%')) " +
           "OR LOWER(a.lastName) LIKE LOWER(CONCAT('%', :q, '%'))")
    Page<Film> searchFilms(@Param("q") String q, Pageable pageable);

    Page<Film> findByActiveTrue(Pageable pageable);

    @Query("SELECT DISTINCT f FROM Film f " +
           "LEFT JOIN f.categories c " +
           "WHERE (:title IS NULL OR :title = '' OR LOWER(f.title) LIKE LOWER(CONCAT('%', :title, '%'))) " +
           "AND (:category IS NULL OR :category = '' OR c.name = :category) " +
           "AND (:year IS NULL OR f.releaseYear = :year) " +
           "AND (:rating IS NULL OR :rating = '' OR f.rating = :rating) " +
           "AND f.active = true")
    Page<Film> advancedSearch(@Param("title") String title, @Param("category") String category, @Param("year") Integer year, @Param("rating") String rating, Pageable pageable);
}
