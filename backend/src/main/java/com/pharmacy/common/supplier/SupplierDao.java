package com.pharmacy.common.supplier;

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
import com.pharmacy.common.auth.TenantContext;

/**
 * Data Access Object for suppliers table using JdbcTemplate.
 */
@Repository
public class SupplierDao {

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<Supplier> rowMapper = (rs, rowNum) -> {
        Supplier s = new Supplier();
        s.setId(rs.getLong("id"));
        s.setName(rs.getString("name"));
        s.setPhone(rs.getString("phone"));
        s.setEmail(rs.getString("email"));
        s.setAddress(rs.getString("address"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            s.setCreatedAt(ts.toLocalDateTime());
        }
        return s;
    };

    public SupplierDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<Supplier> findAll() {
        String sql = "SELECT * FROM suppliers WHERE pharmacy_id = ? ORDER BY name";
        return jdbcTemplate.query(sql, rowMapper, TenantContext.getCurrentPharmacyId());
    }

    public Optional<Supplier> findById(Long id) {
        String sql = "SELECT * FROM suppliers WHERE id = ? AND pharmacy_id = ?";
        List<Supplier> results = jdbcTemplate.query(sql, rowMapper, id, TenantContext.getCurrentPharmacyId());
        return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
    }

    public Supplier save(Supplier supplier) {
        String sql = "INSERT INTO suppliers (pharmacy_id, name, phone, email, address) VALUES (?, ?, ?, ?, ?)";
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, TenantContext.getCurrentPharmacyId());
            ps.setString(2, supplier.getName());
            ps.setString(3, supplier.getPhone());
            ps.setString(4, supplier.getEmail());
            ps.setString(5, supplier.getAddress());
            return ps;
        }, keyHolder);

        var keys = keyHolder.getKeys();
        if (keys != null) {
            supplier.setId(((Number) keys.get("id")).longValue());
        }
        return supplier;
    }

    public int update(Supplier supplier) {
        String sql = "UPDATE suppliers SET name = ?, phone = ?, email = ?, address = ? WHERE id = ? AND pharmacy_id = ?";
        return jdbcTemplate.update(sql,
                supplier.getName(),
                supplier.getPhone(),
                supplier.getEmail(),
                supplier.getAddress(),
                supplier.getId(),
                TenantContext.getCurrentPharmacyId());
    }

    public int deleteById(Long id) {
        String sql = "DELETE FROM suppliers WHERE id = ? AND pharmacy_id = ?";
        return jdbcTemplate.update(sql, id, TenantContext.getCurrentPharmacyId());
    }
}
