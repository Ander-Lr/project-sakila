package com.example.demo.models.dto;

import lombok.Data;

@Data
public class LocalRegisterRequest {
    private String email;
    private String password;
    private String fullName;
}
