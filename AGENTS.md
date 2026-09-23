# FeedCasket — Agent Instructions

## Project Identity

This repository contains **FeedCasket**, a developer-focused feedback infrastructure SaaS.

FeedCasket allows website developers to build their **own feedback UI** and send feedback to FeedCasket's backend.

FeedCasket is **API/infrastructure-first**.

The MVP must NOT depend on a mandatory FeedCasket-provided feedback widget.

A developer should be able to create any feedback interface they want and connect it to FeedCasket.

---

## Core Product

The core flow is:

Developer
→ creates a FeedCasket project
→ receives a public project identifier and API/integration instructions
→ creates a feedback UI on their own website
→ visitor enters feedback
→ visitor optionally provides an email address
→ visitor optionally attaches a screenshot
→ FeedCasket receives the submission
→ validates the request
→ applies abuse/rate protections
→ stores the feedback
→ developer sees it in the FeedCasket dashboard.

The developer should be able to reply to a visitor directly from the dashboard.

For the initial product, replying should open the developer's email client/Gmail with the recipient, subject, and message body prefilled. FeedCasket does not need to operate a mail server merely to allow developers to reply.

---

## Technical Direction

The intended backend architecture is:

* Cloudflare Workers for the application/API
* Cloudflare D1 for relational application data
* Cloudflare R2 for screenshot/object storage
* TypeScript
* Wrangler for Cloudflare development and deployment

Do not introduce a VPS or unnecessary server infrastructure.

Do not introduce microservices unless a concrete requirement appears.

Keep the architecture as small and maintainable as reasonably possible.

---

## Important Architectural Boundary

FeedCasket provides:

* API
* validation
* authentication
* authorization
* project management
* feedback storage
* screenshot storage
* metadata handling
* rate limiting/abuse protection
* usage tracking
* developer dashboard
* feedback search
* read/unread state
* Gmail/email-compose reply functionality
* future notification infrastructure

The developer's website provides:

* feedback button
* modal/form
* visual design
* styling
* placement
* animations
* accessibility
* any custom feedback UX

Do not build a mandatory FeedCasket widget for the MVP.

---

## Public Project Identifier

Each project has a public identifier.

The public project identifier is NOT a secret.

Never treat it as authentication.

Never expose or embed privileged backend credentials in customer-side code.

The public feedback API must be designed as an intentionally public endpoint and protected using:

* project validation
* allowed-domain/origin validation where appropriate
* request validation
* rate limiting
* request-size limits
* abuse protection
* usage enforcement

---

## Security Rules

Security is a first-class requirement.

Never:

* commit secrets
* hardcode API tokens
* expose Cloudflare credentials to browsers
* expose D1 credentials to browsers
* expose privileged API credentials in customer-side code
* trust a project ID as permission to view private data
* allow one developer to access another developer's data
* render submitted feedback as unsafe HTML
* trust client-provided authorization information
* use client-side checks as a substitute for server-side authorization

Always perform authorization on the server.

Every private resource must ultimately be scoped to the authenticated owner/project.

---

## Multi-Tenancy

FeedCasket is a multi-tenant application.

A developer must only be able to access:

* their own account
* their own projects
* feedback belonging to their projects
* their own project settings
* their own usage/credits

A public project identifier may permit feedback submission to that project according to the API rules, but must NEVER permit access to that project's dashboard data.

---

## Feedback Requirements

A feedback submission must support:

### Required

* message

### Optional

* visitor email
* screenshot

### Context

Where appropriate and privacy-conscious, support:

* page URL
* page title
* browser/user-agent information
* basic device information
* viewport/screen information
* submission timestamp

Only collect information that serves a clear product purpose.

Do not permanently store unnecessary information merely because a browser exposes it.

---

## Screenshot Requirements

Screenshots are optional.

The basic text-feedback flow must work without screenshots.

Screenshots must:

* have a size limit
* have an allowed-format policy
* be validated server-side
* be stored in object storage rather than D1
* be associated with the relevant feedback record
* be access-controlled when viewed from the dashboard

Do not implement sophisticated automatic webpage screenshot capture unless explicitly requested as a later feature.

A normal screenshot attachment/upload is sufficient for the MVP.

---

## Rate Limiting and Abuse Protection

The public feedback endpoint must be treated as an abuse-prone endpoint.

Rate limiting should preferably occur at the edge or through transient infrastructure rather than creating a permanent D1 row for every rate-limit event.

Do NOT design D1 as a database of every visitor IP/request.

The durable database should primarily contain actual product data.

Use appropriate combinations of:

* project-level limits
* request limits
* IP or equivalent transient signals
* origin/domain checks
* payload limits
* abuse controls

Do not rely on IP address alone as a perfect identity mechanism.

---

## Database Rules

Use D1 for relational application data.

The schema should be version-controlled through migrations.

Do not manually modify production database schemas without updating the migration history.

Do not put binary screenshots directly into D1.

The initial schema should be designed around the actual product requirements rather than speculative future features.

---

## Usage and Credits

FeedCasket will have a free allowance and later purchasable feedback capacity.

The system must track:

* submissions used
* remaining allowance/capacity
* project-level usage
* additional purchased capacity later

Do not implement payment processing in the initial foundation task.

Design usage accounting so concurrent requests cannot trivially bypass remaining capacity.

A simple unsafe read-then-write counter is not sufficient where atomicity matters.

---

## Authentication

Developers require authentication for private functionality such as:

* dashboard
* project management
* settings
* usage
* feedback access

Visitors submitting feedback do NOT create FeedCasket accounts.

Do not invent a fake authentication system for demonstration purposes.

Use a real authentication approach suitable for the chosen architecture.

---

## Dashboard

The dashboard is a real application, not a mockup.

It must eventually retrieve data from the real FeedCasket backend/database.

Do NOT implement fake feedback arrays, fake API responses, or hardcoded dashboard records and present them as completed functionality.

The MVP dashboard should include:

* projects
* feedback inbox
* feedback details
* read/unread state
* search
* visitor email where supplied
* page URL
* technical context
* screenshot where supplied
* usage/credits
* basic project settings

---

## Reply Flow

The initial reply experience should be simple.

When a developer clicks Reply:

1. Use the visitor's supplied email address.
2. Generate a useful subject.
3. Generate a prefilled body containing the relevant feedback context.
4. Open the developer's email client/Gmail compose flow.
5. Let the developer review and press Send.

FeedCasket should not pretend it sent the reply itself.

Do not build an SMTP/mail server for this feature.

---

## API Philosophy

The API is part of the product.

API behavior should be:

* explicit
* versionable
* validated
* documented
* predictable
* secure

Prefer a versioned API namespace such as:

`/api/v1/...`

Do not expose Cloudflare's D1 management API as the application's public API.

The Cloudflare Worker should be the application API layer.

---

## Error Handling

Errors must be understandable.

The public API should return appropriate HTTP status codes and machine-readable responses.

The client should receive useful human-readable error information without leaking:

* secrets
* stack traces
* internal infrastructure details
* SQL statements
* sensitive system information

The application should fail gracefully.

A failure in FeedCasket must not intentionally break the host website.

---

## Performance

The product should remain lightweight.

Avoid:

* unnecessary dependencies
* unnecessary network calls
* unnecessary database queries
* unnecessary persistent client-side tracking

Do not build analytics systems unless explicitly required.

---

## Privacy

FeedCasket should follow data minimization principles.

Only collect information necessary to provide the product.

Pay particular attention to:

* visitor email
* screenshots
* page URLs
* browser/device metadata
* IP/rate-limit information
* data retention

Do not permanently store information merely because it is technically available.

---

## Development Standards

Use:

* TypeScript
* strict typing where practical
* clear module boundaries
* reusable server-side validation
* clear error handling
* automated tests for important logic

Prefer simple understandable code over clever abstractions.

Avoid premature abstraction.

Avoid speculative frameworks and dependencies.

---

## Testing Requirements

Important backend behavior must have tests.

At minimum, test:

* project ownership/authorization
* feedback validation
* invalid project handling
* usage enforcement
* rate-limit behavior where practical
* screenshot validation
* API response behavior
* multi-tenant isolation

Do not consider a feature complete merely because the frontend renders.

A feature is complete when the underlying real backend behavior works and is tested appropriately.

---

## Cloudflare Development

Use Wrangler for Cloudflare development and deployment.

Cloudflare resources should be represented in project configuration and reproducible from the repository.

Use D1 migrations for database schema evolution.

Use environment-specific configuration where appropriate.

Do not commit secrets.

Do not hardcode the Cloudflare API token or other credentials.

Do not connect development code to production resources accidentally.

---

## Deployment Safety

Never make destructive production changes unless explicitly requested.

Do not delete production resources as part of routine development.

Do not reset or destroy databases simply to make a development task easier.

Before any destructive operation, stop and inspect the repository/configuration carefully.

---

## Documentation

Important architecture and behavior must be documented in the repository.

As the project develops, maintain documentation covering:

* product requirements
* architecture
* API
* database
* security
* development
* deployment

Do not allow critical architectural decisions to exist only inside conversation history.

---

## Agent Behavior

Before implementing a substantial task:

1. Inspect the repository.
2. Read relevant project documentation.
3. Understand existing code before changing it.
4. Prefer incremental changes.
5. Do not rewrite working code unnecessarily.
6. Do not add unrelated features.
7. Do not create fake implementations simply to make a UI look complete.
8. Run relevant tests/typechecks/linting after changes.
9. Report important assumptions.
10. Clearly identify anything that remains dependent on external configuration or credentials.

When requirements are ambiguous, choose the smallest implementation consistent with the documented product direction rather than inventing a large system.

---

## Current MVP Priorities

The MVP should ultimately achieve this real end-to-end flow:

Developer creates account
→ creates project
→ receives project/API configuration
→ builds or asks an AI coding agent to build a feedback UI
→ visitor submits feedback
→ FeedCasket API validates the request
→ abuse/rate controls are applied
→ feedback is stored in D1
→ screenshot is stored in R2 when supplied
→ usage is updated
→ developer opens dashboard
→ developer sees the actual feedback
→ developer can search it
→ developer can mark it read/unread
→ developer can open a Gmail/email compose response.

Do not expand beyond this core flow without a clear requirement.

---

## Definition of Done

Do not describe a feature as implemented when it is only:

* mocked
* hardcoded
* visually simulated
* represented by placeholder data
* disconnected from the real backend

A feature is implemented when its actual intended behavior works in the application and appropriate tests/documentation exist.

When an external service has not yet been configured, clearly identify it as a dependency instead of replacing it with fake behavior.
