# Management System — Project Specification

## 1. Project Overview

This project consists of two related college mini-projects:

1. Pharmacy Management System
2. Inventory Management System

Both projects will use a common backend architecture and database design.

The backend will contain business logic required by both domains, while the frontend applications will be separate and domain-specific.

The Pharmacy Management System is the primary project for this repository.

The Inventory Management System will have a separate repository but will use the same backend design and business logic foundation.

---

## 2. Project Scope

This is a **college mini-project**, not a production-level application.

The implementation must therefore:

- Focus on the mandatory management features.
- Keep the architecture understandable.
- Avoid unnecessary complexity.
- Demonstrate Java, JDBC, database management, REST APIs, and frontend integration.
- Prioritize correctness and maintainability over production-scale infrastructure.

Do NOT add advanced features merely because they are common in commercial applications.

---

## 3. Technology Stack

### Frontend

- Flutter
- Dart
- Flutter Web for deployment
- Vercel for frontend hosting

### Backend

- Java
- Spring Boot
- Maven
- REST APIs
- JDBC / Spring JdbcTemplate

### Database

- PostgreSQL
- Railway PostgreSQL for deployment

### Backend Hosting

- Railway

### Version Control

- Git
- GitHub

---

## 4. Important Technology Restriction

The backend database access layer MUST use JDBC.

Preferred approach:

Spring Boot
→ Service Layer
→ DAO/Repository Layer
→ JdbcTemplate
→ PostgreSQL

Do NOT use:

- JPA
- Hibernate
- Spring Data JPA
- ORM-based persistence

unless explicitly approved later.

---

## 5. Overall System Concept

The backend is designed as a reusable management backend containing:

### Common functionality

- Authentication
- Users
- Products/items
- Suppliers
- Customers
- Sales
- Purchases
- Stock/inventory

### Pharmacy functionality

- Medicine management
- Medicine batches
- Expiry information
- Prescription management

### Inventory functionality

- Product/category management
- Warehouse/location management
- Stock movement

The exact final feature list will be finalized before implementation.

---

## 6. Two Frontends

There will be two separate Flutter applications.

### Pharmacy Management System

The Pharmacy frontend will expose pharmacy-related functionality such as:

- Medicines
- Medicine stock
- Suppliers
- Customers
- Sales/billing
- Expiry information
- Prescriptions

### Inventory Management System

The Inventory frontend will expose inventory-related functionality such as:

- Products
- Categories
- Stock
- Suppliers
- Customers
- Purchases
- Sales
- Warehouse/location
- Stock movement

The two frontends must have different user experiences appropriate to their respective project topics.

---

## 7. Shared Backend Principle

There will be one conceptual backend containing business logic for both projects.

The backend should be modular.

Common modules should contain reusable business logic.

Domain-specific modules should contain functionality unique to Pharmacy or Inventory Management.

The backend should NOT duplicate the same business logic merely because two frontends consume it.

---

## 8. Repository Structure

The final projects will be maintained as two separate GitHub repositories.

### Pharmacy repository

```text
Pharmacy Management System/
├── backend/
├── frontend/
├── database/
└── docs/
```

### Inventory repository

```text
Inventory Management System/
├── backend/
├── frontend/
├── database/
└── docs/
```

The backend and database designs will initially be developed as a common system.

Migration/copying of the finalized backend into the separate project repositories will be handled later.

---

## 9. Deployment Architecture

Final deployment target:

```text
Flutter Web
      ↓
    Vercel
      ↓
 HTTPS REST API
      ↓
   Railway
      ↓
Java Spring Boot
      ↓
    JDBC
      ↓
PostgreSQL
```

Deployment will be performed only after the application works correctly in the local development environment.

---

## 10. Development Philosophy

Development must proceed incrementally.

Recommended order:

1. Requirements
2. Feature definition
3. Database design
4. Backend architecture
5. Database implementation
6. Backend implementation
7. Backend testing
8. Pharmacy frontend
9. Inventory frontend
10. Integration testing
11. Deployment

Do not implement the entire application in one step.

Each module must be implemented, reviewed, and tested before moving to the next major module.

---

## 11. Current Development Status

At the beginning of development:

- Detailed features are not yet frozen.
- Detailed database schema is not yet frozen.
- API specification is not yet frozen.
- Backend implementation has not started.

Therefore, the AI agent must NOT begin generating the complete application yet.

The next task is to finalize the minimum required features and design the database accordingly.