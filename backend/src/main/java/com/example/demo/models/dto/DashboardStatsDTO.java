package com.example.demo.models.dto;

import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DashboardStatsDTO {
    private long totalFilms;
    private long totalCopies;
    private long activeRentals;
    private long returnedRentals;
}
