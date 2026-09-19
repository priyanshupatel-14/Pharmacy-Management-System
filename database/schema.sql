-- ============================================================
-- Pharmacy Management System — Database Schema (Multi-Tenant)
-- PostgreSQL
-- ============================================================

-- Drop tables in reverse dependency order (for clean re-creation)
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS medicine_batches CASCADE;
DROP TABLE IF EXISTS medicines CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS pharmacies CASCADE;

-- ============================================================
-- 1. PHARMACIES (Tenant Root)
-- ============================================================
CREATE TABLE pharmacies (
    id          BIGSERIAL       PRIMARY KEY,
    name        VARCHAR(100)    NOT NULL,
    owner_name  VARCHAR(100)    NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    address     TEXT,
    status      VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE',
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. USERS — Authentication
-- ============================================================
CREATE TABLE users (
    id          BIGSERIAL       PRIMARY KEY,
    pharmacy_id BIGINT          NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    username    VARCHAR(50)     NOT NULL,
    password    VARCHAR(255)    NOT NULL,
    full_name   VARCHAR(100)    NOT NULL,
    role        VARCHAR(20)     NOT NULL DEFAULT 'PHARMACIST',
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_users_role CHECK (role IN ('ADMIN', 'PHARMACIST')),
    CONSTRAINT users_username_key UNIQUE (username)
);

CREATE INDEX idx_users_pharmacy ON users(pharmacy_id);

-- ============================================================
-- 3. SESSIONS — Stateful token validation
-- ============================================================
CREATE TABLE sessions (
    token       VARCHAR(36)     PRIMARY KEY,
    user_id     BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at  TIMESTAMP       NOT NULL
);

-- ============================================================
-- 4. SUPPLIERS
-- ============================================================
CREATE TABLE suppliers (
    id          BIGSERIAL       PRIMARY KEY,
    pharmacy_id BIGINT          NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    name        VARCHAR(100)    NOT NULL,
    phone       VARCHAR(20),
    email       VARCHAR(100),
    address     TEXT,
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_suppliers_pharmacy ON suppliers(pharmacy_id);

-- ============================================================
-- 5. MEDICINES
-- ============================================================
CREATE TABLE medicines (
    id              BIGSERIAL       PRIMARY KEY,
    pharmacy_id     BIGINT          NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    name            VARCHAR(100)    NOT NULL,
    category        VARCHAR(50),
    manufacturer    VARCHAR(100),
    unit_price      DECIMAL(10,2)   NOT NULL,
    supplier_id     BIGINT          REFERENCES suppliers(id) ON DELETE SET NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_medicines_price CHECK (unit_price > 0)
);

CREATE INDEX idx_medicines_pharmacy ON medicines(pharmacy_id);
CREATE INDEX idx_medicines_name ON medicines(name);
CREATE INDEX idx_medicines_supplier ON medicines(supplier_id);

-- ============================================================
-- 6. MEDICINE BATCHES — Stock is tracked here (quantity column)
-- ============================================================
-- Note: Derived tenant ownership via medicine_id
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
-- 7. SALES
-- ============================================================
CREATE TABLE sales (
    id              BIGSERIAL       PRIMARY KEY,
    pharmacy_id     BIGINT          NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    user_id         BIGINT          REFERENCES users(id) ON DELETE SET NULL,
    total_amount    DECIMAL(10,2)   NOT NULL,
    sale_date       TIMESTAMP       NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sales_pharmacy ON sales(pharmacy_id);
CREATE INDEX idx_sales_date ON sales(sale_date);

-- ============================================================
-- 8. SALE ITEMS
-- ============================================================
-- Note: Derived tenant ownership via sale_id
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
