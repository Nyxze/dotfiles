---
name: repository-architecture
description: Analyze an existing repository and produce a self-contained architecture.html documenting its structure, components, dependencies, runtime flows, data, APIs, integrations, configuration, build, tests, deployment, and developer navigation. Use when documenting an unfamiliar codebase, reverse-engineering an application's architecture, creating architecture documentation, onboarding developers to a repository, or explaining how a repository works. Include focused technical diagrams when they materially improve understanding.
---

# Repository Architecture

Produce a self-contained `architecture.html` from the repository's actual implementation.

The HTML must function as a technical architecture reference and developer navigation guide.

It should explain:

- what the system does
- how it is structured
- how its components interact
- how important runtime flows work
- how data moves through the system
- how external systems are integrated
- how the application is configured
- how it is built, tested, and deployed
- where developers should look when modifying the system

The analysis is evidence-driven. Source code, configuration, tests, build files, infrastructure, and CI/CD definitions take precedence over README claims or conventional architecture assumptions.

---

## Output Contract

The primary output is:

```text
architecture.html
```

The file must be directly viewable in a modern browser without requiring a build step.

Prefer a self-contained HTML document:

- HTML structure in the document
- CSS embedded in `<style>`
- JavaScript embedded in `<script>`
- no unnecessary external dependencies
- diagrams rendered or embedded in a reproducible way
- no external assets required for basic viewing

The document should remain useful when opened locally.

### Required HTML capabilities

Implement when useful:

- sticky sidebar navigation
- table of contents
- anchor-based section navigation
- responsive layout
- code/path highlighting
- copy-to-clipboard for repository references
- collapsible technical details
- diagram containers
- badges for technologies and component types
- visual distinction between observations, interpretations, and recommendations
- print-friendly styling

Do not add interactions merely for decoration.

---

# Visual Design

The HTML should resemble a premium technical documentation site rather than a generated Markdown report.

Use a visual direction described as:

> **Dark technical documentation / engineering blueprint**

The visual language should combine the geometric precision of Manim-inspired diagrams with the clarity of modern engineering documentation.

## Visual principles

Use:

- dark-first presentation
- clean geometric shapes
- precise alignment
- generous spacing
- strong typographic hierarchy
- concise labels
- clear directional relationships
- restrained color usage
- subtle borders
- minimal shadows
- minimal decoration
- progressive disclosure

Avoid:

- generic SaaS dashboard aesthetics
- excessive gradients
- excessive rounded cards
- decorative illustrations
- stock imagery
- unnecessary icons
- excessive colors
- visual noise
- oversized headings that waste screen space

The interface should feel technical, precise, calm, and information-dense without becoming difficult to scan.

## Color system

Prefer a dark palette based on near-black / dark-blue-gray surfaces.

Example palette:

```css
--background: #0b0d10;
--surface: #11151a;
--surface-elevated: #171c22;
--border: #252c34;
--text: #e6eaf0;
--text-muted: #8b95a3;
--accent: #5cc8ff;
```

Use a restrained accent color for:

- important links
- selected navigation items
- diagram highlights
- architectural boundaries

Use additional colors only when they encode meaning, such as:

- warning
- uncertainty
- external boundary
- asynchronous behavior

Do not assign arbitrary colors to every component.

---

# Page Structure

Use a persistent navigation sidebar on larger screens.

Example:

```text
ARCHITECTURE

Overview
Repository
Components
Interactions
Flows
Data
APIs
Integrations
Configuration
Deployment
Patterns
Developer Guide
Observations
```

The main content area should contain the architecture analysis.

The page header should provide a concise system overview.

Example:

```text
REPOSITORY ARCHITECTURE

my-application

TypeScript · Node.js · PostgreSQL

12 modules    47 routes    8 integrations    3 traced flows
```

Only display metrics that can actually be derived from the repository.

---

# Architecture Overview

Start with a concise overview containing:

- repository/project name
- primary technologies
- architectural summary
- major components
- external systems
- primary persistence systems
- key architectural characteristics

Include a high-level architecture diagram when useful.

The overview should allow a developer to understand the system's shape within a few minutes.

---

# Repository Reconnaissance

Start with the repository structure before forming architectural conclusions.

Inspect enough of the repository to establish:

- primary languages and frameworks
- runtime and build system
- application entry points
- major source directories
- package/module boundaries
- configuration
- persistence
- APIs and interfaces
- external integrations
- tests
- CI/CD
- containers and infrastructure
- scripts and developer tooling

Prioritize files that reveal runtime behavior and dependency boundaries.

Do not treat directory names as architectural boundaries until their contents support that interpretation.

---

# Architecture Reconstruction

Reconstruct the smallest useful architectural model supported by the implementation.

Identify:

- major components
- responsibilities
- public interfaces
- dependencies
- important data structures
- persistence boundaries
- external boundaries
- synchronous communication
- asynchronous communication
- initialization and bootstrap paths

For important components, expose concrete repository references.

Example:

```text
src/orders/application/OrderService.ts
OrderService.createOrder()
```

The HTML should make important paths easy to copy.

Do not invent components, responsibilities, dependencies, runtime behavior, or architectural intent.

---

# Entry Points

Find the actual execution entry points.

Consider:

- HTTP servers
- REST/GraphQL handlers
- CLI commands
- workers
- scheduled jobs
- queue consumers
- event handlers
- serverless handlers
- application bootstrap code

For each important entry point, explain:

- location
- trigger
- initialization
- major downstream components

Connect entry points to the rest of the architecture through diagrams or flow descriptions when useful.

---

# Runtime Flows

Trace at least three meaningful end-to-end flows when the repository exposes enough functionality.

Prefer important flows such as:

- authentication
- resource creation
- resource retrieval
- mutation workflows
- background processing
- event publication
- queue consumption
- external API calls
- scheduled processing

Follow actual implementation paths.

Each flow should identify:

1. trigger
2. entry point
3. major components
4. important transformations
5. persistence
6. external calls
7. asynchronous boundaries
8. resulting response or state

Example:

```text
HTTP request
    ↓
Router
    ↓
Controller
    ↓
Application service
    ↓
Repository
    ↓
Database
```

Use concrete symbols and paths in the explanation.

Prefer focused sequence/flow diagrams over generic prose when the flow contains meaningful interactions.

---

# Data Architecture

Inspect how data is actually represented and persisted.

Look for:

- domain models
- entities
- DTOs
- schemas
- migrations
- repositories
- ORM mappings
- serializers
- caches
- message payloads
- file/object storage

Document important transformations and boundaries.

Where relevant, distinguish:

```text
Request
  ↓
DTO
  ↓
Domain model
  ↓
Persistence model
  ↓
Database
```

Do not infer business ownership or semantics without evidence.

---

# APIs and Interfaces

Document important interfaces exposed by the repository:

- HTTP routes
- GraphQL operations
- RPC interfaces
- CLI commands
- events
- messages
- webhooks
- public library interfaces

Connect important interfaces to their concrete implementations.

Example:

```text
POST /orders
    ↓
OrderController.create()
    ↓
OrderService.createOrder()
```

Avoid documenting every trivial endpoint if doing so would obscure the architecture.

---

# External Integrations

Identify meaningful boundaries with external systems.

For each integration, document:

- purpose
- client/adapter implementation
- configuration source
- authentication mechanism at a non-secret level
- request/response or message flow
- retry/error behavior when visible
- synchronous/asynchronous behavior

Never expose:

- API keys
- tokens
- passwords
- private keys
- credentials
- secrets
- sensitive connection strings

Use placeholders when configuration examples are necessary.

---

# Configuration and Environments

Trace configuration from its source to its consumers.

Inspect:

- environment variables
- configuration modules
- configuration files
- CLI arguments
- feature flags
- environment-specific configuration
- secret references

Document only environment differences that can be established from repository evidence.

---

# Build, Test, and Deployment

Inspect:

- package/build manifests
- scripts
- Dockerfiles
- compose files
- CI/CD workflows
- infrastructure-as-code
- deployment manifests
- test configuration

Explain the observable path from source to execution/deployment.

Example:

```text
Source
  ↓
Build
  ↓
Tests
  ↓
Artifact
  ↓
Container
  ↓
Deployment
```

Include concrete commands when defined by the repository.

Do not invent infrastructure that is not present.

---

# Architectural Patterns

Identify architectural patterns only when implementation evidence supports them.

Possible patterns include:

- layered architecture
- modular monolith
- microservices
- hexagonal architecture
- clean architecture
- MVC
- repository pattern
- dependency injection
- adapter pattern
- facade
- middleware/pipeline
- event-driven architecture
- CQRS

For every identified pattern, provide evidence.

Use:

```text
OBSERVED
Directly supported by source code or configuration.

INTERPRETATION
A conclusion derived from implementation evidence.

RECOMMENDATION
A potential improvement or area worth investigating.
```

Do not label an architecture merely because directory names resemble a known pattern.

---

# Diagrams

Use diagrams when they communicate architecture more efficiently than prose.

Prefer several focused diagrams over one large diagram.

Useful diagrams include:

- system context
- component architecture
- request/response flow
- sequence flow
- asynchronous flow
- data flow
- deployment topology
- integration boundaries

Prefer Mermaid when the diagram can be represented clearly and reproducibly.

Use SVG or generated visuals when Mermaid cannot provide sufficient layout control or visual clarity.

## Diagram style

Use a Manim-inspired technical visual language:

- geometric shapes
- precise alignment
- generous spacing
- clear arrows
- concise labels
- progressive storytelling
- restrained colors
- strong hierarchy
- minimal decoration

Suggested semantics:

```text
Rectangle       Application component
Cylinder        Database / storage
Cloud           External system
Queue           Asynchronous transport
Solid arrow     Direct interaction
Dashed arrow    Indirect / asynchronous interaction
```

Adapt these semantics when another representation is clearer.

Every diagram must answer a specific architectural question.

Avoid:

- giant UML diagrams
- unreadable dependency graphs
- decorative diagrams
- screenshots when a diagram is sufficient
- diagrams containing unsupported relationships

---

# Component Cards

For major components, use compact visual cards containing:

- component name
- type
- location
- responsibility
- important symbols
- dependencies
- dependents

Example:

```text
┌──────────────────────────────────────────┐
│ ORDER SERVICE                       APP  │
│                                          │
│ src/orders/application/OrderService.ts  │
│                                          │
│ Coordinates order creation and validation│
│                                          │
│ DEPENDS ON                               │
│ OrderRepository · PaymentService         │
│                                          │
│ USED BY                                  │
│ OrderController                          │
└──────────────────────────────────────────┘
```

Do not turn every file into a card. Use cards only for architecturally meaningful components.

---

# Developer Navigation

Include a dedicated developer-oriented section.

Answer practical questions such as:

- Where should a new endpoint be added?
- Where should business logic be implemented?
- Where should persistence logic go?
- Where should an external integration be added?
- Where are background jobs defined?
- Where are events published or consumed?
- Where is configuration defined?
- Where are tests located?
- Where should investigation begin for a new feature?

Use concrete repository paths and symbols.

Example:

```text
NEW API ENDPOINT

1. Route
   src/api/routes/

2. Controller
   src/api/controllers/

3. Business logic
   src/orders/application/

4. Persistence
   src/orders/infrastructure/

5. Tests
   test/orders/
```

This section should be based on observed repository conventions, not generic framework conventions.

---

# Evidence and Uncertainty

Separate repository facts from interpretations.

Use explicit visual treatments in the HTML.

### Observed

Directly supported by source code or configuration.

### Interpretation

A conclusion derived from implementation evidence.

### Recommendation

A possible improvement or area worth investigating.

### Unknown

Information that cannot be established from the repository.

Use:

> Not determinable from the repository.

Do not silently fill missing information with conventional assumptions.

---

# Repository References

Make repository references visually identifiable.

For important references, display:

```text
src/orders/application/OrderService.ts
OrderService.createOrder()
```

Prefer adding:

- copy buttons
- syntax highlighting where relevant
- GitHub links when the repository origin is known
- line references when reliably available

Do not generate links that cannot be verified.

---

# HTML Interaction

Keep interactions purposeful.

Useful interactions include:

- sidebar navigation
- section collapse/expand
- copy path
- copy symbol
- diagram focus
- search within the document
- light/dark mode if it does not complicate the document
- print/PDF layout

Interactions must degrade gracefully when JavaScript is unavailable.

Core information must remain readable as static HTML.

---

# Documentation Structure

The generated document should generally contain:

1. Executive Summary
2. Technology Stack
3. Architecture Overview
4. Repository Structure
5. Main Components
6. Component Interactions
7. Runtime Flows
8. Data Architecture
9. APIs and Interfaces
10. External Integrations
11. Configuration and Environments
12. Build, Test, and Deployment
13. Architectural Patterns
14. Developer Navigation
15. Observations, Interpretations, and Recommendations
16. Known Limitations

Sections may be omitted when the repository does not contain the corresponding concept.

Do not pad the document to satisfy the outline.

---

# Evidence Rules

For significant architectural conclusions, prefer:

### High confidence

Directly visible in source code or configuration.

### Medium confidence

Strongly implied by multiple implementation details.

### Low confidence

Reasonable interpretation with incomplete evidence.

Low-confidence conclusions must be explicitly qualified.

---

# Security

Never expose repository secrets in the generated HTML.

Before finalizing:

- scan configuration examples for credentials
- redact tokens
- redact API keys
- redact passwords
- redact private keys
- redact sensitive connection strings
- replace secret values with placeholders

Do not include `.env` contents unless all sensitive values have been removed.

---

# Validation

Before finalizing `architecture.html`, verify:

- [ ] Major source areas were inspected
- [ ] Entry points were identified
- [ ] Important dependencies were traced
- [ ] At least three meaningful flows were traced when possible
- [ ] Persistence and data boundaries were inspected
- [ ] External integrations were inspected
- [ ] Configuration was inspected
- [ ] Tests and build tooling were inspected
- [ ] Deployment/infrastructure was inspected when present
- [ ] Important claims contain concrete repository references
- [ ] Observed facts are separated from interpretations
- [ ] Unknowns are explicitly stated
- [ ] Diagrams correspond to real repository behavior
- [ ] No secrets are exposed
- [ ] The HTML works when opened locally
- [ ] Navigation works
- [ ] Diagrams remain readable
- [ ] The document is usable on both desktop and smaller screens
- [ ] Print/PDF output remains legible

The final document must describe the architecture supported by repository evidence, not an idealized or assumed architecture.