package com.example.demo.models.dto;

import lombok.Data;

@Data
public class LocalLoginRequest {
    private String email;
    private String password;
}
