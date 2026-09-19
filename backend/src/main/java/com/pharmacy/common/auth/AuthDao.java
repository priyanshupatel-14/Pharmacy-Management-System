package com.pharmacy.common.auth;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;

/**
 * Data Access Object for users table using JdbcTemplate.
 */
@Repository
public class AuthDao {

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<User> rowMapper = (rs, rowNum) -> {
        User u = new User();
        u.setId(rs.getLong("id"));
        u.setPharmacyId(rs.getLong("pharmacy_id"));
        u.setUsername(rs.getString("username"));
        u.setPassword(rs.getString("password"));
        u.setFullName(rs.getString("full_name"));
        u.setRole(rs.getString("role"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            u.setCreatedAt(ts.toLocalDateTime());
        }
        return u;
    };

    public AuthDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<User> findByUsername(String username) {
        String sql = "SELECT * FROM users WHERE username = ?";
        List<User> results = jdbcTemplate.query(sql, rowMapper, username);
        return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
    }

    public Optional<User> findById(Long id) {
        String sql = "SELECT * FROM users WHERE id = ?";
        List<User> results = jdbcTemplate.query(sql, rowMapper, id);
        return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
    }

    public boolean existsByUsername(String username) {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ?";
        Integer count = jdbcTemplate.queryForObject(sql, Integer.class, username);
        return count != null && count > 0;
    }

    public User save(User user) {
        String sql = "INSERT INTO users (pharmacy_id, username, password, full_name, role) VALUES (?, ?, ?, ?, ?)";
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, user.getPharmacyId());
            ps.setString(2, user.getUsername());
            ps.setString(3, user.getPassword());
            ps.setString(4, user.getFullName());
            ps.setString(5, user.getRole());
            return ps;
        }, keyHolder);

        var keys = keyHolder.getKeys();
        if (keys != null) {
            user.setId(((Number) keys.get("id")).longValue());
        }
        return user;
    }

    public void createSession(String token, Long userId, Timestamp expiresAt) {
        String sql = "INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)";
        jdbcTemplate.update(sql, token, userId, expiresAt);
    }

    public Optional<User> getUserByToken(String token) {
        String sql = "SELECT u.* FROM users u JOIN sessions s ON u.id = s.user_id WHERE s.token = ? AND s.expires_at > NOW()";
        List<User> results = jdbcTemplate.query(sql, rowMapper, token);
        return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
    }

    public Long createPharmacy(String name, String ownerName, String email, String phone, String address) {
        String sql = "INSERT INTO pharmacies (name, owner_name, email, phone, address, status) VALUES (?, ?, ?, ?, ?, 'ACTIVE')";
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, name);
            ps.setString(2, ownerName);
            ps.setString(3, email);
            ps.setString(4, phone);
            ps.setString(5, address);
            return ps;
        }, keyHolder);

        var keys = keyHolder.getKeys();
        if (keys != null) {
            return ((Number) keys.get("id")).longValue();
        }
        throw new RuntimeException("Failed to create pharmacy");
    }

    public String getPharmacyName(Long pharmacyId) {
        String sql = "SELECT name FROM pharmacies WHERE id = ?";
        List<String> results = jdbcTemplate.queryForList(sql, String.class, pharmacyId);
        return results.isEmpty() ? null : results.get(0);
    }
}
