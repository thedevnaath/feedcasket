# FeedCasket

**Feedback infrastructure for developers.**

FeedCasket is a developer-focused SaaS that lets website developers collect user feedback through their own custom UI while FeedCasket provides the backend infrastructure for receiving, validating, storing, and managing that feedback.

The developer controls the frontend experience.

FeedCasket controls the infrastructure behind it.

---

# 1. Core Concept

A developer builds any feedback interface they want on their website.

For example:

```text
[Give Feedback]
```

could open any custom UI the developer creates.

That UI sends feedback to FeedCasket.

FeedCasket then:

1. Receives the submission.
2. Validates the project and request.
3. Applies abuse/rate protection.
4. Validates the submitted data.
5. Stores the feedback.
6. Stores an attached screenshot when provided.
7. Tracks project usage.
8. Makes the feedback available in the developer dashboard.

The developer can then review the feedback and reply using their own email client/Gmail.

FeedCasket is therefore **infrastructure**, not a mandatory feedback-widget design system.

---

# 2. Product Philosophy

FeedCasket should be:

* Developer-first
* API-first
* Lightweight
* Simple
* Reliable
* Privacy-conscious
* Easy to integrate
* Friendly to AI coding agents
* Minimal rather than feature-heavy

The product should solve one problem extremely well:

> Make it easy for website visitors to send useful feedback without leaving the website.

---

# 3. What FeedCasket Provides

FeedCasket provides the backend and developer-facing systems required to collect feedback.

Core functionality:

* Developer accounts
* Project creation
* Public project identifiers
* Feedback API
* Feedback validation
* Domain/origin controls
* Rate limiting
* Abuse protection
* Feedback storage
* Screenshot storage
* Page/context metadata
* Developer dashboard
* Feedback inbox
* Feedback search
* Read/unread state
* Usage tracking
* Free usage allowance
* Project settings
* Gmail/email-compose reply functionality
* AI-agent installation instructions

---

# 4. What FeedCasket Does NOT Control

The developer controls the feedback interface shown on their website.

FeedCasket does not require the developer to use a particular:

* Button
* Modal
* Form
* Layout
* Color
* Theme
* Animation
* Branding
* Position
* Design system

The developer may build the interface manually or ask an AI coding agent to build it.

The developer's UI communicates with the FeedCasket API.

---

# 5. Target Users

Primary users:

* Indie hackers
* Solo SaaS developers
* Startup founders
* Small development teams
* Web developers
* SaaS developers
* Developers building tools or web applications
* Developers who want feedback infrastructure without building the backend themselves

Secondary users:

* Agencies
* Freelancers
* Developers building custom feedback interfaces
* Developers using AI coding agents

---

# 6. Core User Flow

## Developer

```text
Create FeedCasket account
        ↓
Create project
        ↓
Configure project
        ↓
Receive project/API configuration
        ↓
Build custom feedback UI
        ↓
Connect UI to FeedCasket API
        ↓
Deploy website
```

## Website Visitor

```text
Visits website
        ↓
Uses developer's feedback UI
        ↓
Writes message
        ↓
Optionally enters email
        ↓
Optionally attaches screenshot
        ↓
Submits feedback
```

## FeedCasket

```text
Receive request
        ↓
Validate request
        ↓
Validate project
        ↓
Validate domain/origin where applicable
        ↓
Apply rate/abuse controls
        ↓
Check usage allowance
        ↓
Store feedback
        ↓
Store screenshot if provided
        ↓
Update usage
        ↓
Return response
```

## Developer

```text
Opens FeedCasket dashboard
        ↓
Views feedback
        ↓
Searches feedback
        ↓
Views metadata/screenshot
        ↓
Marks feedback read/unread
        ↓
Clicks Reply
        ↓
Gmail/email compose opens
        ↓
Message is prefilled
        ↓
Developer presses Send
```

---

# 7. Feedback Submission

Every feedback submission must contain:

### Required

* Project identifier
* Feedback message

### Optional

* Visitor email
* Screenshot
* Page URL
* Page title
* Browser/user-agent information
* Device information
* Viewport/screen information

The final server-side schema and validation rules must be defined before implementation of the corresponding feature.

---

# 8. Public Project Identifier

Each project receives a unique public identifier.

Example:

```text
abc123xyz
```

The public project identifier is used to identify where feedback should be sent.

It is NOT:

* a password
* an API secret
* an authentication credential

A public project identifier must never provide access to private project data.

---

# 9. API

The FeedCasket API is the main integration point for customer websites.

The application API should be versioned.

Initial convention:

```text
/api/v1/...
```

The core feedback endpoint is conceptually:

```text
POST /api/v1/feedback
```

The exact request and response schemas should be defined in the API specification before the corresponding implementation is finalized.

The Cloudflare Worker is the application API layer.

Cloudflare's internal D1 management APIs must NOT be exposed as the public FeedCasket application API.

---

# 10. Backend Architecture

FeedCasket is intended to use serverless infrastructure.

Primary architecture:

```text
Customer Website
       │
       │ HTTPS API request
       ▼
Cloudflare Worker
       │
       ├───────────────┐
       ▼               ▼
      D1               R2
   Application       Screenshots
      Data
```

Potential future/background infrastructure may be added only when justified by an actual product requirement.

The architecture should remain simple.

---

# 11. Cloudflare Services

## Cloudflare Workers

Used for:

* HTTP API
* Authentication logic
* Authorization
* Request validation
* Feedback processing
* Project management
* Dashboard API
* Usage enforcement
* Server-side business logic

## Cloudflare D1

Used for relational application data such as:

* Users
* Projects
* Feedback
* Usage/credits
* Notification settings
* Other required relational entities

## Cloudflare R2

Used for:

* Feedback screenshots
* Other required uploaded objects

Binary screenshot data should not be stored directly in D1.

---

# 12. Dashboard

The developer dashboard is a real application backed by the FeedCasket API and D1.

The dashboard must not rely on hardcoded sample data.

The MVP dashboard should contain:

* Project information
* Usage/credits
* Feedback inbox
* Feedback details
* Search
* Read/unread state
* Screenshot viewing
* Visitor email
* Page URL
* Page title
* Technical context
* Project settings
* Account settings as required

The dashboard should intentionally remain simple.

---

# 13. Feedback Inbox

Each feedback item should display useful information such as:

* Feedback message
* Submission date/time
* Visitor email when supplied
* Page URL
* Page title
* Browser/device context
* Viewport/screen context
* Screenshot when supplied
* Read/unread state

Actions should include:

* Open/view feedback
* Mark as read
* Mark as unread
* Open source page
* View screenshot
* Reply

---

# 14. Reply

FeedCasket does not need to send replies through its own mail server for the MVP.

Instead, when the developer presses Reply:

```text
FeedCasket
      ↓
Creates a prefilled email composition
      ↓
Developer's Gmail/email client opens
      ↓
Recipient already filled
      ↓
Subject already filled
      ↓
Body already filled
      ↓
Developer reviews and presses Send
```

FeedCasket should never claim that it sent an email when it merely opened an email composition interface.

The exact implementation should be compatible with the practical capabilities of the browser and Gmail/email client.

---

# 15. Screenshots

Screenshot support is optional.

The basic feedback submission must work without screenshots.

MVP screenshot requirements:

* Upload screenshot
* Validate file type
* Validate file size
* Store object in R2
* Associate screenshot with feedback
* Allow authenticated developer to view it

Do not build advanced automatic webpage screenshot capture in the MVP.

---

# 16. Security

The public feedback API must be assumed to be potentially abused.

Security requirements include:

* Server-side validation
* Authentication for private dashboard APIs
* Authorization for every private resource
* Multi-tenant data isolation
* Request-size limits
* Feedback length limits
* Screenshot limits
* File validation
* Rate limiting
* Abuse prevention
* Safe rendering of submitted content
* HTTPS
* Secret management
* No privileged credentials in customer-side code

A public project identifier must never be sufficient to access private project data.

---

# 17. Rate Limiting

Rate limiting is required because the feedback endpoint is publicly reachable.

Rate limiting should preferably use edge/transient mechanisms.

Do not turn D1 into a permanent database of every rate-limit event or every visitor IP.

D1 should primarily contain durable application data.

Rate limiting should protect:

* individual projects
* the API
* FeedCasket infrastructure
* free usage allowances
* against obvious abuse

IP-based controls should not be treated as a perfect identity system.

---

# 18. Privacy

FeedCasket should minimize data collection.

Collect only information required to operate the product and provide useful feedback context.

Particular care should be taken with:

* visitor email
* screenshots
* browser/device information
* page URLs
* rate-limiting information
* data retention

The product should document what information is collected.

---

# 19. Usage and Credits

The product should provide a free initial allowance.

Usage should be associated with the project.

The system should be able to determine:

* submissions used
* submissions remaining
* whether the allowance has been exhausted
* additional capacity later purchased by the developer

The MVP should support the free allowance.

Payment processing can be implemented later.

Usage accounting must be designed carefully enough that concurrent submissions cannot trivially exceed the available allowance.

---

# 20. Monetization Direction

The intended pricing philosophy is:

* Free to start
* No card required to begin
* Developer can use an initial allowance
* Developer pays only when additional capacity is desired
* Additional feedback capacity may be sold as credit/submission blocks

The exact pricing values are not yet final.

The architecture should allow future credit purchases without requiring a redesign of the entire data model.

---

# 21. AI-Assisted Integration

FeedCasket should be friendly to AI coding agents.

Developers should be able to provide an AI coding agent with:

* FeedCasket documentation
* Project identifier
* API instructions
* Integration instructions

The AI agent should be capable of:

1. Inspecting the existing website.
2. Creating a feedback interface.
3. Matching the existing design.
4. Connecting the interface to the FeedCasket API.
5. Adding only the necessary code.
6. Avoiding unrelated changes.
7. Explaining the integration.

The product should eventually provide a ready-to-copy AI installation prompt.

---

# 22. MVP Scope

The MVP consists of:

### Developer

* Account creation/login
* Project creation
* Project identifier
* Project settings
* Usage visibility

### API

* Feedback submission
* Request validation
* Project validation
* Domain/origin controls
* Rate limiting
* Abuse protection
* Usage enforcement

### Feedback

* Text
* Optional email
* Page URL
* Page title
* Basic browser/device context
* Basic viewport/screen context
* Optional screenshot

### Dashboard

* Feedback inbox
* Feedback details
* Search
* Read/unread
* Screenshot viewing
* Reply via Gmail/email compose

### Infrastructure

* Cloudflare Workers
* D1
* R2
* Versioned database migrations
* Environment configuration
* Automated testing

---

# 23. Explicit MVP Non-Goals

Do not build these unless later requested:

* Mandatory FeedCasket widget
* Complex analytics
* Large chart dashboards
* CRM
* Project-management workflows
* Enterprise permissions
* Team management
* Advanced AI functionality
* Complex moderation
* Large integration marketplace
* Sophisticated referral system
* Advanced screenshot capture
* Real-time dashboard
* Complex billing system
* Payment processing in the initial foundation
* Unnecessary microservices

---

# 24. Product Success

The core technical product is successful when:

1. A developer can create a project.
2. The developer can obtain the required API/project configuration.
3. A custom website UI can submit actual feedback.
4. The real Worker receives the request.
5. The backend validates it.
6. Real feedback is stored in D1.
7. Screenshots are stored in R2 when supplied.
8. The developer can see actual feedback in the dashboard.
9. The developer can search feedback.
10. The developer can mark feedback read/unread.
11. The developer can reply through Gmail/email compose.
12. Rate limits work.
13. Usage is tracked.
14. Private data is properly isolated between developers.
15. Tests cover important backend behavior.

---

# 25. Definition of a Real Implementation

FeedCasket must not be presented as complete when functionality is only:

* a mockup
* hardcoded
* simulated
* represented by placeholder data
* disconnected from the database
* disconnected from the API
* implemented only in the frontend

A completed feature must use the actual intended backend behavior and must be appropriately tested.

When a required external configuration is missing, the implementation must clearly identify that dependency instead of replacing it with fake behavior.

---

# 26. Development Principle

Build the smallest real version of FeedCasket.

Do not optimize for:

> "The demo looks impressive."

Optimize for:

> "The entire flow actually works."

The first meaningful milestone is:

```text
Developer
   ↓
Create project
   ↓
Get project configuration
   ↓
Custom feedback UI
   ↓
POST feedback
   ↓
Cloudflare Worker
   ↓
D1
   ↓
Real dashboard
   ↓
Real feedback
```

Everything else should be built around making that flow reliable, secure, and simple.
