package com.pharmacy.common.auth;

import com.pharmacy.common.exception.BadRequestException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

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

        // Generate a simple session token (UUID-based, appropriate for a college project)
        String token = UUID.randomUUID().toString();

        return new LoginResponse(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                user.getRole(),
                token
        );
    }

    /**
     * Register a new user.
     * Password is hashed with BCrypt before storage.
     */
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

        // Check for duplicate username
        if (authDao.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username already exists: " + request.getUsername());
        }

        // Hash password
        String hashedPassword = passwordEncoder.encode(request.getPassword());

        // Create user
        User user = new User();
        user.setUsername(request.getUsername());
        user.setPassword(hashedPassword);
        user.setFullName(request.getFullName());
        user.setRole(request.getRole() != null ? request.getRole() : "PHARMACIST");

        // Validate role
        if (!user.getRole().equals("ADMIN") && !user.getRole().equals("PHARMACIST")) {
            throw new BadRequestException("Role must be ADMIN or PHARMACIST");
        }

        user = authDao.save(user);

        // Generate token
        String token = UUID.randomUUID().toString();

        return new LoginResponse(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                user.getRole(),
                token
        );
    }
}
