package com.pharmacy.pharmacy.batch;

import com.pharmacy.common.exception.BadRequestException;
import com.pharmacy.common.exception.ResourceNotFoundException;
import com.pharmacy.pharmacy.medicine.MedicineDao;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Business logic for medicine batch and expiry operations.
 */
@Service
public class MedicineBatchService {

    private final MedicineBatchDao batchDao;
    private final MedicineDao medicineDao;

    public MedicineBatchService(MedicineBatchDao batchDao, MedicineDao medicineDao) {
        this.batchDao = batchDao;
        this.medicineDao = medicineDao;
    }

    public List<MedicineBatch> getAllBatches() {
        return batchDao.findAll();
    }

    public MedicineBatch getBatchById(Long id) {
        return batchDao.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Batch not found with id: " + id));
    }

    public List<MedicineBatch> getBatchesByMedicine(Long medicineId) {
        // Verify medicine exists
        medicineDao.findById(medicineId)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found with id: " + medicineId));
        return batchDao.findByMedicineId(medicineId);
    }

    public List<MedicineBatch> getExpiredBatches() {
        return batchDao.findExpired();
    }

    public List<MedicineBatch> getExpiringSoonBatches(int days) {
        if (days <= 0) {
            throw new BadRequestException("Days must be greater than zero");
        }
        return batchDao.findExpiringSoon(days);
    }

    public MedicineBatch createBatch(MedicineBatch batch) {
        validateBatch(batch);

        // Verify medicine exists
        medicineDao.findById(batch.getMedicineId())
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found with id: " + batch.getMedicineId()));

        return batchDao.save(batch);
    }

    public MedicineBatch updateBatch(Long id, MedicineBatch batch) {
        // Verify batch exists
        getBatchById(id);

        validateBatch(batch);
        batch.setId(id);
        batchDao.update(batch);
        return getBatchById(id);
    }

    public void deleteBatch(Long id) {
        MedicineBatch batch = getBatchById(id);

        if (batch.getQuantity() > 0) {
            throw new BadRequestException("Cannot delete batch with remaining stock (quantity: " + batch.getQuantity() + ")");
        }

        batchDao.deleteById(id);
    }

    private void validateBatch(MedicineBatch batch) {
        if (batch.getMedicineId() == null) {
            throw new BadRequestException("Medicine ID is required");
        }
        if (batch.getBatchNumber() == null || batch.getBatchNumber().isBlank()) {
            throw new BadRequestException("Batch number is required");
        }
        if (batch.getExpiryDate() == null) {
            throw new BadRequestException("Expiry date is required");
        }
        if (batch.getQuantity() == null || batch.getQuantity() < 0) {
            throw new BadRequestException("Quantity must be zero or positive");
        }
    }
}
