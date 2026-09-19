package com.pharmacy.pharmacy.batch;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for medicine batch and expiry management.
 */
@RestController
@RequestMapping("/api/batches")
public class MedicineBatchController {

    private final MedicineBatchService batchService;

    public MedicineBatchController(MedicineBatchService batchService) {
        this.batchService = batchService;
    }

    private void requireAdmin() {
        if (!"ADMIN".equals(com.pharmacy.common.auth.TenantContext.getCurrentUser().getRole())) {
            throw new com.pharmacy.common.exception.BadRequestException("Only ADMIN can perform this action");
        }
    }

    @GetMapping
    public ResponseEntity<List<MedicineBatch>> getAllBatches() {
        return ResponseEntity.ok(batchService.getAllBatches());
    }

    @GetMapping("/{id}")
    public ResponseEntity<MedicineBatch> getBatchById(@PathVariable Long id) {
        return ResponseEntity.ok(batchService.getBatchById(id));
    }

    @GetMapping("/medicine/{medicineId}")
    public ResponseEntity<List<MedicineBatch>> getBatchesByMedicine(@PathVariable Long medicineId) {
        return ResponseEntity.ok(batchService.getBatchesByMedicine(medicineId));
    }

    @GetMapping("/expired")
    public ResponseEntity<List<MedicineBatch>> getExpiredBatches() {
        return ResponseEntity.ok(batchService.getExpiredBatches());
    }

    @GetMapping("/expiring-soon")
    public ResponseEntity<List<MedicineBatch>> getExpiringSoonBatches(
            @RequestParam(name = "days", defaultValue = "30") int days) {
        return ResponseEntity.ok(batchService.getExpiringSoonBatches(days));
    }

    @PostMapping
    public ResponseEntity<MedicineBatch> createBatch(@RequestBody MedicineBatch batch) {
        requireAdmin();
        MedicineBatch created = batchService.createBatch(batch);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<MedicineBatch> updateBatch(@PathVariable Long id, @RequestBody MedicineBatch batch) {
        requireAdmin();
        return ResponseEntity.ok(batchService.updateBatch(id, batch));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBatch(@PathVariable Long id) {
        requireAdmin();
        batchService.deleteBatch(id);
        return ResponseEntity.noContent().build();
    }
}
