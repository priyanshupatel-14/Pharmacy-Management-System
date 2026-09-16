package com.pharmacy.common.exception;

/**
 * Thrown when a sale cannot be completed due to insufficient stock.
 */
public class InsufficientStockException extends RuntimeException {

    public InsufficientStockException(String message) {
        super(message);
    }
}
