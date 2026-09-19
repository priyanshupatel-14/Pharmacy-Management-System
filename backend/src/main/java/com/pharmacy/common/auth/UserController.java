package com.pharmacy.common.auth;

import com.pharmacy.common.exception.BadRequestException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller to manage staff (users) for the current pharmacy.
 */
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final JdbcTemplate jdbcTemplate;
    private final BCryptPasswordEncoder passwordEncoder;

    public UserController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    private void requireAdmin() {
        if (!"ADMIN".equals(TenantContext.getCurrentUser().getRole())) {
            throw new BadRequestException("Only ADMIN can perform this action");
        }
    }

    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getStaff() {
        requireAdmin();
        Long pharmacyId = TenantContext.getCurrentPharmacyId();
        
        String sql = "SELECT id, username, full_name, role, created_at FROM users WHERE pharmacy_id = ? ORDER BY full_name";
        List<Map<String, Object>> users = jdbcTemplate.queryForList(sql, pharmacyId);
        
        return ResponseEntity.ok(users);
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> createStaff(@RequestBody RegisterRequest request) {
        requireAdmin();
        Long pharmacyId = TenantContext.getCurrentPharmacyId();

        if (request.getUsername() == null || request.getUsername().isBlank()) {
            throw new BadRequestException("Username is required");
        }
        if (request.getPassword() == null || request.getPassword().length() < 4) {
            throw new BadRequestException("Password must be at least 4 characters");
        }

        // Check if username already exists globally (username is unique across all tenants for now)
        String checkSql = "SELECT COUNT(*) FROM users WHERE username = ?";
        Integer count = jdbcTemplate.queryForObject(checkSql, Integer.class, request.getUsername());
        if (count != null && count > 0) {
            throw new BadRequestException("Username already exists");
        }

        String sql = "INSERT INTO users (pharmacy_id, username, password, full_name, role) VALUES (?, ?, ?, ?, ?) RETURNING id";
        String hashedPassword = passwordEncoder.encode(request.getPassword());
        String role = "PHARMACIST";
        if ("ADMIN".equals(request.getRole())) {
            role = "ADMIN";
        }

        Long newId = jdbcTemplate.queryForObject(sql, Long.class, 
                pharmacyId, 
                request.getUsername(), 
                hashedPassword, 
                request.getFullName(), 
                role);

        return ResponseEntity.ok(Map.of(
                "id", newId,
                "username", request.getUsername(),
                "fullName", request.getFullName(),
                "role", role
        ));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteStaff(@PathVariable Long id) {
        requireAdmin();
        Long pharmacyId = TenantContext.getCurrentPharmacyId();

        // Cannot delete self
        if (id.equals(TenantContext.getCurrentUser().getId())) {
            throw new BadRequestException("Cannot delete your own account");
        }

        String sql = "DELETE FROM users WHERE id = ? AND pharmacy_id = ?";
        jdbcTemplate.update(sql, id, pharmacyId);

        return ResponseEntity.ok().build();
    }
}
