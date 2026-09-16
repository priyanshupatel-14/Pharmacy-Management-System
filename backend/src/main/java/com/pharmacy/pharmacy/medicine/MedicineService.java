package com.pharmacy.pharmacy.medicine;

import com.pharmacy.common.exception.BadRequestException;
import com.pharmacy.common.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Business logic for medicine operations.
 */
@Service
public class MedicineService {

    private final MedicineDao medicineDao;

    public MedicineService(MedicineDao medicineDao) {
        this.medicineDao = medicineDao;
    }

    public List<Medicine> getAllMedicines() {
        return medicineDao.findAll();
    }

    public Medicine getMedicineById(Long id) {
        return medicineDao.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found with id: " + id));
    }

    public List<Medicine> searchMedicines(String query) {
        if (query == null || query.isBlank()) {
            return medicineDao.findAll();
        }
        return medicineDao.searchByName(query);
    }

    public Medicine createMedicine(Medicine medicine) {
        validateMedicine(medicine);
        return medicineDao.save(medicine);
    }

    public Medicine updateMedicine(Long id, Medicine medicine) {
        // Verify medicine exists
        getMedicineById(id);

        validateMedicine(medicine);
        medicine.setId(id);
        medicineDao.update(medicine);
        return getMedicineById(id);
    }

    public void deleteMedicine(Long id) {
        // Verify medicine exists
        getMedicineById(id);

        // Prevent deletion if medicine has batches with stock
        if (medicineDao.hasActiveBatches(id)) {
            throw new BadRequestException("Cannot delete medicine with active stock. Remove or deplete batches first.");
        }

        medicineDao.deleteById(id);
    }

    private void validateMedicine(Medicine medicine) {
        if (medicine.getName() == null || medicine.getName().isBlank()) {
            throw new BadRequestException("Medicine name is required");
        }
        if (medicine.getUnitPrice() == null) {
            throw new BadRequestException("Unit price is required");
        }
        if (medicine.getUnitPrice().signum() <= 0) {
            throw new BadRequestException("Unit price must be greater than zero");
        }
    }
}
