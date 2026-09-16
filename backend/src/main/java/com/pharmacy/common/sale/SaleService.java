package com.pharmacy.common.sale;

import com.pharmacy.common.exception.BadRequestException;
import com.pharmacy.common.exception.InsufficientStockException;
import com.pharmacy.common.exception.ResourceNotFoundException;
import com.pharmacy.pharmacy.batch.MedicineBatch;
import com.pharmacy.pharmacy.batch.MedicineBatchDao;
import com.pharmacy.pharmacy.medicine.Medicine;
import com.pharmacy.pharmacy.medicine.MedicineDao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Business logic for sales and billing.
 * Handles stock validation, price calculation, and stock reduction.
 */
@Service
public class SaleService {

    private final SaleDao saleDao;
    private final MedicineBatchDao batchDao;
    private final MedicineDao medicineDao;

    public SaleService(SaleDao saleDao, MedicineBatchDao batchDao, MedicineDao medicineDao) {
        this.saleDao = saleDao;
        this.batchDao = batchDao;
        this.medicineDao = medicineDao;
    }

    public List<Sale> getAllSales() {
        return saleDao.findAll();
    }

    public Sale getSaleById(Long id) {
        Sale sale = saleDao.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Sale not found with id: " + id));
        // Load items
        sale.setItems(saleDao.findItemsBySaleId(id));
        return sale;
    }

    /**
     * Creates a new sale:
     * 1. Validates the request (items present, quantities positive)
     * 2. Validates each batch exists, is not expired, and has sufficient stock
     * 3. Looks up the medicine's unit_price for each batch
     * 4. Calculates subtotals and total
     * 5. Saves the sale and items
     * 6. Reduces batch quantities
     */
    @Transactional
    public Sale createSale(SaleRequest request) {
        // Validate request
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new BadRequestException("Sale must contain at least one item");
        }

        BigDecimal totalAmount = BigDecimal.ZERO;

        // Create sale header (total will be updated after calculation)
        Sale sale = new Sale();
        sale.setUserId(request.getUserId());
        sale.setTotalAmount(BigDecimal.ZERO); // placeholder

        // Validate all items BEFORE making any changes
        for (SaleRequest.SaleItemRequest itemReq : request.getItems()) {
            if (itemReq.getBatchId() == null) {
                throw new BadRequestException("Batch ID is required for each item");
            }
            if (itemReq.getQuantity() == null || itemReq.getQuantity() <= 0) {
                throw new BadRequestException("Quantity must be greater than zero for each item");
            }

            // Verify batch exists
            MedicineBatch batch = batchDao.findById(itemReq.getBatchId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Batch not found with id: " + itemReq.getBatchId()));

            // Check if batch is expired
            if (batch.getExpiryDate().isBefore(LocalDate.now())) {
                throw new BadRequestException(
                        "Cannot sell from expired batch: " + batch.getBatchNumber()
                        + " (expired: " + batch.getExpiryDate() + ")");
            }

            // Check sufficient stock
            if (batch.getQuantity() < itemReq.getQuantity()) {
                throw new InsufficientStockException(
                        "Insufficient stock for batch " + batch.getBatchNumber()
                        + ". Available: " + batch.getQuantity()
                        + ", Requested: " + itemReq.getQuantity());
            }
        }

        // All validations passed — save sale header
        sale = saleDao.saveSale(sale);

        // Process each item: calculate price, save item, reduce stock
        for (SaleRequest.SaleItemRequest itemReq : request.getItems()) {
            MedicineBatch batch = batchDao.findById(itemReq.getBatchId()).orElseThrow();

            // Get medicine price
            Medicine medicine = medicineDao.findById(batch.getMedicineId()).orElseThrow();
            BigDecimal unitPrice = medicine.getUnitPrice();

            // Calculate subtotal
            BigDecimal subtotal = unitPrice.multiply(BigDecimal.valueOf(itemReq.getQuantity()));
            totalAmount = totalAmount.add(subtotal);

            // Save sale item
            SaleItem saleItem = new SaleItem();
            saleItem.setSaleId(sale.getId());
            saleItem.setBatchId(itemReq.getBatchId());
            saleItem.setQuantity(itemReq.getQuantity());
            saleItem.setUnitPrice(unitPrice);
            saleItem.setSubtotal(subtotal);
            saleDao.saveSaleItem(saleItem);

            // Reduce batch stock
            int updated = batchDao.reduceQuantity(itemReq.getBatchId(), itemReq.getQuantity());
            if (updated == 0) {
                // This shouldn't happen since we validated above, but safety check
                throw new InsufficientStockException(
                        "Failed to reduce stock for batch " + batch.getBatchNumber());
            }
        }

        // Update sale total
        sale.setTotalAmount(totalAmount);
        // Update the total in the database
        updateSaleTotal(sale.getId(), totalAmount);

        // Return full sale with items
        return getSaleById(sale.getId());
    }

    private void updateSaleTotal(Long saleId, BigDecimal total) {
        saleDao.updateTotal(saleId, total);
    }
}
