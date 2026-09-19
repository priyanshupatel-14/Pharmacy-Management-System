package com.pharmacy.pharmacy.batch;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import com.pharmacy.common.auth.TenantContext;
import com.pharmacy.common.exception.ResourceNotFoundException;

/**
 * Data Access Object for medicine_batches table using JdbcTemplate.
 */
@Repository
public class MedicineBatchDao {

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<MedicineBatch> rowMapper = (rs, rowNum) -> {
        MedicineBatch b = new MedicineBatch();
        b.setId(rs.getLong("id"));
        b.setMedicineId(rs.getLong("medicine_id"));
        b.setBatchNumber(rs.getString("batch_number"));
        Date expiryDate = rs.getDate("expiry_date");
        if (expiryDate != null) {
            b.setExpiryDate(expiryDate.toLocalDate());
        }
        b.setQuantity(rs.getInt("quantity"));
        b.setPurchasePrice(rs.getBigDecimal("purchase_price"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            b.setCreatedAt(ts.toLocalDateTime());
        }
        try {
            b.setMedicineName(rs.getString("medicine_name"));
        } catch (Exception e) {
            // Column not present
        }
        return b;
    };

    public MedicineBatchDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<MedicineBatch> findAll() {
        String sql = """
                SELECT mb.*, m.name AS medicine_name
                FROM medicine_batches mb
                JOIN medicines m ON mb.medicine_id = m.id
                WHERE m.pharmacy_id = ?
                ORDER BY mb.expiry_date
                """;
        return jdbcTemplate.query(sql, rowMapper, TenantContext.getCurrentPharmacyId());
    }

    public Optional<MedicineBatch> findById(Long id) {
        String sql = """
                SELECT mb.*, m.name AS medicine_name
                FROM medicine_batches mb
                JOIN medicines m ON mb.medicine_id = m.id
                WHERE mb.id = ? AND m.pharmacy_id = ?
                """;
        List<MedicineBatch> results = jdbcTemplate.query(sql, rowMapper, id, TenantContext.getCurrentPharmacyId());
        return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
    }

    public List<MedicineBatch> findByMedicineId(Long medicineId) {
        String sql = """
                SELECT mb.*, m.name AS medicine_name
                FROM medicine_batches mb
                JOIN medicines m ON mb.medicine_id = m.id
                WHERE mb.medicine_id = ? AND m.pharmacy_id = ?
                ORDER BY mb.expiry_date
                """;
        return jdbcTemplate.query(sql, rowMapper, medicineId, TenantContext.getCurrentPharmacyId());
    }

    public List<MedicineBatch> findExpired() {
        String sql = """
                SELECT mb.*, m.name AS medicine_name
                FROM medicine_batches mb
                JOIN medicines m ON mb.medicine_id = m.id
                WHERE mb.expiry_date < CURRENT_DATE AND m.pharmacy_id = ?
                ORDER BY mb.expiry_date
                """;
        return jdbcTemplate.query(sql, rowMapper, TenantContext.getCurrentPharmacyId());
    }

    public List<MedicineBatch> findExpiringSoon(int days) {
        String sql = """
                SELECT mb.*, m.name AS medicine_name
                FROM medicine_batches mb
                JOIN medicines m ON mb.medicine_id = m.id
                WHERE mb.expiry_date >= CURRENT_DATE AND mb.expiry_date <= DATEADD('DAY', ?, CURRENT_DATE) AND m.pharmacy_id = ?
                ORDER BY mb.expiry_date
                """;
        return jdbcTemplate.query(sql, rowMapper, days, TenantContext.getCurrentPharmacyId());
    }

    public MedicineBatch save(MedicineBatch batch) {
        // verify medicine ownership for security
        String verifySql = "SELECT COUNT(*) FROM medicines WHERE id = ? AND pharmacy_id = ?";
        Integer count = jdbcTemplate.queryForObject(verifySql, Integer.class, batch.getMedicineId(), TenantContext.getCurrentPharmacyId());
        if (count == null || count == 0) {
            throw new ResourceNotFoundException("Medicine not found or access denied");
        }

        String sql = "INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES (?, ?, ?, ?, ?)";
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, batch.getMedicineId());
            ps.setString(2, batch.getBatchNumber());
            ps.setDate(3, Date.valueOf(batch.getExpiryDate()));
            ps.setInt(4, batch.getQuantity());
            if (batch.getPurchasePrice() != null) {
                ps.setBigDecimal(5, batch.getPurchasePrice());
            } else {
                ps.setNull(5, Types.DECIMAL);
            }
            return ps;
        }, keyHolder);

        var keys = keyHolder.getKeys();
        if (keys != null) {
            batch.setId(((Number) keys.get("id")).longValue());
        }
        return batch;
    }

    public int update(MedicineBatch batch) {
        // verify ownership via subquery for security
        String sql = "UPDATE medicine_batches SET batch_number = ?, expiry_date = ?, quantity = ?, purchase_price = ? WHERE id = ? AND medicine_id IN (SELECT id FROM medicines WHERE pharmacy_id = ?)";
        return jdbcTemplate.update(sql,
                batch.getBatchNumber(),
                Date.valueOf(batch.getExpiryDate()),
                batch.getQuantity(),
                batch.getPurchasePrice(),
                batch.getId(),
                TenantContext.getCurrentPharmacyId());
    }

    public int deleteById(Long id) {
        String sql = "DELETE FROM medicine_batches WHERE id = ? AND medicine_id IN (SELECT id FROM medicines WHERE pharmacy_id = ?)";
        return jdbcTemplate.update(sql, id, TenantContext.getCurrentPharmacyId());
    }

    /**
     * Reduce quantity of a batch. Used during sales.
     */
    public int reduceQuantity(Long batchId, int amount) {
        String sql = "UPDATE medicine_batches SET quantity = quantity - ? WHERE id = ? AND quantity >= ? AND medicine_id IN (SELECT id FROM medicines WHERE pharmacy_id = ?)";
        return jdbcTemplate.update(sql, amount, batchId, amount, TenantContext.getCurrentPharmacyId());
    }

    /**
     * Get total stock for a medicine across all batches.
     */
    public int getTotalStock(Long medicineId) {
        String sql = "SELECT COALESCE(SUM(quantity), 0) FROM medicine_batches mb JOIN medicines m ON mb.medicine_id = m.id WHERE mb.medicine_id = ? AND m.pharmacy_id = ?";
        Integer total = jdbcTemplate.queryForObject(sql, Integer.class, medicineId, TenantContext.getCurrentPharmacyId());
        return total != null ? total : 0;
    }

    /**
     * Find non-expired batches with stock for a medicine, ordered by expiry date (FEFO).
     */
    public List<MedicineBatch> findAvailableBatches(Long medicineId) {
        String sql = """
                SELECT mb.*, m.name AS medicine_name
                FROM medicine_batches mb
                JOIN medicines m ON mb.medicine_id = m.id
                WHERE mb.medicine_id = ? AND mb.quantity > 0 AND mb.expiry_date >= CURRENT_DATE AND m.pharmacy_id = ?
                ORDER BY mb.expiry_date ASC
                """;
        return jdbcTemplate.query(sql, rowMapper, medicineId, TenantContext.getCurrentPharmacyId());
    }
}
