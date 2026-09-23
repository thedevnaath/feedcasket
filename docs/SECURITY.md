# FeedCasket Security Specification

## 1. Purpose

Security is a core requirement of FeedCasket.

FeedCasket exposes a public API that can receive requests from arbitrary websites and potentially arbitrary clients.

The application must therefore assume that:

* public endpoints can be abused
* client-side code can be modified
* project identifiers can be discovered
* requests can be replayed
* submitted content is untrusted
* users may attempt to access another user's data
* uploaded files may be malicious
* external services may fail

Security controls must be enforced server-side.

---

# 2. Security Principles

FeedCasket follows these principles:

1. Never trust the browser.
2. Never treat a public project identifier as a secret.
3. Authenticate private operations.
4. Authorize every private resource.
5. Validate all input on the server.
6. Minimize collected data.
7. Keep privileged credentials server-side.
8. Separate public submission from private dashboard access.
9. Prefer defense in depth rather than relying on one security mechanism.
10. Fail safely without exposing sensitive information.

---

# 3. Trust Boundaries

The main trust boundaries are:

```text
Customer Website
       │
       │ untrusted client request
       ▼
FeedCasket Public API
       │
       │ trusted server-side processing
       ▼
Cloudflare Worker
       │
       ├── D1
       └── R2
```

A second boundary is:

```text
Developer Browser
       │
       │ authenticated request
       ▼
FeedCasket Private API
       │
       ▼
Developer-owned resources
```

The Worker is responsible for enforcing the security rules at these boundaries.

---

# 4. Public Project Identifier

Each project has a public identifier.

The public identifier is intentionally safe to include in customer-side code.

For example:

```text
PROJECT_PUBLIC_ID
```

must NOT be treated as:

* password
* API secret
* authentication token
* authorization credential

Knowing the public identifier must not allow anyone to:

* view feedback
* view screenshots
* view project settings
* view usage
* view account information
* access the dashboard

The only purpose of the public identifier is to identify the project receiving a public feedback submission.

---

# 5. Private Credentials

The following must never be exposed to customer-side JavaScript:

* Cloudflare API token
* Cloudflare account credentials
* D1 credentials
* R2 credentials
* authentication secrets
* session signing secrets
* email provider secrets
* payment provider secrets
* administrative credentials

Secrets must be provided through the deployment/runtime secret mechanism.

Never commit actual credentials to Git.

Never place them in documentation.

Never place them in frontend bundles.

---

# 6. Authentication

Authentication is required for developer-facing private functionality.

Private functionality includes:

* Dashboard
* Project management
* Feedback access
* Feedback search
* Read/unread changes
* Usage information
* Settings
* Screenshot access

Visitors submitting feedback do not need FeedCasket accounts.

The chosen authentication system must provide a genuine server-verifiable authenticated identity.

Do not implement authentication as a frontend-only state.

For example, this is NOT sufficient:

```text
localStorage.loggedIn = true
```

The Worker must be able to verify the authenticated identity.

---

# 7. Authorization

Authentication alone is not sufficient.

Every private request must verify resource ownership.

Example:

```text
Authenticated User A
        ↓
Requests Project B
        ↓
Worker checks ownership
        ↓
Project B belongs to User B
        ↓
Reject
```

Authorization must happen on the server.

Never trust:

* user_id supplied by browser
* project owner supplied by browser
* project ID alone
* feedback ID alone

---

# 8. Multi-Tenant Isolation

FeedCasket is a multi-tenant SaaS.

The application must guarantee logical isolation between users.

For example:

```text
User A
 └── Project A
      └── Feedback A

User B
 └── Project B
      └── Feedback B
```

User A must never be able to access Feedback B.

Every private database query must be constrained through the authenticated ownership relationship where applicable.

Unsafe:

```text
SELECT * FROM feedback WHERE id = ?
```

when used for private access without verifying ownership.

Safer conceptual pattern:

```text
SELECT feedback.*
FROM feedback
JOIN projects
  ON projects.id = feedback.project_id
WHERE feedback.id = ?
  AND projects.user_id = ?
```

The exact SQL implementation can vary, but the ownership check must exist.

---

# 9. Public Feedback API

The public endpoint is intentionally unauthenticated at the FeedCasket-user level.

Therefore it must be treated as an abuse-prone endpoint.

Required protection layers include:

```text
Request
  ↓
Basic validation
  ↓
Project validation
  ↓
Domain/origin controls
  ↓
Rate limiting
  ↓
Payload validation
  ↓
Usage enforcement
  ↓
Persistence
```

The exact implementation may combine steps where appropriate.

---

# 10. Rate Limiting

Rate limiting protects:

* FeedCasket infrastructure
* projects
* database capacity
* free allowances
* customers from spam

Prefer edge/transient mechanisms where practical.

Do not create a permanent D1 row for every rate-limit event.

Do not use D1 as a high-volume request counter.

Do not permanently store every visitor IP solely because it was used for rate limiting.

The exact limits should be configurable.

The initial system should support protection at appropriate levels, such as:

* per client/IP-related signal
* per project
* global/API level

IP address is an abuse-control signal, not a perfect identity.

---

# 11. Domain and Origin Validation

Projects may define allowed domains.

Example:

```text
example.com
www.example.com
app.example.com
```

The public API should inspect browser origin information where available and compare it against the project's allowed domains.

Domain validation helps prevent obvious misuse of a project's public identifier.

However, it is NOT a cryptographic security boundary.

Non-browser clients can construct requests independently.

Therefore domain validation must be combined with:

* rate limiting
* project validation
* usage enforcement
* payload limits
* abuse controls

---

# 12. CORS

The public feedback endpoint must support legitimate cross-origin browser usage.

CORS configuration must be deliberate.

Do not automatically apply a broad wildcard policy to the entire API.

The application must distinguish between:

### Public feedback API

Needs controlled cross-origin access.

### Private dashboard API

Requires authenticated access and should not be exposed through an unnecessarily permissive CORS policy.

Handle appropriately:

* Origin
* OPTIONS/preflight
* Allowed methods
* Allowed headers
* Credentials where applicable

---

# 13. Input Validation

Every client-supplied field is untrusted.

Validate all input server-side.

This includes:

* project identifier
* feedback message
* email
* page URL
* page title
* viewport values
* screen values
* screenshot
* search parameters
* project configuration
* allowed domains
* feedback status updates

Frontend validation is useful for user experience but is never a security mechanism.

---

# 14. Feedback Message Security

Feedback is arbitrary user-generated text.

The application must:

* enforce maximum length
* reject invalid requests
* store it as data
* safely escape it when rendering
* avoid interpreting it as HTML
* avoid executing embedded scripts

Never render submitted feedback using unsafe raw HTML unless there is a deliberate, reviewed sanitization process.

Default rendering should treat feedback as plain text.

---

# 15. XSS Protection

Potential XSS entry points include:

* feedback messages
* visitor email
* page title
* page URL
* project names
* filenames
* allowed-domain values
* dashboard search results

All untrusted values must be safely encoded before being inserted into HTML.

React/framework escaping must not be bypassed unnecessarily.

Do not use dangerous raw HTML rendering for user-controlled data without a demonstrated requirement.

---

# 16. SQL Injection Protection

Never build SQL by concatenating untrusted request strings.

Do not do:

```text
"SELECT * FROM feedback WHERE message LIKE '%" + search + "%'"
```

Use parameterized SQL/bind parameters.

All database queries involving user input must use safe parameter binding.

---

# 17. URL Security

Submitted page URLs are untrusted data.

Do not automatically assume every submitted URL is safe to navigate to.

When creating clickable dashboard links:

* validate/normalize where appropriate
* handle unsafe schemes
* do not allow `javascript:` or similarly dangerous schemes
* safely encode displayed URLs

The original submitted URL may be stored as data even when its value is not suitable for a clickable navigation action.

---

# 18. Email Security

Visitor-provided email addresses are untrusted.

Validate syntax and length.

When constructing a reply action:

* correctly encode the address
* correctly encode subject
* correctly encode message body
* do not inject uncontrolled headers

The visitor's email must not be treated as an authenticated identity.

---

# 19. Screenshot Security

Screenshots are untrusted uploaded files.

Required controls:

* maximum size
* allowed file types
* server-side validation
* safe object naming
* no use of original filename as storage path
* authenticated dashboard access
* controlled retrieval
* appropriate content-type handling

Do not rely exclusively on the browser's reported MIME type.

Do not assume that a filename ending in `.png` is actually a valid PNG.

The implementation should use appropriate server-side validation for the supported upload formats.

---

# 20. Screenshot Object Keys

Never construct an R2 object key directly from an uploaded filename.

Unsafe:

```text
uploads/<original_filename>
```

Prefer an internally generated key, for example:

```text
projects/<project-id>/feedback/<feedback-id>/<random-id>
```

The actual naming scheme can vary.

The important rules are:

* server generated
* deterministic enough for retrieval
* no path traversal behavior
* no direct trust of client filenames

---

# 21. Screenshot Access Control

Screenshots are private project data.

A user who knows or guesses an object key must not automatically gain access.

The application should authorize screenshot access through FeedCasket.

Conceptually:

```text
Developer request
      ↓
Authenticate
      ↓
Verify project ownership
      ↓
Verify feedback ownership
      ↓
Authorize screenshot
      ↓
Return screenshot
```

Do not expose permanent unrestricted object URLs from R2 for private screenshots unless there is a separately reviewed reason.

---

# 22. Upload Limits

Enforce limits before expensive processing where possible.

At minimum define limits for:

* total request size
* message length
* email length
* URL length
* title length
* screenshot size

The exact values should be configuration rather than scattered magic numbers.

Large uploads should be rejected early.

---

# 23. Content-Type Handling

Do not trust client-supplied content types blindly.

For screenshot uploads:

1. Inspect declared content type.
2. Validate extension where useful.
3. Perform appropriate content/file validation.
4. Reject unsupported or suspicious files.

Only explicitly supported image types should be accepted.

---

# 24. Replay and Duplicate Requests

Clients may retry because of network failures.

FeedCasket should support an idempotency strategy for feedback submission.

A unique client/request submission identifier should prevent accidental duplicate creation when the same submission is retried.

Idempotency keys are not authentication credentials.

---

# 25. Usage Enforcement Security

The free allowance is a business/security boundary.

The browser must never be able to bypass it.

For example, changing:

```text
remaining = 0
```

in browser JavaScript must have no effect.

The Worker must determine whether the project can accept a new submission.

Usage updates must be concurrency-safe.

---

# 26. Race Conditions

Important operations must consider concurrent requests.

Examples:

* Two submissions consume the final available credit.
* Two requests update the same feedback state.
* Multiple project updates occur simultaneously.
* Screenshot metadata is created twice.

Do not assume a request will always run alone.

Use database constraints, transactions, or atomic operations where appropriate.

---

# 27. Idempotency and Database Constraints

Where duplicate creation is unacceptable, the database should enforce appropriate uniqueness.

Application checks alone can race.

For example:

```text
Request A checks submission_id
Request B checks submission_id
Both see "not found"
Both insert
```

A unique constraint can provide the final integrity boundary.

---

# 28. Authentication Session Security

The selected authentication implementation must consider:

* session expiration
* secure cookies or equivalent secure session transport
* CSRF where applicable
* logout/invalidation
* account recovery
* email verification where applicable
* protection against session fixation
* secure redirect handling

Do not store long-lived privileged authentication tokens in unsafe browser storage unless the selected authentication architecture explicitly requires and secures that mechanism.

---

# 29. CSRF

Evaluate CSRF protection for all state-changing authenticated browser requests.

Particular attention should be given to:

* project creation
* project updates
* feedback status updates
* settings changes

The final approach depends on the authentication architecture.

SameSite cookie settings, CSRF tokens, or an equivalent secure design may be appropriate.

Do not assume CSRF is irrelevant simply because the API uses JSON.

---

# 30. Password Handling

If the selected authentication solution manages passwords:

* never store plaintext passwords
* do not invent custom password hashing
* follow the authentication provider's secure implementation
* use established password recovery mechanisms

Prefer a reputable authentication solution over building password security manually.

---

# 31. Secret Management

Secrets must be injected through the runtime/deployment secret system.

Examples:

```text
CLOUDFLARE_API_TOKEN
authentication secrets
email provider secrets
payment provider secrets
```

Real secret values must never be committed to Git.

`.env.example` may contain variable names with empty values.

---

# 32. Logging Security

Logs must not unnecessarily contain:

* authentication tokens
* Cloudflare API tokens
* passwords
* session secrets
* payment secrets
* complete private screenshots
* unnecessary visitor personal information

Use request/correlation IDs for debugging without exposing sensitive values.

---

# 33. Error Response Security

Production API errors must not expose:

* stack traces
* source code paths
* SQL queries
* database structure
* Cloudflare credentials
* internal environment values
* authentication details

Return a stable public error code and human-readable message.

Internal logs can contain additional diagnostic information where appropriate and safely handled.

---

# 34. Account Enumeration

Do not unnecessarily reveal whether another developer's account, project, or private resource exists.

For private endpoints, unauthorized access should not leak resource details.

The implementation should use appropriate `401`, `403`, and `404` behavior based on the endpoint and security considerations.

---

# 35. Public Project Enumeration

Public project identifiers should be difficult to guess.

Generate identifiers with sufficient randomness.

Do not use simple sequential IDs such as:

```text
1
2
3
4
```

for customer-facing project identifiers.

The public identifier is still not a secret, but making it unpredictable reduces casual enumeration and accidental collisions.

---

# 36. Data Minimization

Do not permanently store every piece of browser information.

The default collection should remain limited to useful product context.

Potential metadata includes:

* page URL
* page title
* user-agent
* basic device information
* viewport information
* submission timestamp

Only persist information that has a clear product purpose.

---

# 37. IP Address Handling

If IP information is used for abuse controls, avoid automatically making it a permanent feedback field unless there is a demonstrated need.

Prefer transient or edge-level usage for rate limiting where practical.

If an IP address is ever stored, document:

* why it is stored
* retention period
* who can access it
* why it is needed

The product should minimize persistent personal information.

---

# 38. Privacy and Data Retention

The security architecture must support future privacy requirements.

The system should eventually have clearly defined policies for:

* feedback retention
* screenshot retention
* account deletion
* project deletion
* visitor email retention
* logs
* abuse-control data

Do not create permanent data retention accidentally simply because data is easy to store.

---

# 39. Dependency Security

Use dependencies deliberately.

Avoid unnecessary packages.

Keep dependencies reasonably current.

Before adopting a package, consider:

* maintenance status
* security history
* package size
* whether the functionality is actually needed

Do not add large dependencies for trivial functionality.

---

# 40. Cloudflare Security Boundary

Cloudflare credentials are infrastructure credentials.

They must only be available to trusted development/deployment environments.

The browser must never receive:

```text
CLOUDFLARE_API_TOKEN
```

or equivalent infrastructure credentials.

The Worker itself should access D1/R2 through server-side bindings rather than exposing those credentials to clients.

---

# 41. Environment Separation

Maintain distinct development and production resources/configuration.

A development task must not accidentally:

* delete production data
* overwrite production databases
* overwrite production R2 objects
* deploy unintended code to production

Production operations should be deliberate.

---

# 42. Deployment Security

Before production deployment:

* typecheck
* lint
* run automated tests
* verify environment configuration
* verify secrets are configured
* verify database migration state
* verify production bindings
* verify allowed domains
* verify API routes
* verify authentication
* verify screenshot access controls

Do not treat a successful build as proof of production safety.

---

# 43. Abuse Scenarios to Test

The implementation should explicitly test scenarios such as:

### Scenario 1

Attacker sends feedback using a valid public project ID from an unauthorized domain.

Expected:

```text
Reject according to project/domain/abuse policy.
```

### Scenario 2

Attacker sends thousands of submissions rapidly.

Expected:

```text
Rate/abuse protection limits requests.
```

### Scenario 3

User A changes a project ID in a dashboard request to User B's project.

Expected:

```text
Access denied.
```

### Scenario 4

User A changes a feedback ID to User B's feedback.

Expected:

```text
Access denied.
```

### Scenario 5

Attacker uploads an oversized screenshot.

Expected:

```text
Rejected before unsafe/expensive processing.
```

### Scenario 6

Attacker uploads an unsupported or malicious file.

Expected:

```text
Rejected.
```

### Scenario 7

Two requests attempt to consume the final project credit simultaneously.

Expected:

```text
Business rules remain correct.
```

### Scenario 8

Visitor submits HTML/script content.

Expected:

```text
Stored as text and safely rendered.
```

### Scenario 9

Visitor supplies a dangerous URL.

Expected:

```text
Stored safely; dashboard does not execute or navigate unsafely.
```

### Scenario 10

A client retries the same submission.

Expected:

```text
Idempotency mechanism prevents accidental duplication where applicable.
```

---

# 44. Secure-by-Default Rules

The implementation should prefer:

* deny by default
* explicit authorization
* explicit allowed domains
* explicit allowed file types
* explicit request limits
* explicit CORS behavior
* explicit public/private API separation

Avoid broad permissions simply because they make development easier.

---

# 45. What Security Does NOT Mean

Do not over-engineer the MVP.

The application does not need:

* custom cryptographic algorithms
* a custom identity provider
* a custom mail server
* a complex intrusion-detection platform
* a large security analytics pipeline
* dozens of microservices

Use established platform capabilities and standard security practices.

---

# 46. Security Completion Criteria

Security is not considered complete merely because HTTPS is enabled.

Before MVP launch, verify:

1. Private dashboard APIs require real authentication.
2. Every private resource checks ownership.
3. Public project identifiers cannot access private data.
4. Feedback input is validated.
5. Feedback is safely rendered.
6. SQL uses parameterized queries.
7. Screenshot uploads are validated and limited.
8. Screenshot access is authorized.
9. Rate limiting is active.
10. Usage limits are enforced server-side.
11. Concurrent usage cannot trivially bypass limits.
12. Secrets are not in the repository or browser.
13. CORS is deliberately configured.
14. Authentication/session protections are implemented.
15. Important abuse scenarios have tests.
16. Error responses do not leak sensitive internals.
17. Development and production resources are separated.
18. Sensitive logs are minimized.

---

# 47. Security Implementation Rule

Security requirements in this document are implementation requirements, not suggestions.

If a feature cannot yet satisfy its necessary security boundary, it must not be presented as production-ready.

Do not replace missing security functionality with:

* frontend checks
* comments
* placeholders
* mocked validation
* hardcoded authorization
* fake rate limiting

A security control must actually execute in the real application.
