package com.pharmacy.pharmacy.stock;

import com.pharmacy.common.exception.ResourceNotFoundException;
import com.pharmacy.pharmacy.batch.MedicineBatch;
import com.pharmacy.pharmacy.batch.MedicineBatchDao;
import com.pharmacy.pharmacy.medicine.Medicine;
import com.pharmacy.pharmacy.medicine.MedicineDao;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Service for stock queries. Stock data comes from medicine_batches.
 * This service does NOT have its own DAO — it uses MedicineBatchDao and MedicineDao.
 */
@Service
public class StockService {

    private final MedicineDao medicineDao;
    private final MedicineBatchDao batchDao;
    private final JdbcTemplate jdbcTemplate;

    public StockService(MedicineDao medicineDao, MedicineBatchDao batchDao, JdbcTemplate jdbcTemplate) {
        this.medicineDao = medicineDao;
        this.batchDao = batchDao;
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * Get stock summary for all medicines.
     */
    public List<StockInfo> getAllStock() {
        String sql = """
                SELECT m.id, m.name, m.category, COALESCE(SUM(mb.quantity), 0) AS total_stock
                FROM medicines m
                LEFT JOIN medicine_batches mb ON m.id = mb.medicine_id
                GROUP BY m.id, m.name, m.category
                ORDER BY m.name
                """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            StockInfo info = new StockInfo();
            info.setMedicineId(rs.getLong("id"));
            info.setMedicineName(rs.getString("name"));
            info.setCategory(rs.getString("category"));
            info.setTotalStock(rs.getInt("total_stock"));
            // Batches not included in summary view for performance
            return info;
        });
    }

    /**
     * Get detailed stock for a single medicine, including batch breakdown.
     */
    public StockInfo getStockByMedicine(Long medicineId) {
        Medicine medicine = medicineDao.findById(medicineId)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found with id: " + medicineId));

        List<MedicineBatch> batches = batchDao.findByMedicineId(medicineId);
        int totalStock = batchDao.getTotalStock(medicineId);

        return new StockInfo(
                medicine.getId(),
                medicine.getName(),
                medicine.getCategory(),
                totalStock,
                batches
        );
    }

    /**
     * Get medicines with stock below a given threshold.
     */
    public List<StockInfo> getLowStock(int threshold) {
        String sql = """
                SELECT m.id, m.name, m.category, COALESCE(SUM(mb.quantity), 0) AS total_stock
                FROM medicines m
                LEFT JOIN medicine_batches mb ON m.id = mb.medicine_id
                GROUP BY m.id, m.name, m.category
                HAVING COALESCE(SUM(mb.quantity), 0) < ?
                ORDER BY total_stock ASC
                """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            StockInfo info = new StockInfo();
            info.setMedicineId(rs.getLong("id"));
            info.setMedicineName(rs.getString("name"));
            info.setCategory(rs.getString("category"));
            info.setTotalStock(rs.getInt("total_stock"));
            return info;
        }, threshold);
    }
}
