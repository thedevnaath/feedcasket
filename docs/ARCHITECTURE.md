# FeedCasket Architecture

## 1. Purpose

This document defines the technical architecture of FeedCasket.

FeedCasket is an API-first feedback infrastructure platform.

The customer website owns the feedback user interface.

FeedCasket owns the backend infrastructure that receives, validates, stores, protects, and exposes feedback to the developer.

The architecture must prioritize:

* Simplicity
* Security
* Reliability
* Low operating complexity
* Developer experience
* Clear separation of public and private functionality
* Ability to scale without premature infrastructure complexity

---

# 2. High-Level Architecture

The primary system is:

```text
                    CUSTOMER WEBSITE
                           │
                           │
                  Developer's custom UI
                           │
                           │ HTTPS
                           ▼
                ┌──────────────────────┐
                │   FeedCasket API     │
                │  Cloudflare Worker   │
                └──────────┬───────────┘
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
          Validate       Usage          D1
          & Protect     / Limits      Database
                           │
                           │
                           ▼
                          R2
                     Screenshots
```

The developer dashboard communicates with the same FeedCasket API.

```text
                DEVELOPER DASHBOARD
                         │
                         │ authenticated API
                         ▼
                ┌──────────────────────┐
                │   FeedCasket API     │
                │  Cloudflare Worker   │
                └──────────┬───────────┘
                           │
                           ▼
                          D1
```

Screenshots use R2 rather than D1.

---

# 3. Core Architectural Principle

FeedCasket must remain **UI-independent**.

The customer website may implement:

* Feedback button
* Feedback modal
* Feedback form
* Inline feedback UI
* Custom styling
* Custom animations
* Custom accessibility behavior
* Custom fields in their own interface

FeedCasket only defines the backend contract.

This allows developers to create an experience that matches their existing product.

---

# 4. Main Components

## 4.1 Customer Integration

The customer integrates FeedCasket into their website through the documented API/integration method.

The customer-side code must never contain privileged FeedCasket credentials.

The customer may safely contain:

* Public project identifier
* Public API configuration required by the integration

The customer-side code must never contain:

* Cloudflare API tokens
* Database credentials
* Authentication secrets
* Administrative credentials
* Payment-provider secrets
* Any other privileged server credential

---

# 5. Cloudflare Worker

The Cloudflare Worker is the primary application backend.

It acts as:

* HTTP API
* Authentication layer
* Authorization layer
* Validation layer
* Business-logic layer
* Project-management API
* Feedback-processing API
* Dashboard API
* Usage enforcement layer
* Screenshot-upload authorization layer

The Worker communicates with:

* D1
* R2
* Cloudflare platform capabilities required for request protection

The Worker should remain a modular monolith for the MVP.

Do not create multiple Workers/services unless there is a demonstrated requirement.

---

# 6. Public API vs Private API

The API should logically separate public customer submission functionality from authenticated developer functionality.

## Public functionality

The public feedback endpoint allows a visitor's custom feedback UI to submit feedback.

Conceptually:

```text
POST /api/v1/feedback
```

The endpoint must assume requests can be malicious.

It therefore must apply:

1. Request validation
2. Project validation
3. Domain/origin validation where appropriate
4. Payload limits
5. Rate limiting
6. Abuse protection
7. Usage enforcement
8. Safe persistence

A public project identifier is not an authentication credential.

---

## Private functionality

Authenticated APIs are used by:

* Developer dashboard
* Project management
* Feedback access
* Search
* Read/unread updates
* Usage information
* Settings

Private APIs must verify:

```text
Authenticated user
        ↓
owns project
        ↓
may access requested resource
```

Never trust a project ID supplied by the client to determine authorization.

---

# 7. D1 Database

D1 is the primary relational application database.

It should store durable application data such as:

* Users
* Projects
* Feedback
* Usage/credits
* Credit transactions where appropriate
* Notification/settings data where required
* Screenshot metadata
* Other relational entities required by the product

D1 should NOT store binary screenshot files.

D1 should NOT be used as a permanent event log for every rate-limit attempt.

The database should remain focused on durable business data.

---

# 8. Database Ownership Model

FeedCasket is multi-tenant.

The ownership model is:

```text
User
 │
 ├── Project
 │     ├── Feedback
 │     ├── Usage
 │     └── Screenshots
 │
 └── Other private resources
```

Every private resource must have a reliable ownership path back to the authenticated user.

Example:

```text
Authenticated User
        ↓
Project
        ↓
Feedback
```

A developer must never be able to retrieve another developer's project or feedback by changing a project ID, feedback ID, or API parameter.

Authorization must always be enforced server-side.

---

# 9. R2 Object Storage

R2 is used for screenshot files.

The database stores metadata/reference information.

R2 stores the actual binary object.

Conceptually:

```text
Feedback row
   │
   └── screenshot_reference
             │
             ▼
           R2 object
```

Screenshot uploads must have:

* Maximum file size
* Allowed file formats
* Server-side validation
* Safe object naming
* Project/feedback association
* Access controls

Dashboard users must not gain unrestricted access to another project's screenshots.

---

# 10. Screenshot Access

Screenshots are private project data.

The dashboard must not expose a public permanent object URL merely because the image exists in R2.

Use an authenticated application flow to authorize access.

The application may provide a temporary/signed access mechanism where appropriate.

The important requirement is:

```text
Authenticated developer
        ↓
authorized for feedback
        ↓
authorized for screenshot
        ↓
screenshot delivered
```

---

# 11. Authentication

Authentication is required for developer-facing private functionality.

Authentication covers:

* Account access
* Dashboard access
* Project management
* Feedback access
* Usage information
* Settings

Visitors submitting feedback do not authenticate with FeedCasket.

The authentication implementation must use a real secure mechanism.

Do not implement fake authentication or a frontend-only login state.

---

# 12. Authorization

Authentication answers:

> Who is this user?

Authorization answers:

> What may this user access?

FeedCasket must enforce authorization at the API/backend level.

For example:

```text
GET /api/v1/projects/projectA/feedback
```

must verify that the authenticated account owns `projectA`.

The API must not simply return data because a valid project ID was supplied.

---

# 13. Feedback Processing Pipeline

A public feedback request should conceptually follow this sequence:

```text
HTTP Request
      │
      ▼
Basic request validation
      │
      ▼
Project validation
      │
      ▼
Origin/domain checks
      │
      ▼
Rate limiting / abuse controls
      │
      ▼
Payload validation
      │
      ▼
Usage/allowance validation
      │
      ▼
Screenshot validation/upload if applicable
      │
      ▼
Persist feedback
      │
      ▼
Update usage
      │
      ▼
Return success response
```

The implementation may combine steps where technically appropriate, but the security boundaries must remain clear.

---

# 14. Rate Limiting Architecture

Rate limiting exists to protect:

* FeedCasket infrastructure
* Individual projects
* Database capacity
* Free allowances
* Customers from abuse

Rate limiting should preferably happen at the edge or through a transient mechanism.

Do not create a D1 row for every incoming request merely to record rate-limit activity.

Do not build a permanent IP tracking database as the primary rate-limit mechanism.

The exact rate-limit values should be configurable rather than deeply hardcoded into business logic.

Rate limiting should support multiple dimensions where practical, such as:

* Project
* Client/IP-related signal
* Request frequency
* Global protection

IP-based controls should be treated as an abuse signal rather than a perfect identity.

---

# 15. Domain / Origin Validation

Projects may define allowed domains.

Example:

```text
example.com
www.example.com
app.example.com
```

The public feedback endpoint should use available request-origin information to determine whether the request is consistent with the configured project domain.

This is an abuse-control layer.

It is not a replacement for cryptographic authentication because public web requests can be reproduced outside normal browser behavior.

Domain configuration must therefore be combined with rate limiting and other controls.

---

# 16. CORS

The public API must be deliberately configured for cross-origin requests because the customer interface will normally run on a domain different from the FeedCasket API domain.

CORS must not be configured more broadly than necessary.

Private dashboard APIs must apply appropriate authentication/credential handling.

The implementation must distinguish:

```text
Public feedback submission
```

from:

```text
Authenticated developer dashboard access
```

Do not use a blanket permissive CORS configuration for the entire API without considering its effect on private endpoints.

---

# 17. API Versioning

Application APIs should use a versioned namespace.

Initial convention:

```text
/api/v1/...
```

Examples:

```text
POST /api/v1/feedback
GET  /api/v1/projects
POST /api/v1/projects
GET  /api/v1/projects/:projectId/feedback
PATCH /api/v1/projects/:projectId/feedback/:feedbackId
```

The exact endpoint set will be defined in `docs/API.md`.

Versioning exists so future API changes do not unexpectedly break existing customer integrations.

---

# 18. Idempotency

Feedback submission may be retried by clients because of network failures.

The system should be designed so a client retry does not unnecessarily create duplicate feedback.

Where appropriate, support a client-generated submission/request identifier or an equivalent idempotency mechanism.

The exact implementation should be defined in the API specification.

The database should enforce appropriate uniqueness where necessary.

---

# 19. Usage Accounting

Usage limits must be enforced server-side.

A client must never be able to bypass a project allowance simply by modifying browser code.

Conceptually:

```text
Submission
    ↓
Determine project
    ↓
Determine allowed capacity
    ↓
Atomically validate/update usage where necessary
    ↓
Accept or reject
```

The implementation must consider concurrent requests.

An unsafe pattern such as:

```text
read remaining
↓
if remaining > 0
↓
write remaining - 1
```

without appropriate concurrency protection is not sufficient.

---

# 20. Free Usage

Every new project may receive an initial free allowance.

The allowance should be represented in durable application data.

Usage should be attributable to the project.

The system should eventually support:

```text
Free allocation
+
Purchased allocation
-
Used submissions
=
Available capacity
```

The payment system does not need to exist in the initial foundation.

---

# 21. Payment Architecture

Payment processing is a later subsystem.

Do not add payment-provider dependencies to the initial architecture unless required for the current implementation task.

The data model should be extensible enough to support purchased credits later.

Future payment processing should use verified provider webhooks rather than trusting browser-side success messages.

---

# 22. Dashboard Architecture

The dashboard is a normal authenticated web application.

The dashboard should communicate with FeedCasket through the application API.

Do not make the dashboard directly query D1 from browser code.

Correct:

```text
Browser
   ↓
Authenticated API
   ↓
Worker
   ↓
D1
```

Incorrect:

```text
Browser
   ↓
D1
```

The browser must never receive direct privileged database access.

---

# 23. Feedback Search

MVP search should remain simple.

Searchable fields include:

* Feedback message
* Visitor email
* Page URL
* Page title

The implementation should initially use database capabilities appropriate to the expected MVP data volume.

Do not introduce an external search engine unless the actual product scale requires it.

---

# 24. Read / Unread State

Each feedback item should have a basic state:

```text
unread
read
```

This state belongs to the stored feedback record.

The API must verify ownership before allowing a developer to change the state.

---

# 25. Reply Architecture

The MVP does not require FeedCasket to operate a mail server for replies.

The dashboard should generate a browser email composition action.

Conceptually:

```text
Reply button
     ↓
Recipient = visitor email
Subject = generated subject
Body = generated message
     ↓
Gmail/email compose
```

FeedCasket should not persistently claim delivery of the reply.

The reply was sent by the developer's own email provider.

---

# 26. Failure Isolation

FeedCasket should fail safely.

For example:

```text
Screenshot upload fails
        ↓
Text feedback should still be handled according to the API contract
```

A screenshot-storage problem should not unnecessarily break the entire application.

Similarly:

```text
Dashboard image fails
        ↓
Feedback text remains accessible
```

The system should prefer partial functionality over total failure when safe.

---

# 27. Data Minimization

Do not automatically persist every request header or browser property.

The application should explicitly choose which information is useful.

Potential metadata:

* page URL
* page title
* user-agent
* basic device information
* viewport information
* submission time

Only store fields that are justified by the product.

---

# 28. Secrets and Configuration

Secrets must exist outside Git version control.

Examples include:

* Cloudflare API token
* Authentication secrets
* Email provider secrets if later required
* Payment provider secrets if later required

Use environment variables/secrets supported by the deployment environment.

The repository may contain:

```text
.env.example
```

but must never contain actual secrets.

---

# 29. Development and Production Separation

FeedCasket should distinguish development/test resources from production resources.

At minimum, the architecture must allow separate:

```text
Development
Production
```

configuration.

Development work must not accidentally modify production databases or storage.

Resource identifiers and environment bindings should be explicit.

---

# 30. Database Migrations

D1 schema changes must be version-controlled.

Use migration files stored in the repository.

Conceptually:

```text
migrations/
├── 0001_initial_schema.sql
├── 0002_add_feedback_metadata.sql
└── ...
```

The exact migration filenames and contents will be created as implementation begins.

Do not manually modify production schema without corresponding migration history.

---

# 31. Testing Architecture

Tests should exist at multiple levels where useful.

### Unit tests

Examples:

* Validation
* Authorization logic
* Usage calculations
* Utility functions

### API tests

Examples:

* Feedback submission
* Invalid project
* Unauthorized dashboard access
* Ownership isolation
* Search
* Read/unread
* Error responses

### Integration tests

Examples:

* Worker + D1 behavior
* Screenshot persistence
* Project/feedback relationships

Testing should focus especially on security boundaries and core business logic.

---

# 32. Observability

The application should have enough logging/error visibility to diagnose real failures.

Important events include:

* API failures
* Authentication failures
* Database failures
* Screenshot failures
* Usage enforcement errors
* Unexpected Worker errors

Logs must not unnecessarily expose:

* passwords
* authentication secrets
* API tokens
* sensitive visitor information

Use request/correlation identifiers where useful.

Do not build a giant analytics system for the MVP.

---

# 33. Deployment

Deployment should be reproducible from the repository.

The application should use Wrangler configuration rather than manual undocumented dashboard changes wherever practical.

The deployment process should eventually include:

```text
Install dependencies
        ↓
Typecheck
        ↓
Lint
        ↓
Tests
        ↓
Build if required
        ↓
Deploy Worker
        ↓
Apply appropriate database migrations
```

Production deployment must be deliberate and must not destroy existing resources.

---

# 34. Architecture Evolution

The initial FeedCasket system should be a modular monolith.

Potential future additions may include:

* Queues
* Transactional notifications
* Purchased credits
* Headless SDK
* Advanced spam detection
* AI processing
* Additional integrations
* Teams
* Advanced search

These should be added only when justified.

Do not implement future architecture simply because it might someday be useful.

---

# 35. Non-Goals for the Architecture

The initial architecture must not require:

* VPS
* Kubernetes
* Microservices
* Redis unless a real requirement appears
* Dedicated search cluster
* Custom mail server
* Custom CDN
* Dedicated screenshot-rendering infrastructure
* Large analytics pipeline
* AI infrastructure

The objective is a small production-capable system.

---

# 36. Primary Success Criterion

The architecture is successful when the following real flow works:

```text
Developer
    ↓
Creates account
    ↓
Creates project
    ↓
Receives project/API configuration
    ↓
Builds custom feedback UI
    ↓
Visitor submits feedback
    ↓
Cloudflare Worker receives request
    ↓
Request is validated
    ↓
Rate/abuse protection is applied
    ↓
Usage is checked
    ↓
Feedback is stored in D1
    ↓
Screenshot is stored in R2 if supplied
    ↓
Developer opens authenticated dashboard
    ↓
Real feedback is retrieved from API/D1
    ↓
Developer searches/reads it
    ↓
Developer can open a prefilled Gmail/email reply
```

This end-to-end path is more important than adding a large number of secondary features.
