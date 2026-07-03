package com.example.demo.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class TestController {

    @GetMapping("/admin/test")
    public ResponseEntity<Map<String, Object>> adminTest() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Map<String, Object> response = new java.util.HashMap<>();
        response.put("message", "Welcome Admin!");
        response.put("id", auth.getName());
        response.put("authorities", auth.getAuthorities());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user/test")
    public ResponseEntity<Map<String, Object>> userTest() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Map<String, Object> response = new java.util.HashMap<>();
        response.put("message", "Welcome User!");
        response.put("id", auth.getName());
        response.put("authorities", auth.getAuthorities());
        return ResponseEntity.ok(response);
    }
}
