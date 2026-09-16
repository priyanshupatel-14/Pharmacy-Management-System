# AI Agent Development Rules

## Role

You are assisting with the development of a Java + JDBC college mini-project.

You are an implementation agent, not the sole architect.

Follow the project documentation and existing code. Do not make major architectural decisions without explicit approval.

---

## Rule 1 — Read Documentation First

Before modifying code, inspect:

- `PROJECT_SPEC.md`
- `ARCHITECTURE.md`
- Existing source code
- Existing database files
- Existing API documentation

Do not assume the architecture.

---

## Rule 2 — Do Not Over-Engineer

This is a college mini-project.

Do not introduce unnecessary:

- Microservices
- Redis
- Kafka
- Docker unless explicitly requested
- Complex caching
- Event-driven architecture
- Advanced security systems
- Excessive design patterns
- Unnecessary abstractions

Prefer simple, understandable code.

---

## Rule 3 — JDBC Is Mandatory

Database access must use:

```text
Spring Boot
+
JdbcTemplate
+
PostgreSQL
```

Do NOT introduce:

- JPA
- Hibernate
- Spring Data JPA
- EntityManager
- ORM-based persistence

---

## Rule 4 — Respect the Layered Architecture

Follow:

```text
Controller
    ↓
Service
    ↓
DAO
    ↓
JdbcTemplate
    ↓
Database
```

Do not place SQL inside controllers.

Do not place database access directly inside Flutter.

Do not put major business logic inside controllers.

---

## Rule 5 — Do Not Modify the Database Without Approval

Once the database schema is finalized:

- Do not rename tables.
- Do not rename columns.
- Do not remove columns.
- Do not change relationships.
- Do not add tables.

unless the change is explicitly discussed and approved.

If a requirement appears to require a schema change, explain the issue before making the change.

---

## Rule 6 — Do Not Implement Everything at Once

Work module-by-module.

For each module:

1. Inspect requirements.
2. Implement database support if required.
3. Implement model/DTO.
4. Implement DAO.
5. Implement service.
6. Implement controller.
7. Test the API.
8. Fix issues.
9. Move to the next module.

---

## Rule 7 — Do Not Invent Requirements

If a feature is not specified, do not automatically add it.

Ask for clarification or identify it as an optional recommendation.

---

## Rule 8 — Keep Pharmacy and Inventory Concepts Distinct

Pharmacy-specific functionality belongs to Pharmacy modules.

Inventory-specific functionality belongs to Inventory modules.

Do not make the Pharmacy application simply a renamed Inventory application.

The Pharmacy project must have genuine pharmacy-specific functionality.

---

## Rule 9 — Preserve Existing Working Code

Before modifying an existing module:

- Understand its current implementation.
- Avoid unnecessary rewrites.
- Modify only what is required.
- Do not break unrelated functionality.

---

## Rule 10 — Explain Important Changes

After implementing a task, report:

1. What was changed.
2. Which files were changed.
3. Why the changes were made.
4. How the implementation works.
5. How it can be tested.
6. Any issues or assumptions.

Keep the explanation concise but technically accurate.

---

## Rule 11 — Test Before Claiming Completion

Do not claim that a feature is complete merely because the code compiles.

Where possible:

- Compile the backend.
- Run the application.
- Test the relevant API.
- Verify database operations.
- Check error cases.

If something could not be tested, state that clearly.

---

## Rule 12 — No Hardcoded Secrets

Never commit:

- Database passwords
- API keys
- JWT secrets
- Production credentials

Use environment variables/configuration.

---

## Rule 13 — Don't Change Technologies

Do not replace the approved stack with alternatives.

Approved stack:

```text
Flutter
Dart
Java
Spring Boot
JDBC / JdbcTemplate
PostgreSQL
GitHub
Railway
Vercel
```

Any technology change requires explicit approval.

---

## Rule 14 — Ask Before Major Changes

Stop and ask for approval before:

- Changing architecture
- Changing database structure
- Adding a major dependency
- Switching persistence technology
- Adding major functionality
- Rewriting a completed module
- Changing API contracts used by the frontend

---

## Rule 15 — Development Priority

Always prioritize:

1. Correctness
2. Simplicity
3. Requirement compliance
4. Maintainability
5. Clean architecture
6. Production-level optimization

The project is educational, so understandable implementation is more important than unnecessary sophistication.