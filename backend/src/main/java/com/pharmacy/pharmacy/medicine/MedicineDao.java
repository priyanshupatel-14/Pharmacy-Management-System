package com.pharmacy.pharmacy.medicine;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.List;
import java.util.Optional;
import com.pharmacy.common.auth.TenantContext;

/**
 * Data Access Object for medicines table using JdbcTemplate.
 */
@Repository
public class MedicineDao {

    private final JdbcTemplate jdbcTemplate;

    /**
     * RowMapper that includes supplier name via LEFT JOIN.
     */
    private final RowMapper<Medicine> rowMapper = (rs, rowNum) -> {
        Medicine m = new Medicine();
        m.setId(rs.getLong("id"));
        m.setName(rs.getString("name"));
        m.setCategory(rs.getString("category"));
        m.setManufacturer(rs.getString("manufacturer"));
        m.setUnitPrice(rs.getBigDecimal("unit_price"));
        long supplierId = rs.getLong("supplier_id");
        m.setSupplierId(rs.wasNull() ? null : supplierId);
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            m.setCreatedAt(ts.toLocalDateTime());
        }
        // supplier_name comes from LEFT JOIN — may not be present in all queries
        try {
            m.setSupplierName(rs.getString("supplier_name"));
        } catch (Exception e) {
            // Column not present — that's fine
        }
        return m;
    };

    public MedicineDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<Medicine> findAll() {
        String sql = """
                SELECT m.*, s.name AS supplier_name
                FROM medicines m
                LEFT JOIN suppliers s ON m.supplier_id = s.id
                WHERE m.pharmacy_id = ?
                ORDER BY m.name
                """;
        return jdbcTemplate.query(sql, rowMapper, TenantContext.getCurrentPharmacyId());
    }

    public Optional<Medicine> findById(Long id) {
        String sql = """
                SELECT m.*, s.name AS supplier_name
                FROM medicines m
                LEFT JOIN suppliers s ON m.supplier_id = s.id
                WHERE m.id = ? AND m.pharmacy_id = ?
                """;
        List<Medicine> results = jdbcTemplate.query(sql, rowMapper, id, TenantContext.getCurrentPharmacyId());
        return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
    }

    public List<Medicine> searchByName(String query) {
        String sql = """
                SELECT m.*, s.name AS supplier_name
                FROM medicines m
                LEFT JOIN suppliers s ON m.supplier_id = s.id
                WHERE LOWER(m.name) LIKE LOWER(?) AND m.pharmacy_id = ?
                ORDER BY m.name
                """;
        return jdbcTemplate.query(sql, rowMapper, "%" + query + "%", TenantContext.getCurrentPharmacyId());
    }

    public Medicine save(Medicine medicine) {
        String sql = "INSERT INTO medicines (pharmacy_id, name, category, manufacturer, unit_price, supplier_id) VALUES (?, ?, ?, ?, ?, ?)";
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, TenantContext.getCurrentPharmacyId());
            ps.setString(2, medicine.getName());
            ps.setString(3, medicine.getCategory());
            ps.setString(4, medicine.getManufacturer());
            ps.setBigDecimal(5, medicine.getUnitPrice());
            if (medicine.getSupplierId() != null) {
                ps.setLong(6, medicine.getSupplierId());
            } else {
                ps.setNull(6, Types.BIGINT);
            }
            return ps;
        }, keyHolder);

        var keys = keyHolder.getKeys();
        if (keys != null) {
            medicine.setId(((Number) keys.get("id")).longValue());
        }
        return medicine;
    }

    public int update(Medicine medicine) {
        String sql = "UPDATE medicines SET name = ?, category = ?, manufacturer = ?, unit_price = ?, supplier_id = ? WHERE id = ? AND pharmacy_id = ?";
        return jdbcTemplate.update(sql,
                medicine.getName(),
                medicine.getCategory(),
                medicine.getManufacturer(),
                medicine.getUnitPrice(),
                medicine.getSupplierId(),
                medicine.getId(),
                TenantContext.getCurrentPharmacyId());
    }

    public int deleteById(Long id) {
        String sql = "DELETE FROM medicines WHERE id = ? AND pharmacy_id = ?";
        return jdbcTemplate.update(sql, id, TenantContext.getCurrentPharmacyId());
    }

    /**
     * Check if a medicine has any batches with stock remaining.
     */
    public boolean hasActiveBatches(Long medicineId) {
        String sql = """
                SELECT COUNT(*) FROM medicine_batches mb 
                JOIN medicines m ON mb.medicine_id = m.id 
                WHERE mb.medicine_id = ? AND mb.quantity > 0 AND m.pharmacy_id = ?
                """;
        Integer count = jdbcTemplate.queryForObject(sql, Integer.class, medicineId, TenantContext.getCurrentPharmacyId());
        return count != null && count > 0;
    }
}
