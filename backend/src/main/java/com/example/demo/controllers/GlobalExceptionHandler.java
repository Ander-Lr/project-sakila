package com.example.demo.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.dao.DataAccessException;
import org.springframework.validation.FieldError;
import com.example.demo.exceptions.PaymentDeclinedException;
import com.example.demo.exceptions.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import java.util.LinkedHashMap;
import java.util.Map;
import java.time.format.DateTimeFormatter;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private Map<String, Object> createErrorBody(HttpStatus status, String error, String message, String path) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", ZonedDateTime.now(ZoneId.of("UTC")).format(DateTimeFormatter.ISO_INSTANT));
        body.put("status", status.value());
        body.put("error", error);
        body.put("message", message);
        body.put("path", path);
        return body;
    }

    private void logErrorEvent(String eventType, String message, String path) {
        String timestampForLog = ZonedDateTime.now(ZoneId.of("UTC")).format(DateTimeFormatter.ISO_INSTANT);
        System.out.printf("%s ERROR %s user=null path=%s %s%n", timestampForLog, eventType, path, message);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessException(BusinessException ex, HttpServletRequest request) {
        Map<String, Object> body = createErrorBody(ex.getStatus(), ex.getErrorCode(), ex.getMessage(), request.getRequestURI());
        return ResponseEntity.status(ex.getStatus()).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationExceptions(MethodArgumentNotValidException ex, HttpServletRequest request) {
        String errors = ex.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining(", "));
        logErrorEvent("VALIDATION_ERROR", "Campos incompletos: " + errors, request.getRequestURI());
        Map<String, Object> body = createErrorBody(HttpStatus.BAD_REQUEST, "CAMPOS_INCOMPLETOS", "Los datos enviados son inválidos: " + errors, request.getRequestURI());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<Map<String, Object>> handleTypeMismatch(Exception ex, HttpServletRequest request) {
        logErrorEvent("VALIDATION_ERROR", "Tipo de dato incorrecto", request.getRequestURI());
        Map<String, Object> body = createErrorBody(HttpStatus.BAD_REQUEST, "TIPO_DATO_INCORRECTO", "El formato de los datos o los tipos de datos enviados son incorrectos.", request.getRequestURI());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, Object>> handleDatabaseException(DataAccessException ex, HttpServletRequest request) {
        System.err.println("DB Error: " + ex.getMessage()); // Log internal error securely
        logErrorEvent("DATABASE_ERROR", "Ocurrió un error en la base de datos", request.getRequestURI());
        Map<String, Object> body = createErrorBody(HttpStatus.INTERNAL_SERVER_ERROR, "ERROR_BASE_DATOS", "Ocurrió un error al procesar los datos.", request.getRequestURI());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex, HttpServletRequest request) {
        logErrorEvent("VALIDATION_ERROR", "Petición inválida", request.getRequestURI());
        Map<String, Object> body = createErrorBody(HttpStatus.BAD_REQUEST, "PETICION_INVALIDA", ex.getMessage(), request.getRequestURI());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(PaymentDeclinedException.class)
    public ResponseEntity<Map<String, Object>> handlePaymentDeclined(PaymentDeclinedException ex, HttpServletRequest request) {
        Map<String, Object> body = createErrorBody(HttpStatus.PAYMENT_REQUIRED, "PAGO_RECHAZADO", ex.getMessage(), request.getRequestURI());
        return ResponseEntity.status(HttpStatus.PAYMENT_REQUIRED).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAllExceptions(Exception ex, HttpServletRequest request) {
        System.err.println("Internal Server Error: " + ex.getMessage());
        ex.printStackTrace(); // Log full trace internally
        logErrorEvent("INTERNAL_ERROR", "Ocurrió un error interno", request.getRequestURI());
        Map<String, Object> body = createErrorBody(HttpStatus.INTERNAL_SERVER_ERROR, "ERROR_INTERNO_SERVIDOR", "Ocurrió un error interno en el servidor.", request.getRequestURI());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}
