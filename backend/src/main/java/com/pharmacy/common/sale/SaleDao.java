package com.pharmacy.common.sale;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.List;
import java.util.Optional;

/**
 * Data Access Object for sales and sale_items tables using JdbcTemplate.
 */
@Repository
public class SaleDao {

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<Sale> saleRowMapper = (rs, rowNum) -> {
        Sale s = new Sale();
        s.setId(rs.getLong("id"));
        long userId = rs.getLong("user_id");
        s.setUserId(rs.wasNull() ? null : userId);
        s.setTotalAmount(rs.getBigDecimal("total_amount"));
        Timestamp ts = rs.getTimestamp("sale_date");
        if (ts != null) {
            s.setSaleDate(ts.toLocalDateTime());
        }
        try {
            s.setUserName(rs.getString("user_name"));
        } catch (Exception e) {
            // Column not present
        }
        return s;
    };

    private final RowMapper<SaleItem> itemRowMapper = (rs, rowNum) -> {
        SaleItem si = new SaleItem();
        si.setId(rs.getLong("id"));
        si.setSaleId(rs.getLong("sale_id"));
        si.setBatchId(rs.getLong("batch_id"));
        si.setQuantity(rs.getInt("quantity"));
        si.setUnitPrice(rs.getBigDecimal("unit_price"));
        si.setSubtotal(rs.getBigDecimal("subtotal"));
        try {
            si.setMedicineName(rs.getString("medicine_name"));
        } catch (Exception e) {
            // Column not present
        }
        try {
            si.setBatchNumber(rs.getString("batch_number"));
        } catch (Exception e) {
            // Column not present
        }
        return si;
    };

    public SaleDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<Sale> findAll() {
        String sql = """
                SELECT s.*, u.full_name AS user_name
                FROM sales s
                LEFT JOIN users u ON s.user_id = u.id
                ORDER BY s.sale_date DESC
                """;
        return jdbcTemplate.query(sql, saleRowMapper);
    }

    public Optional<Sale> findById(Long id) {
        String sql = """
                SELECT s.*, u.full_name AS user_name
                FROM sales s
                LEFT JOIN users u ON s.user_id = u.id
                WHERE s.id = ?
                """;
        List<Sale> results = jdbcTemplate.query(sql, saleRowMapper, id);
        return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
    }

    public List<SaleItem> findItemsBySaleId(Long saleId) {
        String sql = """
                SELECT si.*, m.name AS medicine_name, mb.batch_number
                FROM sale_items si
                JOIN medicine_batches mb ON si.batch_id = mb.id
                JOIN medicines m ON mb.medicine_id = m.id
                WHERE si.sale_id = ?
                ORDER BY si.id
                """;
        return jdbcTemplate.query(sql, itemRowMapper, saleId);
    }

    public Sale saveSale(Sale sale) {
        String sql = "INSERT INTO sales (user_id, total_amount) VALUES (?, ?)";
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            if (sale.getUserId() != null) {
                ps.setLong(1, sale.getUserId());
            } else {
                ps.setNull(1, Types.BIGINT);
            }
            ps.setBigDecimal(2, sale.getTotalAmount());
            return ps;
        }, keyHolder);

        var keys = keyHolder.getKeys();
        if (keys != null) {
            sale.setId(((Number) keys.get("id")).longValue());
        }
        return sale;
    }

    public void saveSaleItem(SaleItem item) {
        String sql = "INSERT INTO sale_items (sale_id, batch_id, quantity, unit_price, subtotal) VALUES (?, ?, ?, ?, ?)";
        jdbcTemplate.update(sql,
                item.getSaleId(),
                item.getBatchId(),
                item.getQuantity(),
                item.getUnitPrice(),
                item.getSubtotal());
    }

    public void updateTotal(Long saleId, BigDecimal total) {
        String sql = "UPDATE sales SET total_amount = ? WHERE id = ?";
        jdbcTemplate.update(sql, total, saleId);
    }
}

