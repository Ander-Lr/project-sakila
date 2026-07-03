package com.example.demo.services;

import com.example.demo.models.AppUser;
import com.example.demo.models.Customer;
import com.example.demo.models.Staff;
import com.example.demo.models.Store;
import com.example.demo.models.Address;
import com.example.demo.repositories.AppUserRepository;
import com.example.demo.repositories.CustomerRepository;
import com.example.demo.repositories.StaffRepository;
import com.example.demo.repositories.StoreRepository;
import com.example.demo.repositories.AddressRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MigrationService {

    private final AppUserRepository appUserRepository;
    private final CustomerRepository customerRepository;
    private final StaffRepository staffRepository;
    private final StoreRepository storeRepository;
    private final AddressRepository addressRepository;

    @Transactional
    public int migrateUsers() {
        List<AppUser> users = appUserRepository.findAll();
        int migratedCount = 0;
        
        Store defaultStore = storeRepository.findById((short) 1)
                .orElseThrow(() -> new IllegalStateException("Store por defecto no encontrada"));
        Address defaultAddress = addressRepository.findById((short) 1)
                .orElseThrow(() -> new IllegalStateException("Address por defecto no encontrada"));

        for (AppUser user : users) {
            boolean isAdmin = user.getEmail() != null && user.getEmail().endsWith("@espe.edu.ec");
            boolean needsMigration = false;
            
            // Check if we need to promote an existing CUSTOMER to ADMIN
            if (isAdmin && user.getRole() == AppUser.Role.CUSTOMER) {
                user.setRole(AppUser.Role.ADMIN);
                needsMigration = true;
            }
            
            // Check if staff/customer records are missing
            if (isAdmin && user.getStaffId() == null) {
                needsMigration = true;
            } else if (!isAdmin && user.getCustomerId() == null) {
                needsMigration = true;
            }

            if (needsMigration) {
                String[] nameParts = user.getFullName().split(" ", 2);
                String firstName = nameParts[0];
                String lastName = nameParts.length > 1 ? nameParts[1] : "";

                if (isAdmin) {
                    if (user.getStaffId() == null) {
                        Staff staff = new Staff();
                        staff.setFirstName(firstName);
                        staff.setLastName(lastName);
                        staff.setEmail(user.getEmail());
                        staff.setStore(defaultStore);
                        staff.setAddress(defaultAddress);
                        staff = staffRepository.save(staff);
                        user.setStaffId(staff.getStaffId());
                    }
                    // If promoted from CUSTOMER, we could optionally nullify customerId but let's just keep it or remove it.
                    // The business rule implies exclusivity. Let's nullify it if they have one.
                    user.setCustomerId(null); 
                } else {
                    if (user.getCustomerId() == null) {
                        Customer customer = new Customer();
                        customer.setFirstName(firstName);
                        customer.setLastName(lastName);
                        customer.setEmail(user.getEmail());
                        customer.setStore(defaultStore);
                        customer.setAddress(defaultAddress);
                        customer = customerRepository.save(customer);
                        user.setCustomerId(customer.getCustomerId());
                    }
                }
                appUserRepository.save(user);
                migratedCount++;
            }
        }
        return migratedCount;
    }
}
