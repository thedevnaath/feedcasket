# FeedCasket API Specification

## 1. Purpose

This document defines the application API contract for FeedCasket.

The FeedCasket API is implemented by the Cloudflare Worker.

The API provides two broad categories of functionality:

1. Public feedback submission.
2. Authenticated developer/dashboard operations.

The API must use the versioned prefix:

```text
/api/v1
```

The API must return JSON unless otherwise explicitly specified.

---

# 2. Base URL

Production:

```text
https://<feedcasket-api-domain>/api/v1
```

The exact production hostname is determined during deployment.

Development may use the Wrangler local development URL.

The application code must not hardcode a production hostname where configuration is more appropriate.

---

# 3. API Design Principles

The API must be:

* Versioned
* Explicit
* Predictable
* Server-validated
* Multi-tenant safe
* Secure
* Compatible with cross-origin customer websites
* Independent of the customer's frontend framework

The API must not expose D1 directly.

The Cloudflare Worker is the application API layer.

---

# 4. Authentication Model

There are two different authentication categories.

## Public feedback submission

A visitor submitting feedback does NOT authenticate as a FeedCasket user.

The public submission identifies the destination project using its public project identifier.

The project identifier is not a secret.

Additional protections include:

* Domain/origin validation
* Rate limiting
* Abuse protection
* Payload validation
* Usage enforcement

## Developer/dashboard APIs

Developer APIs require authenticated developer access.

The exact authentication provider/mechanism may be selected during implementation.

The API specification intentionally does not require a particular authentication vendor.

The Worker must receive an authenticated identity and use it for authorization.

---

# 5. Public Endpoint

## POST /feedback

Submit feedback to a FeedCasket project.

```text
POST /api/v1/feedback
```

This endpoint is public and must assume that arbitrary clients may call it.

---

## 5.1 Request Format

The endpoint should support:

```text
multipart/form-data
```

This allows text feedback and an optional screenshot to be submitted in one request.

The request must contain:

### Required fields

```text
project_id
message
```

### Optional fields

```text
visitor_email
page_url
page_title
viewport_width
viewport_height
screen_width
screen_height
screenshot
```

---

## 5.2 Example Request

Conceptual browser code:

```javascript
const formData = new FormData();

formData.append("project_id", "PROJECT_PUBLIC_ID");
formData.append(
  "message",
  "The pricing button does not work on mobile."
);

formData.append(
  "visitor_email",
  "visitor@example.com"
);

formData.append(
  "page_url",
  window.location.href
);

formData.append(
  "page_title",
  document.title
);

formData.append(
  "viewport_width",
  String(window.innerWidth)
);

formData.append(
  "viewport_height",
  String(window.innerHeight)
);

const response = await fetch(
  "https://api.example.com/api/v1/feedback",
  {
    method: "POST",
    body: formData
  }
);
```

The exact customer-side integration helper may later simplify this.

---

# 5.3 Server-Derived Information

The API should not require the browser to provide information the Worker can safely derive itself.

For example:

### User agent

Prefer the incoming HTTP `User-Agent` header rather than trusting a client-supplied user-agent field.

### Submission timestamp

Generate the authoritative submission timestamp on the server.

### Origin

Use the request's `Origin` where available for origin/domain validation.

The client must not be able to override the authoritative server timestamp.

---

# 5.4 Feedback Validation

The Worker must validate all fields server-side.

At minimum:

### project_id

* Required
* Valid format
* Must refer to an existing active project

### message

* Required
* Must contain actual content
* Maximum length must be enforced
* Whitespace-only content must be rejected

### visitor_email

When supplied:

* Must be syntactically valid enough for the application's requirements
* Must have a maximum length

### page_url

When supplied:

* Must have a maximum length
* Must be treated as untrusted input

### page_title

When supplied:

* Must have a maximum length
* Must be treated as untrusted input

### viewport/screen values

When supplied:

* Must be validated numeric values
* Must have reasonable bounds

### screenshot

When supplied:

* Must be checked against maximum size
* Must be checked against allowed MIME/file types
* Must not be blindly trusted based solely on the filename or client MIME type

---

# 5.5 Public Request Processing

A feedback request should conceptually pass through:

```text
Request
  ↓
Basic HTTP validation
  ↓
Project validation
  ↓
Origin/domain checks
  ↓
Rate limiting / abuse controls
  ↓
Payload validation
  ↓
Usage/allowance check
  ↓
Screenshot validation/storage if present
  ↓
Feedback persistence
  ↓
Usage update
  ↓
Success response
```

The implementation may combine or reorder internal operations where appropriate.

The security and business rules must remain enforced.

---

# 5.6 Successful Response

Recommended status:

```text
201 Created
```

Example:

```json
{
  "success": true,
  "feedback": {
    "id": "feedback_public_id",
    "created_at": "2026-09-23T12:00:00.000Z"
  }
}
```

Do not return private dashboard information from the public submission endpoint.

The public response should contain only what the submitting client needs.

---

# 5.7 Public API Errors

The API should use meaningful HTTP status codes.

### 400 Bad Request

Malformed or invalid request.

Example:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "The feedback message is required."
  }
}
```

### 403 Forbidden

The project cannot accept the request because the request does not satisfy project access/origin rules.

Example code:

```text
PROJECT_NOT_ALLOWED
```

### 404 Not Found

The referenced project does not exist or is not publicly available.

Do not reveal unnecessary information about private project existence.

### 413 Payload Too Large

Request or screenshot exceeds the allowed size.

### 429 Too Many Requests

Rate limit exceeded.

Example:

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many submissions. Please try again later."
  }
}
```

The API may provide an appropriate `Retry-After` header where useful.

### 500 Internal Server Error

Unexpected server-side failure.

The response must not expose stack traces, SQL statements, credentials, or internal infrastructure details.

---

# 6. Project APIs

Project APIs are authenticated developer APIs.

---

## POST /projects

Create a new FeedCasket project.

```text
POST /api/v1/projects
```

Example request:

```json
{
  "name": "My SaaS",
  "website_url": "https://example.com"
}
```

The server generates the project's unique public identifier.

The client must not choose a project identifier directly.

Possible response:

```text
201 Created
```

Example:

```json
{
  "success": true,
  "project": {
    "id": "internal_project_id",
    "name": "My SaaS",
    "website_url": "https://example.com",
    "project_identifier": "public_project_id",
    "created_at": "2026-09-23T12:00:00.000Z"
  }
}
```

Private internal IDs should not be exposed unnecessarily.

---

# 7. GET /projects

Return projects owned by the authenticated developer.

```text
GET /api/v1/projects
```

Only projects owned by the authenticated user may be returned.

The public project identifier may be included because it is required for integration.

---

# 8. GET /projects/:projectId

Return the details of one project owned by the authenticated developer.

```text
GET /api/v1/projects/:projectId
```

Authorization is mandatory.

A caller must not be able to access the project merely by knowing its ID.

---

# 9. PATCH /projects/:projectId

Update project settings.

```text
PATCH /api/v1/projects/:projectId
```

Possible editable fields include:

```text
name
website_url
allowed_domains
other approved project settings
```

Only fields explicitly supported by the application should be accepted.

The API must reject unsupported or dangerous fields.

---

# 10. DELETE /projects/:projectId

Project deletion is not required for the first implementation milestone.

If implemented later, the deletion model must be explicitly designed around:

* Feedback retention
* Screenshot deletion
* Usage records
* Possible recovery
* Data privacy requirements

Do not implement destructive deletion casually.

---

# 11. Feedback APIs

Developer feedback access is private.

---

## GET /projects/:projectId/feedback

Retrieve feedback belonging to the authenticated developer's project.

```text
GET /api/v1/projects/:projectId/feedback
```

The request must verify:

```text
authenticated user
        ↓
owns project
```

---

# 12. Feedback List Query Parameters

The MVP should support basic pagination.

Recommended parameters:

```text
page
limit
search
status
```

Example:

```text
GET /api/v1/projects/project123/feedback?page=1&limit=25&search=checkout&status=unread
```

The implementation should enforce reasonable limits on `limit`.

Do not allow a client to request an unlimited dataset.

---

# 13. Search

The `search` parameter should initially search relevant fields such as:

* Feedback message
* Visitor email
* Page URL
* Page title

Search should remain simple for the MVP.

Do not introduce an external search engine unless required by actual scale.

---

# 14. Feedback List Response

Example:

```json
{
  "success": true,
  "feedback": [
    {
      "id": "feedback_123",
      "message": "The checkout button does not work.",
      "visitor_email": "visitor@example.com",
      "page_url": "https://example.com/checkout",
      "page_title": "Checkout",
      "status": "unread",
      "created_at": "2026-09-23T12:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 25,
    "total": 1
  }
}
```

The exact pagination implementation may use cursor pagination later if required.

---

# 15. GET /projects/:projectId/feedback/:feedbackId

Retrieve one feedback item.

```text
GET /api/v1/projects/:projectId/feedback/:feedbackId
```

Authorization must verify that:

1. The authenticated user owns the project.
2. The feedback belongs to the project.

The endpoint may return full feedback metadata and screenshot information appropriate for the developer.

---

# 16. PATCH /projects/:projectId/feedback/:feedbackId

Update supported feedback state.

Initial supported operation:

```text
read/unread
```

Example:

```json
{
  "status": "read"
}
```

Supported values:

```text
read
unread
```

The server must reject arbitrary field updates through this endpoint.

---

# 17. Screenshot Access

Screenshots are stored in R2.

The dashboard should not receive privileged R2 credentials.

Screenshot access should use an authenticated application route or another secure access mechanism.

Possible application endpoint:

```text
GET /api/v1/projects/:projectId/feedback/:feedbackId/screenshot
```

The endpoint must:

1. Authenticate the developer.
2. Verify project ownership.
3. Verify feedback ownership.
4. Locate the screenshot.
5. Return the authorized image or an appropriately restricted temporary access response.

The exact delivery mechanism may be selected during implementation.

---

# 18. Usage API

The dashboard needs to display project usage.

Possible endpoint:

```text
GET /api/v1/projects/:projectId/usage
```

Example response:

```json
{
  "success": true,
  "usage": {
    "included": 10,
    "used": 7,
    "remaining": 3
  }
}
```

The final response structure should support future purchased capacity.

Do not expose internal accounting implementation details unnecessarily.

---

# 19. Reply / Gmail

The MVP reply flow does not require a server-side email API.

The dashboard can create a client-side email composition action using:

* Visitor email
* Generated subject
* Generated body

Example conceptual target:

```text
mailto:visitor@example.com
```

or an appropriate Gmail compose URL where practical.

The browser/client must correctly encode subject and body values.

FeedCasket must not falsely claim that the message was delivered.

The developer's email client is responsible for actually sending the email.

---

# 20. Dashboard Authentication

All endpoints under private dashboard functionality require an authenticated developer identity.

The Worker must derive the authenticated identity from the selected authentication mechanism.

The browser must never be trusted to declare:

```text
user_id = ...
```

The server determines the authenticated user.

---

# 21. Authorization Rules

Every private request must enforce resource ownership.

Examples:

```text
GET /projects/A
```

must verify:

```text
current_user owns A
```

And:

```text
GET /projects/A/feedback/B
```

must verify:

```text
current_user owns A
AND
B belongs to A
```

This prevents ID-based data leakage.

---

# 22. CORS Requirements

The public feedback endpoint must support controlled cross-origin browser requests.

The API must return appropriate CORS headers for approved public feedback use.

Do not apply a blanket permissive CORS policy to private dashboard APIs.

Private APIs should use the authentication model appropriate to the dashboard.

The final CORS implementation should account for:

* Origin
* Preflight requests
* Allowed methods
* Allowed headers
* Credentials where applicable

---

# 23. Request Size Limits

The Worker must enforce request-size limits.

At minimum:

* Maximum message size
* Maximum email size
* Maximum URL size
* Maximum title size
* Maximum screenshot size
* Maximum total request size

The limits should be configurable.

Do not rely solely on frontend validation.

---

# 24. Idempotency

Feedback clients may retry requests due to network failures.

The API should support an appropriate idempotency strategy.

A recommended approach is allowing the client to supply a unique submission/request identifier.

For example:

```text
submission_id
```

The backend can use this to prevent accidental duplicate creation during retries.

The exact database constraints and retention behavior should be designed during implementation.

---

# 25. API Security Rules

Never trust these as security credentials:

* project identifier
* visitor email
* page URL
* page title
* browser metadata
* client-provided timestamps
* client-provided user IDs

All submitted fields are untrusted input.

Private resources require authenticated authorization.

The public feedback API requires abuse controls.

---

# 26. API Error Format

Use a consistent error format.

Recommended:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable explanation."
  }
}
```

Do not expose:

* SQL errors
* stack traces
* Cloudflare internal errors
* secrets
* internal paths
* sensitive debugging information

Error codes should be stable enough for client integrations.

---

# 27. Recommended Initial Error Codes

Possible initial codes include:

```text
INVALID_REQUEST
INVALID_PROJECT
PROJECT_NOT_ALLOWED
INVALID_MESSAGE
INVALID_EMAIL
INVALID_URL
INVALID_SCREENSHOT
SCREENSHOT_TOO_LARGE
PAYLOAD_TOO_LARGE
RATE_LIMITED
USAGE_LIMIT_REACHED
UNAUTHORIZED
FORBIDDEN
NOT_FOUND
INTERNAL_ERROR
```

The implementation may add additional codes when necessary.

Do not create dozens of error codes without a real use case.

---

# 28. API Implementation Requirements

The API implementation must:

* Validate all incoming data
* Use parameterized database queries
* Keep private authorization server-side
* Return correct HTTP status codes
* Avoid leaking internal errors
* Enforce request limits
* Enforce project limits
* Enforce usage limits
* Handle concurrent requests safely where business correctness requires it
* Maintain backward compatibility within a version where practical

---

# 29. MVP Endpoint Summary

The initial application should eventually provide at least:

```text
POST   /api/v1/feedback

POST   /api/v1/projects
GET    /api/v1/projects
GET    /api/v1/projects/:projectId
PATCH  /api/v1/projects/:projectId

GET    /api/v1/projects/:projectId/feedback
GET    /api/v1/projects/:projectId/feedback/:feedbackId
PATCH  /api/v1/projects/:projectId/feedback/:feedbackId

GET    /api/v1/projects/:projectId/feedback/:feedbackId/screenshot

GET    /api/v1/projects/:projectId/usage
```

The authentication provider may introduce additional authentication-specific routes or callbacks.

Those routes should be documented separately once the authentication approach is selected.

---

# 30. API Completion Criteria

The API is considered functionally implemented when:

1. A real website can submit feedback.
2. A project is actually validated.
3. The request is rate/abuse protected.
4. Feedback is actually stored in D1.
5. Screenshots are actually stored in R2.
6. Authenticated developers can retrieve their own feedback.
7. Developers cannot retrieve another developer's data.
8. Search works against actual stored data.
9. Read/unread updates persist.
10. Usage is enforced.
11. API errors are predictable.
12. Important security and ownership cases have automated tests.
13. No core endpoint depends on hardcoded/mock data.

---

# 31. Implementation Rule

Do not implement endpoints as frontend demonstrations.

An endpoint is only considered implemented when:

* The Worker exposes the route.
* Input is validated.
* Business rules are enforced.
* Real D1/R2 interactions occur where required.
* Authentication/authorization is enforced where required.
* Appropriate tests exist.
* The API behavior matches this contract.

When a dependency is not yet configured, document the dependency rather than replacing the implementation with fake behavior.
