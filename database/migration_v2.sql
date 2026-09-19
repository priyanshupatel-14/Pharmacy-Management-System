-- ============================================================
-- Pharmacy Management System — Multi-Tenant Migration (v2)
-- PostgreSQL
-- WARNING: This script modifies the live schema.
-- ============================================================

BEGIN;

-- 1. Create new tables
CREATE TABLE IF NOT EXISTS pharmacies (
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

CREATE TABLE IF NOT EXISTS sessions (
    token       VARCHAR(36)     PRIMARY KEY,
    user_id     BIGINT          NOT NULL,
    expires_at  TIMESTAMP       NOT NULL
);

-- 2. Add nullable pharmacy_id columns to existing tables
ALTER TABLE users ADD COLUMN IF NOT EXISTS pharmacy_id BIGINT;
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS pharmacy_id BIGINT;
ALTER TABLE medicines ADD COLUMN IF NOT EXISTS pharmacy_id BIGINT;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS pharmacy_id BIGINT;

-- 3. Insert Demo Pharmacy if none exists
INSERT INTO pharmacies (id, name, owner_name, email, phone, address, status)
SELECT 1, 'PharmacyOS Demo Store', 'Admin User', 'admin@pharmacyos.demo', '9999999999', 'Demo Address, City', 'ACTIVE'
WHERE NOT EXISTS (SELECT 1 FROM pharmacies WHERE id = 1);

-- Reset sequence just in case
SELECT setval('pharmacies_id_seq', (SELECT MAX(id) FROM pharmacies));

-- 4. Map all existing records to the Demo Pharmacy
UPDATE users SET pharmacy_id = 1 WHERE pharmacy_id IS NULL;
UPDATE suppliers SET pharmacy_id = 1 WHERE pharmacy_id IS NULL;
UPDATE medicines SET pharmacy_id = 1 WHERE pharmacy_id IS NULL;
UPDATE sales SET pharmacy_id = 1 WHERE pharmacy_id IS NULL;

-- 5. Enforce NOT NULL and Foreign Key constraints
ALTER TABLE users ALTER COLUMN pharmacy_id SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT fk_users_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE;

ALTER TABLE suppliers ALTER COLUMN pharmacy_id SET NOT NULL;
ALTER TABLE suppliers ADD CONSTRAINT fk_suppliers_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE;

ALTER TABLE medicines ALTER COLUMN pharmacy_id SET NOT NULL;
ALTER TABLE medicines ADD CONSTRAINT fk_medicines_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE;

ALTER TABLE sales ALTER COLUMN pharmacy_id SET NOT NULL;
ALTER TABLE sales ADD CONSTRAINT fk_sales_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE;

-- Add foreign key constraint to sessions table after the fact, since it references users
ALTER TABLE sessions ADD CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Update unique constraint for multi-tenancy
-- Note: We retain global username uniqueness to support simple login with just username/password.
-- Thus, users_username_key is kept as-is, and we do not add a per-pharmacy constraint.

-- 6. Add indexes
CREATE INDEX IF NOT EXISTS idx_users_pharmacy ON users(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_pharmacy ON suppliers(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_medicines_pharmacy ON medicines(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_sales_pharmacy ON sales(pharmacy_id);

COMMIT;
