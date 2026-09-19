package com.pharmacy.common.auth;

import com.pharmacy.common.exception.BadRequestException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

/**
 * Business logic for authentication.
 * Uses BCrypt for password hashing and a simple UUID token for sessions.
 */
@Service
public class AuthService {

    private final AuthDao authDao;
    private final BCryptPasswordEncoder passwordEncoder;

    public AuthService(AuthDao authDao) {
        this.authDao = authDao;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    /**
     * Authenticate a user with username and password.
     * Returns a LoginResponse with a session token if credentials are valid.
     */
    public LoginResponse login(LoginRequest request) {
        if (request.getUsername() == null || request.getUsername().isBlank()) {
            throw new BadRequestException("Username is required");
        }
        if (request.getPassword() == null || request.getPassword().isBlank()) {
            throw new BadRequestException("Password is required");
        }

        User user = authDao.findByUsername(request.getUsername())
                .orElseThrow(() -> new BadRequestException("Invalid username or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadRequestException("Invalid username or password");
        }

        // Generate a simple session token
        String token = UUID.randomUUID().toString();
        // Set expiry to 7 days from now
        Timestamp expiresAt = Timestamp.from(Instant.now().plus(7, ChronoUnit.DAYS));
        authDao.createSession(token, user.getId(), expiresAt);

        String pharmacyName = authDao.getPharmacyName(user.getPharmacyId());

        return new LoginResponse(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                user.getRole(),
                token,
                pharmacyName
        );
    }

    /**
     * Register a new user and a new pharmacy.
     * Password is hashed with BCrypt before storage.
     */
    @Transactional
    public LoginResponse register(RegisterRequest request) {
        if (request.getUsername() == null || request.getUsername().isBlank()) {
            throw new BadRequestException("Username is required");
        }
        if (request.getPassword() == null || request.getPassword().length() < 4) {
            throw new BadRequestException("Password must be at least 4 characters");
        }
        if (request.getFullName() == null || request.getFullName().isBlank()) {
            throw new BadRequestException("Full name is required");
        }
        if (request.getPharmacyName() == null || request.getPharmacyName().isBlank()) {
            throw new BadRequestException("Pharmacy name is required");
        }

        // Check for duplicate username
        if (authDao.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username already exists: " + request.getUsername());
        }

        // 1. Create Pharmacy
        Long pharmacyId = authDao.createPharmacy(
                request.getPharmacyName(),
                request.getFullName(),
                request.getPharmacyEmail(),
                request.getPharmacyPhone(),
                request.getPharmacyAddress()
        );

        // 2. Hash password
        String hashedPassword = passwordEncoder.encode(request.getPassword());

        // 3. Create user
        User user = new User();
        user.setPharmacyId(pharmacyId);
        user.setUsername(request.getUsername());
        user.setPassword(hashedPassword);
        user.setFullName(request.getFullName());
        user.setRole("ADMIN"); // New registrations are always ADMIN of their new pharmacy

        user = authDao.save(user);

        // 4. Generate token and session
        String token = UUID.randomUUID().toString();
        Timestamp expiresAt = Timestamp.from(Instant.now().plus(7, ChronoUnit.DAYS));
        authDao.createSession(token, user.getId(), expiresAt);

        return new LoginResponse(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                user.getRole(),
                token,
                request.getPharmacyName()
        );
    }
}
