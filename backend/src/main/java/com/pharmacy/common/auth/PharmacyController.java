package com.pharmacy.common.auth;

import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Controller to fetch the current pharmacy profile for the logged-in user.
 */
@RestController
@RequestMapping("/api/pharmacy")
public class PharmacyController {

    private final JdbcTemplate jdbcTemplate;

    public PharmacyController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> getMyPharmacy() {
        Long pharmacyId = TenantContext.getCurrentPharmacyId();
        if (pharmacyId == null) {
            return ResponseEntity.status(401).build();
        }

        String sql = "SELECT id, name, owner_name, email, phone, address, status FROM pharmacies WHERE id = ?";
        Map<String, Object> pharmacy = jdbcTemplate.queryForMap(sql, pharmacyId);

        return ResponseEntity.ok(pharmacy);
    }
}
