# Second Tenant Security Audit Report

## A. Temporary Files That Should Not Be Committed
- `backend/TestJdbc.class`
- `backend/TestJdbc2.class`
- `backend/TestJdbc3.class`
- `backend/TestJdbc4.class`
- `audit.ps1`
- `GIT_PRE_COMMIT_AUDIT.md`
- `scratch/append_analysis.py`

## B. Authentication Architecture
- **Login:** Handled via `AuthService.login()`. It queries `AuthDao.findByUsername(username)`, which executes a global `SELECT * FROM users WHERE username = ?`.
- **Registration:** Handled via `AuthService.register()`. It verifies username uniqueness via `AuthDao.existsByUsername(username)`, which executes a global `SELECT COUNT(*)`. The first user registered with a new pharmacy is hardcoded to the `"ADMIN"` role.
- **Session Management:** Sessions use UUID tokens stored in the `sessions` table mapped to `user_id`, expiring after 7 days.
- **Duplicate Username Handling:** The application enforces **global** username uniqueness due to the global `SELECT` queries, even though the database schema only enforces per-pharmacy uniqueness (`UNIQUE (pharmacy_id, username)`).

## C. Tenant Resolution Flow
1. Client sends `Authorization: Bearer <token>`.
2. `TenantInterceptor.preHandle()` extracts the token and calls `AuthDao.getUserByToken(token)`.
3. If valid, the authenticated `User` object (which contains the `pharmacy_id`) is placed into `TenantContext.setCurrentUser(user)`.
4. Endpoints retrieve the tenant ID using `TenantContext.getCurrentPharmacyId()`.
5. The `TenantInterceptor.afterCompletion()` cleanly calls `TenantContext.clear()` to prevent memory leaks across threads.
6. **Spoofing Prevention:** A client cannot spoof the `pharmacy_id` because it is never read from request headers, parameters, or bodies. It is securely derived from the server-side token mapping.

## D. Complete DAO Tenant-Isolation Table

| File | Method | Operation | Tenant Scoped? | Risk |
|------|--------|-----------|----------------|------|
| AuthDao | save | INSERT | YES (via Service) | Low |
| AuthDao | findByUsername | SELECT | NO (Global) | Low (UX limitation) |
| AuthDao | existsByUsername | SELECT | NO (Global) | Low (UX limitation) |
| UserController | getStaff | SELECT | YES | Low |
| UserController | createStaff | INSERT | YES (via context)| Low |
| UserController | deleteStaff | DELETE | YES (via context)| Low |
| PharmacyController | getMyPharmacy | SELECT | YES | Low |
| SaleDao | findAll / findById | SELECT | YES | Low |
| SaleDao | findItemsBySaleId | SELECT | YES (via Join) | Low |
| SaleDao | saveSale | INSERT | YES | Low |
| SaleDao | saveSaleItem | INSERT | **NO (batchId)** | **HIGH (IDOR)** |
| SupplierDao | findAll / findById | SELECT | YES | Low |
| SupplierDao | save / update / delete | INS/UPD/DEL | YES | Low |
| MedicineBatchDao | findAll / findById | SELECT | YES (via Join) | Low |
| MedicineBatchDao | save | INSERT | **NO (medicineId)**| **HIGH (IDOR)** |
| MedicineBatchDao | update / delete | UPD/DEL | YES (Subquery) | Low |
| MedicineDao | save / update / delete / find | ALL | YES | Low |
| StockService | getAllStock / lowStock | SELECT | YES | Low |

## E. IDOR Findings
- **HIGH:** `SaleDao.saveSaleItem(SaleItem item)` inserts a `batch_id` supplied in the request body without verifying that the batch belongs to the current tenant. A malicious user could submit a sale using a `batch_id` belonging to another pharmacy.
- **HIGH:** `MedicineBatchDao.save(MedicineBatch batch)` inserts a `medicine_id` supplied in the request body without verifying that the medicine belongs to the current tenant. A malicious user could add inventory batches to another pharmacy's medicine.

## F. RBAC Findings
- The `UserController` enforces `requireAdmin()` on `getStaff`, `createStaff`, and `deleteStaff` endpoints.
- New staff users can only be created by an existing `ADMIN`.
- However, all other controllers (Medicines, Suppliers, Batches, Sales) do not enforce any role checks on the backend. This means a `PHARMACIST` can modify/delete suppliers, batches, medicines, and sales (as long as they belong to the same pharmacy).

## G. Migration Findings
- `migration_v2.sql` is well-formed for PostgreSQL.
- It is safe for existing Railway data. There are no `DROP TABLE`, `TRUNCATE`, or destructive data deletion commands.
- It correctly maps legacy records (where `pharmacy_id` is NULL) to a default 'PharmacyOS Demo Store'.
- It successfully alters the `users` table to add a unique constraint on `(pharmacy_id, username)` and drops the legacy global username constraint.

## H. Database Consistency Findings
- There is a mismatch between the database schema and application code regarding usernames. The DB enforces `UNIQUE(pharmacy_id, username)`, but `AuthDao` checks for global uniqueness via `SELECT * FROM users WHERE username = ?`. This prevents reusing usernames across pharmacies.
- Foreign keys correctly enforce relationships between `users`, `medicines`, `suppliers`, `medicine_batches`, `sales`, and their respective `pharmacy_id`.

## I. Test Coverage
- Inspection of `backend/src/test/java` reveals only a single auto-generated test (`PharmacyManagementApplicationTests.contextLoads()`).
- There are **no tests** for registration, login, invalid tokens, tenant isolation, cross-tenant access, role authorization, or duplicate usernames.

## J. Critical Issues
1. **IDOR on Sales:** `SaleDao.saveSaleItem` fails to verify tenant ownership of `batch_id`.
2. **IDOR on Batches:** `MedicineBatchDao.save` fails to verify tenant ownership of `medicine_id`.

## K. Non-Critical Issues
1. **Username Uniqueness Mismatch:** The DB allows per-pharmacy unique usernames, but the backend `AuthDao` enforces global uniqueness, leading to potential login/registration UX issues.
2. **Missing RBAC:** `PHARMACIST` users can potentially edit/delete medicines, suppliers, and sales, unless this is the intended business behavior.
3. **No Test Coverage:** The backend lacks unit and integration tests for security constraints.

## L. Recommended Fixes
1. Modify `MedicineBatchDao.save()` to verify that the `medicine_id` belongs to the current `pharmacy_id` before inserting.
2. Modify `SaleDao.saveSaleItem()` to verify that the `batch_id` belongs to the current `pharmacy_id` before inserting.
3. Update `AuthDao` and `AuthService` to include `pharmacyName` or a `pharmacy_id` mechanism during login to fully support per-tenant duplicate usernames, or accept global uniqueness as a design decision and revert the DB constraint to match.
