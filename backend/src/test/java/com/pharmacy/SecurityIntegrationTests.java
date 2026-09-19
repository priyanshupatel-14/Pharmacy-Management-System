package com.pharmacy;

import com.pharmacy.common.auth.AuthDao;
import com.pharmacy.common.auth.AuthService;
import com.pharmacy.common.auth.LoginRequest;
import com.pharmacy.common.auth.LoginResponse;
import com.pharmacy.common.auth.RegisterRequest;
import com.pharmacy.common.auth.TenantContext;
import com.pharmacy.common.auth.User;
import com.pharmacy.common.exception.BadRequestException;
import com.pharmacy.common.exception.ResourceNotFoundException;
import com.pharmacy.pharmacy.batch.MedicineBatch;
import com.pharmacy.pharmacy.batch.MedicineBatchController;
import com.pharmacy.pharmacy.medicine.Medicine;
import com.pharmacy.pharmacy.medicine.MedicineController;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class SecurityIntegrationTests {

    @Autowired
    private AuthService authService;

    @Autowired
    private AuthDao authDao;

    @Autowired
    private MedicineController medicineController;

    @Autowired
    private MedicineBatchController medicineBatchController;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    public void setup() {
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("TRUNCATE TABLE sale_items");
        jdbcTemplate.execute("TRUNCATE TABLE sales");
        jdbcTemplate.execute("TRUNCATE TABLE medicine_batches");
        jdbcTemplate.execute("TRUNCATE TABLE medicines");
        jdbcTemplate.execute("TRUNCATE TABLE suppliers");
        jdbcTemplate.execute("TRUNCATE TABLE sessions");
        jdbcTemplate.execute("TRUNCATE TABLE users");
        jdbcTemplate.execute("TRUNCATE TABLE pharmacies");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
        TenantContext.clear();
    }

    private void simulateLogin(String username, String password) {
        LoginRequest req = new LoginRequest();
        req.setUsername(username);
        req.setPassword(password);
        LoginResponse res = authService.login(req);
        User user = authDao.getUserByToken(res.getToken()).orElseThrow();
        TenantContext.setCurrentUser(user);
    }

    @Test
    public void testAuthenticationAndRegistration() {
        // 1. Valid Registration
        RegisterRequest req = new RegisterRequest();
        req.setUsername("adminA");
        req.setPassword("pass123");
        req.setFullName("Admin A");
        req.setPharmacyName("Pharmacy A");
        authService.register(req);

        simulateLogin("adminA", "pass123");
        assertNotNull(TenantContext.getCurrentUser());
        assertEquals("ADMIN", TenantContext.getCurrentUser().getRole());

        // 2. Duplicate Username Rejected
        RegisterRequest reqDup = new RegisterRequest();
        reqDup.setUsername("adminA");
        reqDup.setPassword("pass456");
        reqDup.setFullName("Admin A Dup");
        reqDup.setPharmacyName("Pharmacy Dup");

        assertThrows(BadRequestException.class, () -> authService.register(reqDup));

        // 3. Invalid Login (Bad password)
        LoginRequest badLogin = new LoginRequest();
        badLogin.setUsername("adminA");
        badLogin.setPassword("wrongpass");
        assertThrows(BadRequestException.class, () -> authService.login(badLogin));
    }

    @Test
    public void testTenantIsolationAndIDOR() {
        // Register Pharmacy A
        RegisterRequest reqA = new RegisterRequest();
        reqA.setUsername("adminA");
        reqA.setPassword("pass123");
        reqA.setFullName("Admin A");
        reqA.setPharmacyName("Pharmacy A");
        authService.register(reqA);

        // Register Pharmacy B
        RegisterRequest reqB = new RegisterRequest();
        reqB.setUsername("adminB");
        reqB.setPassword("pass123");
        reqB.setFullName("Admin B");
        reqB.setPharmacyName("Pharmacy B");
        authService.register(reqB);

        // Pharmacy A creates a medicine
        simulateLogin("adminA", "pass123");
        Medicine medA = new Medicine();
        medA.setName("MedA");
        medA.setUnitPrice(new BigDecimal("10.0"));
        Medicine createdMedA = medicineController.createMedicine(medA).getBody();
        assertNotNull(createdMedA);
        Long medIdA = createdMedA.getId();

        // Switch to Pharmacy B
        TenantContext.clear();
        simulateLogin("adminB", "pass123");

        // Pharmacy B attempts to create a batch for Pharmacy A's medicine (IDOR check)
        MedicineBatch batchB = new MedicineBatch();
        batchB.setMedicineId(medIdA);
        batchB.setBatchNumber("B-HACK");
        batchB.setQuantity(100);
        batchB.setExpiryDate(LocalDate.now().plusDays(30));

        assertThrows(ResourceNotFoundException.class, () -> medicineBatchController.createBatch(batchB));
    }

    @Test
    public void testRbac() {
        // Admin creates a pharmacist
        RegisterRequest reqAdmin = new RegisterRequest();
        reqAdmin.setUsername("adminRbac");
        reqAdmin.setPassword("pass123");
        reqAdmin.setFullName("Admin");
        reqAdmin.setPharmacyName("Pharmacy RBAC");
        authService.register(reqAdmin);

        simulateLogin("adminRbac", "pass123");

        User reqStaff = new User();
        reqStaff.setUsername("pharmacist1");
        reqStaff.setPassword("pass123");
        reqStaff.setFullName("Pharmacist User");
        reqStaff.setRole("PHARMACIST");
        reqStaff.setPharmacyId(TenantContext.getCurrentPharmacyId());
        // Since UserController is missing from tests package resolution or something, I'll bypass it for DB
        // Wait, I can just use authDao to create user to simulate another user in same pharmacy
        String hashedPassword = new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode("pass123");
        reqStaff.setPassword(hashedPassword);
        authDao.save(reqStaff);

        // Switch to Pharmacist
        TenantContext.clear();
        simulateLogin("pharmacist1", "pass123");

        // Pharmacist attempts to create medicine (Should fail)
        Medicine med = new Medicine();
        med.setName("Med1");
        med.setUnitPrice(new BigDecimal("10.0"));

        assertThrows(BadRequestException.class, () -> medicineController.createMedicine(med));
    }
}
