package com.pharmacy.common.exception;

/**
 * Thrown when a request contains invalid data (bad input, duplicates, etc.).
 */
public class BadRequestException extends RuntimeException {

    public BadRequestException(String message) {
        super(message);
    }
}
