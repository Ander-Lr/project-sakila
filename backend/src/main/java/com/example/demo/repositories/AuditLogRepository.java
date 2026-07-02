package com.example.demo.repositories;

import com.example.demo.models.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    @Query("SELECT a FROM AuditLog a WHERE " +
           "(:eventType IS NULL OR :eventType = '' OR a.eventType = :eventType) AND " +
           "(:userId IS NULL OR a.user.id = :userId) AND " +
           "(:date IS NULL OR :date = '' OR CAST(a.eventTime AS date) = CAST(:date AS date)) AND " +
           "(:q IS NULL OR :q = '' OR LOWER(a.message) LIKE LOWER(CONCAT('%', :q, '%')) " +
           "OR LOWER(a.module) LIKE LOWER(CONCAT('%', :q, '%')))")
    Page<AuditLog> findWithFilters(@Param("eventType") String eventType, 
                                   @Param("userId") Long userId, 
                                   @Param("date") String date,
                                   @Param("q") String q,
                                   Pageable pageable);
}
