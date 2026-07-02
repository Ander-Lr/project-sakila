package com.example.demo.models.dto;

import com.example.demo.models.Rental;
import lombok.Data;
import java.time.LocalDateTime;
import java.math.BigDecimal;

@Data
public class RentalDTO {
    private Integer rentalId;
    private LocalDateTime rentalDate;
    private LocalDateTime returnDate;
    private Integer inventoryId;
    private String filmTitle;
    private String customerName;
    private String staffName;
    private BigDecimal paymentAmount;
    private String paymentMethod;
    private String cardLast4;
    private String transactionRef;

    public RentalDTO(Rental rental) {
        this.rentalId = rental.getRentalId();
        this.rentalDate = rental.getRentalDate();
        this.returnDate = rental.getReturnDate();
        this.inventoryId = rental.getInventory().getInventoryId();
        this.filmTitle = rental.getInventory().getFilm().getTitle();
        this.customerName = rental.getCustomer().getFirstName() + " " + rental.getCustomer().getLastName();
        this.staffName = rental.getStaff() != null ? 
                         rental.getStaff().getFirstName() + " " + rental.getStaff().getLastName() : 
                         "Auto-Servicio";
        if (rental.getPayments() != null && !rental.getPayments().isEmpty()) {
            var payment = rental.getPayments().get(0);
            this.paymentAmount = payment.getAmount();
            this.paymentMethod = payment.getPaymentMethod();
            this.cardLast4 = payment.getCardLast4();
            this.transactionRef = payment.getTransactionRef();
        }
    }
}
