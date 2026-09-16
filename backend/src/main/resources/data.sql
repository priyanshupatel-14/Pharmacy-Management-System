-- ============================================================
-- Pharmacy Management System — Seed Data
-- Compatible with H2 (PostgreSQL mode) and PostgreSQL
-- ============================================================

-- USERS (BCrypt hashed passwords — generated at runtime for real use)
-- admin / admin123
INSERT INTO users (username, password, full_name, role) VALUES
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Admin User', 'ADMIN');
-- pharmacist / pharma123
INSERT INTO users (username, password, full_name, role) VALUES
('pharmacist', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Rahul Sharma', 'PHARMACIST');

-- SUPPLIERS
INSERT INTO suppliers (name, phone, email, address) VALUES
('Sun Pharma', '9876543210', 'contact@sunpharma.com', 'Mumbai, Maharashtra');
INSERT INTO suppliers (name, phone, email, address) VALUES
('Cipla Ltd', '9876543211', 'info@cipla.com', 'Mumbai, Maharashtra');
INSERT INTO suppliers (name, phone, email, address) VALUES
('Dr. Reddys Laboratories', '9876543212', 'support@drreddys.com', 'Hyderabad, Telangana');

-- MEDICINES
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Paracetamol 500mg', 'Tablet', 'Sun Pharma', 12.50, 1);
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Amoxicillin 250mg', 'Capsule', 'Cipla', 25.00, 2);
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Cetirizine 10mg', 'Tablet', 'Dr. Reddys', 8.00, 3);
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Cough Syrup', 'Syrup', 'Cipla', 85.00, 2);
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Ibuprofen 400mg', 'Tablet', 'Sun Pharma', 15.00, 1);
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Metformin 500mg', 'Tablet', 'Dr. Reddys', 10.00, 3);
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Azithromycin 500mg', 'Tablet', 'Cipla', 45.00, 2);
INSERT INTO medicines (name, category, manufacturer, unit_price, supplier_id) VALUES
('Vitamin C 500mg', 'Tablet', 'Sun Pharma', 5.00, 1);

-- MEDICINE BATCHES (mix of valid, expiring-soon, and expired)
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(1, 'PARA-2025-A', '2027-06-15', 200, 8.00);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(1, 'PARA-2025-B', '2027-12-01', 150, 8.50);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(2, 'AMOX-2025-A', '2027-03-20', 100, 18.00);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(3, 'CET-2024-A', '2026-01-15', 30, 5.00);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(3, 'CET-2025-A', '2027-08-10', 80, 5.50);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(4, 'CSYP-2025-A', '2027-09-30', 50, 60.00);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(5, 'IBU-2024-A', '2026-10-15', 40, 10.00);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(6, 'MET-2025-A', '2028-01-20', 300, 6.00);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(7, 'AZI-2025-A', '2027-11-10', 60, 30.00);
INSERT INTO medicine_batches (medicine_id, batch_number, expiry_date, quantity, purchase_price) VALUES
(8, 'VITC-2025-A', '2028-05-01', 500, 3.00);
