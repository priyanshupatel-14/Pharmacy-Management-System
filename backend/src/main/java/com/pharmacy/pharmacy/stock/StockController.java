package com.pharmacy.pharmacy.stock;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for stock queries.
 */
@RestController
@RequestMapping("/api/stock")
public class StockController {

    private final StockService stockService;

    public StockController(StockService stockService) {
        this.stockService = stockService;
    }

    @GetMapping
    public ResponseEntity<List<StockInfo>> getAllStock() {
        return ResponseEntity.ok(stockService.getAllStock());
    }

    @GetMapping("/medicine/{medicineId}")
    public ResponseEntity<StockInfo> getStockByMedicine(@PathVariable Long medicineId) {
        return ResponseEntity.ok(stockService.getStockByMedicine(medicineId));
    }

    @GetMapping("/low")
    public ResponseEntity<List<StockInfo>> getLowStock(
            @RequestParam(name = "threshold", defaultValue = "10") int threshold) {
        return ResponseEntity.ok(stockService.getLowStock(threshold));
    }
}
