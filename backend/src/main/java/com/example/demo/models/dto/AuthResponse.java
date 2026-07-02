package com.example.demo.models.dto;

import com.example.demo.models.AppUser;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String token;
    private AppUser user;
    private String message;
    private String status;

}
