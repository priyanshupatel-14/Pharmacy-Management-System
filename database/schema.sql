-- ============================================================
-- Pharmacy Management System — Database Schema
-- PostgreSQL
-- ============================================================

-- Drop tables in reverse dependency order (for clean re-creation)
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS medicine_batches CASCADE;
DROP TABLE IF EXISTS medicines CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================
-- 1. USERS — Authentication
-- ============================================================
CREATE TABLE users (
    id          BIGSERIAL       PRIMARY KEY,
    username    VARCHAR(50)     NOT NULL UNIQUE,
    password    VARCHAR(255)    NOT NULL,
    full_name   VARCHAR(100)    NOT NULL,
    role        VARCHAR(20)     NOT NULL DEFAULT 'PHARMACIST',
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_users_role CHECK (role IN ('ADMIN', 'PHARMACIST'))
);

-- ============================================================
-- 2. SUPPLIERS
-- ============================================================
CREATE TABLE suppliers (
    id          BIGSERIAL       PRIMARY KEY,
    name        VARCHAR(100)    NOT NULL,
    phone       VARCHAR(20),
    email       VARCHAR(100),
    address     TEXT,
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. MEDICINES
-- ============================================================
CREATE TABLE medicines (
    id              BIGSERIAL       PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    category        VARCHAR(50),
    manufacturer    VARCHAR(100),
    unit_price      DECIMAL(10,2)   NOT NULL,
    supplier_id     BIGINT          REFERENCES suppliers(id) ON DELETE SET NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_medicines_price CHECK (unit_price > 0)
);

CREATE INDEX idx_medicines_name ON medicines(name);
CREATE INDEX idx_medicines_supplier ON medicines(supplier_id);

-- ============================================================
-- 4. MEDICINE BATCHES — Stock is tracked here (quantity column)
-- ============================================================
CREATE TABLE medicine_batches (
    id              BIGSERIAL       PRIMARY KEY,
    medicine_id     BIGINT          NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    batch_number    VARCHAR(50)     NOT NULL,
    expiry_date     DATE            NOT NULL,
    quantity        INTEGER         NOT NULL,
    purchase_price  DECIMAL(10,2),
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_batches_quantity CHECK (quantity >= 0),
    CONSTRAINT uq_medicine_batch UNIQUE (medicine_id, batch_number)
);

CREATE INDEX idx_batches_medicine ON medicine_batches(medicine_id);
CREATE INDEX idx_batches_expiry ON medicine_batches(expiry_date);

-- ============================================================
-- 5. SALES
-- ============================================================
CREATE TABLE sales (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          REFERENCES users(id) ON DELETE SET NULL,
    total_amount    DECIMAL(10,2)   NOT NULL,
    sale_date       TIMESTAMP       NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sales_date ON sales(sale_date);

-- ============================================================
-- 6. SALE ITEMS
-- ============================================================
CREATE TABLE sale_items (
    id          BIGSERIAL       PRIMARY KEY,
    sale_id     BIGINT          NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    batch_id    BIGINT          NOT NULL REFERENCES medicine_batches(id),
    quantity    INTEGER         NOT NULL,
    unit_price  DECIMAL(10,2)   NOT NULL,
    subtotal    DECIMAL(10,2)   NOT NULL,

    CONSTRAINT chk_sale_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_sale_items_price CHECK (unit_price >= 0),
    CONSTRAINT chk_sale_items_subtotal CHECK (subtotal >= 0)
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_batch ON sale_items(batch_id);
