package com.example.demo.services;

import com.example.demo.models.Rental;
import com.example.demo.models.dto.RentalDTO;
import com.example.demo.repositories.RentalRepository;
import com.example.demo.models.AppUser;
import com.example.demo.models.Inventory;
import com.example.demo.models.InventoryAvailability;
import com.example.demo.repositories.AppUserRepository;
import com.example.demo.repositories.CustomerRepository;
import com.example.demo.repositories.InventoryRepository;
import com.example.demo.repositories.InventoryAvailabilityRepository;
import com.example.demo.models.Payment;
import com.example.demo.models.dto.RentalRequestDTO;
import com.example.demo.repositories.PaymentRepository;
import com.example.demo.services.FakePaymentGatewayService;
import com.example.demo.exceptions.PaymentDeclinedException;
import com.example.demo.exceptions.InvalidAmountException;
import com.example.demo.exceptions.ResourceNotFoundException;
import com.example.demo.exceptions.InsufficientStockException;
import com.example.demo.exceptions.FilmUnavailableException;
import com.example.demo.exceptions.DuplicateReturnException;
import com.example.demo.exceptions.CopyAlreadyRentedException;
import com.example.demo.services.AuditLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;

@Service
@RequiredArgsConstructor
@Slf4j
public class RentalService {

    private final RentalRepository rentalRepository;
    private final AppUserRepository appUserRepository;
    private final CustomerRepository customerRepository;
    private final InventoryRepository inventoryRepository;
    private final InventoryAvailabilityRepository inventoryAvailabilityRepository;
    private final PaymentRepository paymentRepository;
    private final FakePaymentGatewayService paymentGatewayService;
    private final AuditLogService auditLogService;

    @Transactional(readOnly = true)
    public Page<RentalDTO> getAllRentals(String q, Short customerId, Short filmId, String date, Pageable pageable) {
        Page<Rental> rentals = rentalRepository.findWithFiltersPaginated(customerId, filmId, date, q, pageable);
        return rentals.map(RentalDTO::new);
    }

    @Transactional(readOnly = true)
    public RentalDTO getRentalById(Integer id) {
        Rental rental = rentalRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Alquiler no encontrado"));
        return new RentalDTO(rental);
    }

    @Transactional(readOnly = true)
    public List<RentalDTO> getReturns() {
        return rentalRepository.findByReturnDateIsNotNull().stream()
                .map(RentalDTO::new)
                .collect(Collectors.toList());
    }

    @Transactional
    public RentalDTO createRental(RentalRequestDTO request, Long appUserId) {
        AppUser appUser = appUserRepository.findById(appUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
                
        if (appUser.getCustomerId() == null) {
            throw new AccessDeniedException("El usuario no tiene un perfil de cliente asociado");
        }

        // Basic card validation
        if (request.getCardNumber() == null || request.getCardNumber().length() != 16) {
            throw new InvalidAmountException("PETICION_INVALIDA", "Número de tarjeta inválido. Debe tener 16 dígitos.");
        }
        if (request.getCvv() == null || request.getCvv().length() < 3) {
            throw new InvalidAmountException("PETICION_INVALIDA", "CVV inválido.");
        }

        Integer inventoryId = request.getInventoryId();
        if (inventoryId == null) {
            if (request.getFilmId() == null) {
                throw new InvalidAmountException("PETICION_INVALIDA", "Debe proveer inventoryId o filmId");
            }
            // Auto-select inventory
            List<InventoryAvailability> availables = inventoryAvailabilityRepository.findAll().stream()
                .filter(ia -> ia.getFilm().getFilmId().intValue() == request.getFilmId() && ia.getAvailable())
                .collect(Collectors.toList());
            if (availables.isEmpty()) {
                throw new InsufficientStockException("No hay ejemplares disponibles para esta película");
            }
            inventoryId = availables.get(0).getInventoryId();
        }
        
        InventoryAvailability availability = inventoryAvailabilityRepository.findById(inventoryId)
                .orElseThrow(() -> new ResourceNotFoundException("El inventario no existe"));
                
        if (!availability.getAvailable()) {
            throw new CopyAlreadyRentedException("El ejemplar ya se encuentra alquilado o no disponible");
        }
        
        Inventory inventory = inventoryRepository.findById(inventoryId)
                .orElseThrow(() -> new ResourceNotFoundException("El inventario no existe"));

        if (!inventory.getFilm().getActive()) {
            throw new FilmUnavailableException("La película no está activa en el catálogo");
        }
                
        com.example.demo.models.Customer customer = customerRepository.findById(appUser.getCustomerId())
                .orElseThrow(() -> new ResourceNotFoundException("Perfil de cliente no encontrado en base de datos"));

        BigDecimal amount = inventory.getFilm().getRentalRate();
        if (amount == null) {
            throw new InvalidAmountException("CANTIDAD_INVALIDA", "La película no tiene una tarifa de alquiler configurada");
        }
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new InvalidAmountException("CANTIDAD_NEGATIVA", "La tarifa de alquiler no puede ser negativa");
        }
        if (amount.compareTo(BigDecimal.ZERO) == 0) {
            throw new InvalidAmountException("CANTIDAD_CERO", "La tarifa de alquiler no puede ser cero");
        }

        // Process payment FIRST
        String transactionRef;
        try {
            transactionRef = paymentGatewayService.processPayment(
                request.getCardNumber(), 
                request.getCardHolder(), 
                request.getExpirationDate(), 
                request.getCvv(), 
                amount
            );
            auditLogService.logEvent("INFO", "PURCHASE_CREATED", appUserId, "/api/rentals", "SUCCESS", "Amount: " + amount + ", Ref: " + transactionRef);
        } catch (PaymentDeclinedException e) {
            auditLogService.logEvent("WARN", "PAYMENT_DECLINED", appUserId, "/api/rentals", "FAILURE", "Reason: " + e.getMessage());
            throw e; // Rolls back the transaction
        }

        Rental rental = new Rental();
        rental.setRentalDate(LocalDateTime.now());
        rental.setReturnDate(null);
        rental.setInventory(inventory);
        rental.setCustomer(customer);
        rental.setStaff(null);
        
        rental = rentalRepository.save(rental);
        
        // Register payment
        Payment payment = new Payment();
        payment.setCustomer(customer);
        payment.setStaff(null);
        payment.setRental(rental);
        payment.setAmount(amount);
        payment.setPaymentDate(LocalDateTime.now());
        payment.setPaymentMethod("CARD");
        
        // Save only last 4 digits
        String last4 = request.getCardNumber().substring(request.getCardNumber().length() - 4);
        payment.setCardLast4(last4);
        payment.setTransactionRef(transactionRef);
        
        paymentRepository.save(payment);
        auditLogService.logEvent("INFO", "RENTAL_CREATED", appUserId, "/api/rentals", "SUCCESS", "Rental ID: " + rental.getRentalId() + ", Inventory ID: " + inventory.getInventoryId());
        
        // Set payments to rental manually so the DTO can map it immediately
        rental.setPayments(List.of(payment));
        
        return new RentalDTO(rental);
    }

    @Transactional(readOnly = true)
    public List<RentalDTO> getMyRentals(Long appUserId) {
        AppUser appUser = appUserRepository.findById(appUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
                
        if (appUser.getCustomerId() == null) {
            throw new AccessDeniedException("El usuario no tiene un perfil de cliente asociado");
        }
        
        return rentalRepository.findWithFilters(appUser.getCustomerId(), null, null).stream()
                .map(RentalDTO::new)
                .collect(Collectors.toList());
    }

    @Transactional
    public RentalDTO returnRental(Integer rentalId, Long appUserId, boolean isAdmin) {
        Rental rental = rentalRepository.findById(rentalId)
                .orElseThrow(() -> new ResourceNotFoundException("Alquiler no encontrado"));
                
        if (rental.getReturnDate() != null) {
            throw new DuplicateReturnException("El alquiler ya fue devuelto");
        }
        
        if (!isAdmin) {
            AppUser appUser = appUserRepository.findById(appUserId)
                    .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
            
            if (appUser.getCustomerId() == null || 
                !appUser.getCustomerId().equals(rental.getCustomer().getCustomerId())) {
                throw new AccessDeniedException("No tienes permiso para devolver este alquiler");
            }
        }
        
        rental.setReturnDate(LocalDateTime.now());
        rental = rentalRepository.save(rental);
        auditLogService.logEvent("INFO", "RENTAL_RETURNED", appUserId, "/api/rentals/return", "SUCCESS", "Alquiler devuelto: " + rentalId);
        
        return new RentalDTO(rental);
    }

    @Transactional
    public void deleteRental(Integer rentalId, Long appUserId) {
        Rental rental = rentalRepository.findById(rentalId)
                .orElseThrow(() -> new ResourceNotFoundException("Alquiler no encontrado"));
                
        // Cascades to Payment automatically because of CascadeType.ALL
        rentalRepository.delete(rental);
        
        auditLogService.logEvent("WARN", "RENTAL_DELETED", appUserId, "/api/rentals/" + rentalId, "SUCCESS", "Rental ID deleted: " + rentalId);
    }
}
