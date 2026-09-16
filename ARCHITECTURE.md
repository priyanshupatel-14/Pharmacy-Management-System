# System Architecture

## 1. High-Level Architecture

The system follows a simple layered architecture.

```text
Flutter Frontend
       ↓
    REST API
       ↓
Controller Layer
       ↓
 Service Layer
       ↓
   DAO Layer
       ↓
 JdbcTemplate
       ↓
 PostgreSQL
```

---

## 2. Frontend

Flutter is responsible for:

- User interface
- Navigation
- Form handling
- Input validation where appropriate
- API communication
- Displaying backend responses
- Presenting errors and success messages

The frontend must NOT contain core business rules that belong to the backend.

For example, stock calculations should be performed by the backend rather than being trusted to the Flutter application.

---

## 3. Controller Layer

Controllers expose REST endpoints.

Responsibilities:

- Receive HTTP requests.
- Validate request structure.
- Call the appropriate service.
- Return appropriate HTTP responses.

Controllers should not contain database queries.

Example:

```text
MedicineController
       ↓
MedicineService
```

NOT:

```text
MedicineController
       ↓
SQL Query
```

---

## 4. Service Layer

The service layer contains business logic.

Examples:

- Checking whether sufficient stock exists.
- Calculating sale totals.
- Updating stock after a sale.
- Validating pharmacy-specific operations.
- Handling expiry-related rules.

Services should not directly contain raw SQL.

Example:

```text
MedicineService
       ↓
MedicineDAO
```

---

## 5. DAO Layer

DAO means Data Access Object.

The DAO layer is responsible for database operations.

Example:

```text
MedicineDAO
    ↓
JdbcTemplate
    ↓
PostgreSQL
```

SQL queries should be located in the DAO/repository layer rather than controllers or services.

---

## 6. JDBC

Database communication must use JDBC through Spring's JdbcTemplate.

Example conceptual flow:

```text
HTTP Request
     ↓
Controller
     ↓
Service
     ↓
DAO
     ↓
JdbcTemplate
     ↓
PostgreSQL
```

The project should demonstrate actual JDBC-based database access.

---

## 7. Common Modules

Common backend modules may include:

```text
auth
users
products
suppliers
customers
sales
purchases
inventory
```

The final modules will be determined by the approved feature list.

---

## 8. Pharmacy Modules

Pharmacy-specific functionality may include:

```text
medicine
batch
prescription
expiry
```

These modules must contain logic that is genuinely relevant to pharmacy management.

---

## 9. Inventory Modules

Inventory-specific functionality may include:

```text
category
warehouse
stock-movement
```

These modules must contain logic relevant to general inventory management.

---

## 10. Separation of Concerns

The following rules must be maintained:

### Controller

HTTP/API handling.

### Service

Business logic.

### DAO

Database operations and SQL.

### Model/Entity

Data representation.

### DTO

API request/response representation where required.

### Configuration

Application/database configuration.

---

## 11. Database Principle

The database must be designed around actual project requirements.

Do not create tables simply because they appear in generic management-system tutorials.

Every table should have a clear purpose.

Relationships should use appropriate primary keys and foreign keys.

The final schema must be documented before significant backend implementation begins.

---

## 12. API Principle

The backend should expose simple REST APIs.

Example conceptual structure:

```text
/api/auth/...
/api/products/...
/api/suppliers/...
/api/customers/...
/api/sales/...
/api/medicines/...
/api/prescriptions/...
```

The exact endpoints, request bodies, response structures, and HTTP methods will be defined in a separate API specification before frontend integration.

---

## 13. Error Handling

The backend should provide clear responses for common situations such as:

- Invalid input
- Resource not found
- Insufficient stock
- Duplicate data
- Invalid credentials
- Database errors

Do not build an unnecessarily complicated global error-handling framework for the mini-project.

Keep it clean and understandable.

---

## 14. Configuration

Sensitive configuration such as:

- Database URL
- Database username
- Database password
- JWT secret, if authentication uses JWT

must not be hardcoded into source code.

Use environment variables/configuration appropriate for local development and Railway deployment.

---

## 15. Deployment

Local development:

```text
Flutter
   ↓
localhost
   ↓
Spring Boot
   ↓
PostgreSQL
```

Production:

```text
Vercel
   ↓
Railway Backend
   ↓
Railway PostgreSQL
```

Deployment configuration should not affect the core application architecture.