-- ============================================================
-- Pharmacy Management System — Seed Data (Multi-Tenant)
-- Run AFTER schema.sql
-- ============================================================

-- ============================================================
-- 1. PHARMACIES (Demo Tenant)
-- ============================================================
INSERT INTO pharmacies (name, owner_name, email, phone, address, status) VALUES
('PharmacyOS Demo Store', 'Admin User', 'admin@pharmacyos.demo', '9999999999', 'Demo Address, City', 'ACTIVE');

-- ============================================================
-- 2. USERS (passwords are BCrypt hashes of the plaintext shown in comments)
-- ============================================================
-- admin / admin123
INSERT INTO users (pharmacy_id, username, password, full_name, role) VALUES
(1, 'admin', '$2a$10$1PHOKOiGLfiIGYIPqeGe9eA.IyC2VXLgTZJIns6MmGNUcMc5sPq3S', 'Admin User', 'ADMIN');

-- pharmacist / pharma123
INSERT INTO users (pharmacy_id, username, password, full_name, role) VALUES
(1, 'pharmacist', '$2a$10$5hv85kXT0E7Kra3LFk7HmeI6L2/vVc01abWQYmk2BsNuGP4rn4fha', 'Rahul Sharma', 'PHARMACIST');

-- ============================================================
-- 3. SUPPLIERS
-- ============================================================
INSERT INTO suppliers (pharmacy_id, name, phone, email, address) VALUES
(1, 'Sun Pharma', '9876543210', 'contact@sunpharma.com', 'Mumbai, Maharashtra'),
(1, 'Cipla Ltd', '9876543211', 'info@cipla.com', 'Mumbai, Maharashtra'),
(1, 'Dr. Reddys Laboratories', '9876543212', 'support@drreddys.com', 'Hyderabad, Telangana');

-- ============================================================
-- 4. MEDICINES
-- ============================================================
INSERT INTO medicines (pharmacy_id, name, category, manufacturer, unit_price, supplier_id) VALUES
(1, 'Paracetamol 500mg',   'Tablet',   'Sun Pharma',              12.50,  1),
(1, 'Amoxicillin 250mg',   'Capsule',  'Cipla',                   25.00,  2),
(1, 'Cetirizine 10mg',     'Tablet',   'Dr. Reddys',              8.00,   3),
(1, 'Cough Syrup',         'Syrup',    'Cipla',                   85.00,  2),
(1, 'Ibuprofen 400mg',     'Tablet',   'Sun Pharma',              15.00,  1),
(1, 'Metformin 500mg',     'Tablet',   'Dr. Reddys',              10.00,  3),
(1, 'Azithromycin 500mg',  'Tablet',   'Cipla',                   45.00,  2),
(1, 'Vitamin C 500mg',     'Tablet',   'Sun Pharma',              5.00,   1);

-- ============================================================
-- 5. MEDICINE BATCHES
-- (Mix of valid batches, soon-to-expire, and expired)
-- ============================================================
-- Paracetamol batches
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(1, 'PARA-2025-A', '2027-06-15', 200, 8.00),
(1, 'PARA-2025-B', '2027-12-01', 150, 8.50);

-- Amoxicillin batches
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(2, 'AMOX-2025-A', '2027-03-20', 100, 18.00);

-- Cetirizine — one expired batch
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(3, 'CET-2024-A',  '2026-01-15', 30,  5.00),
(3, 'CET-2025-A',  '2027-08-10', 80,  5.50);

-- Cough Syrup
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(4, 'CSYP-2025-A', '2027-09-30', 50, 60.00);

-- Ibuprofen — expiring soon
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(5, 'IBU-2024-A',  '2026-10-15', 40,  10.00);

-- Metformin
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(6, 'MET-2025-A',  '2028-01-20', 300, 6.00);

-- Azithromycin
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(7, 'AZI-2025-A',  '2027-11-10', 60,  30.00);

-- Vitamin C
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(8, 'VITC-2025-A', '2028-05-01', 500, 3.00);

-- ============================================================
-- 6. SAMPLE SALES
-- ============================================================
-- Sale 1: Pharmacist sells Paracetamol and Cetirizine
INSERT INTO sales (pharmacy_id, user_id, total_amount, sale_date) VALUES
(1, 2, 149.00, '2026-09-15 10:30:00');

INSERT INTO sale_items (sale_id, batch_id, quantity, unit_price, subtotal) VALUES
(1, 1, 10, 12.50, 125.00),
(1, 5,  3,  8.00,  24.00);

-- Sale 2: Admin sells Cough Syrup
INSERT INTO sales (pharmacy_id, user_id, total_amount, sale_date) VALUES
(1, 1, 170.00, '2026-09-15 14:00:00');

INSERT INTO sale_items (sale_id, batch_id, quantity, unit_price, subtotal) VALUES
(2, 6, 2, 85.00, 170.00);
