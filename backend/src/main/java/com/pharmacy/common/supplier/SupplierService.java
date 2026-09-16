package com.pharmacy.common.supplier;

import com.pharmacy.common.exception.BadRequestException;
import com.pharmacy.common.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Business logic for supplier operations.
 */
@Service
public class SupplierService {

    private final SupplierDao supplierDao;

    public SupplierService(SupplierDao supplierDao) {
        this.supplierDao = supplierDao;
    }

    public List<Supplier> getAllSuppliers() {
        return supplierDao.findAll();
    }

    public Supplier getSupplierById(Long id) {
        return supplierDao.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Supplier not found with id: " + id));
    }

    public Supplier createSupplier(Supplier supplier) {
        if (supplier.getName() == null || supplier.getName().isBlank()) {
            throw new BadRequestException("Supplier name is required");
        }
        return supplierDao.save(supplier);
    }

    public Supplier updateSupplier(Long id, Supplier supplier) {
        // Verify supplier exists
        getSupplierById(id);

        if (supplier.getName() == null || supplier.getName().isBlank()) {
            throw new BadRequestException("Supplier name is required");
        }

        supplier.setId(id);
        supplierDao.update(supplier);
        return getSupplierById(id);
    }

    public void deleteSupplier(Long id) {
        // Verify supplier exists
        getSupplierById(id);
        supplierDao.deleteById(id);
    }
}
