package com.pharmacy.common.sale;

import java.util.List;

/**
 * DTO for creating a new sale. Contains the user ID and a list of items.
 * Each item specifies a batch ID and quantity.
 * The backend calculates prices and totals — any price sent by the client is ignored.
 */
public class SaleRequest {

    private Long userId;
    private List<SaleItemRequest> items;

    public SaleRequest() {
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public List<SaleItemRequest> getItems() {
        return items;
    }

    public void setItems(List<SaleItemRequest> items) {
        this.items = items;
    }

    /**
     * Represents a single item in a sale request.
     */
    public static class SaleItemRequest {
        private Long batchId;
        private Integer quantity;

        public SaleItemRequest() {
        }

        public Long getBatchId() {
            return batchId;
        }

        public void setBatchId(Long batchId) {
            this.batchId = batchId;
        }

        public Integer getQuantity() {
            return quantity;
        }

        public void setQuantity(Integer quantity) {
            this.quantity = quantity;
        }
    }
}
