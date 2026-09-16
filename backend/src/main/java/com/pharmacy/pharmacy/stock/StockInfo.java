package com.pharmacy.pharmacy.stock;

import com.pharmacy.pharmacy.batch.MedicineBatch;

import java.util.List;

/**
 * DTO that presents stock information for a medicine.
 * Combines medicine details with aggregated batch/stock data.
 */
public class StockInfo {

    private Long medicineId;
    private String medicineName;
    private String category;
    private int totalStock;
    private List<MedicineBatch> batches;

    public StockInfo() {
    }

    public StockInfo(Long medicineId, String medicineName, String category, int totalStock, List<MedicineBatch> batches) {
        this.medicineId = medicineId;
        this.medicineName = medicineName;
        this.category = category;
        this.totalStock = totalStock;
        this.batches = batches;
    }

    // Getters and setters

    public Long getMedicineId() {
        return medicineId;
    }

    public void setMedicineId(Long medicineId) {
        this.medicineId = medicineId;
    }

    public String getMedicineName() {
        return medicineName;
    }

    public void setMedicineName(String medicineName) {
        this.medicineName = medicineName;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public int getTotalStock() {
        return totalStock;
    }

    public void setTotalStock(int totalStock) {
        this.totalStock = totalStock;
    }

    public List<MedicineBatch> getBatches() {
        return batches;
    }

    public void setBatches(List<MedicineBatch> batches) {
        this.batches = batches;
    }
}
