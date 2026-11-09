---
name: repository-architecture
description: Analyze an existing repository and produce a self-contained architecture.html covering components, runtime flows, data, interfaces, deployment, and developer navigation. Use for repository architecture documentation and onboarding guides.
---

# Repository architecture

Produce `architecture.html` from implementation evidence. The document is a
technical reference and navigation guide for developers unfamiliar with the
repository. Source code, configuration, tests, build files, and infrastructure
take precedence over README claims and conventional architecture assumptions.

## Inspect and reconstruct

Start with the repository structure, then trace the smallest architectural model
supported by its contents. Do not infer module boundaries from directory names.
For significant findings, record concrete paths, symbols, and verified line
references. Separate observed facts, interpretations, recommendations, and
unknowns; say when a fact is not determinable from the repository.

Inspect the applicable areas:

| Area | Establish from implementation |
| --- | --- |
| Entry points | Trigger, initialization, and downstream components for servers, CLIs, workers, jobs, and handlers. |
| Components | Responsibility, public interfaces, dependencies, dependents, and key symbols. |
| Data | Models, schemas, migrations, serialization, persistence, caching, messages, and transformations. |
| Interfaces | Important routes, commands, events, webhooks, and library APIs connected to implementations. |
| Integrations | Purpose, adapter, configuration, authentication mechanism, retries, errors, and sync/async boundaries. |
| Configuration | Sources, consumers, feature flags, environment differences, and secret references without values. |
| Delivery | Actual build commands, test suites, CI, containers, and deployment/infrastructure when present. |

Trace at least three meaningful end-to-end flows when the repository exposes
enough functionality. Identify each trigger, entry point, major component,
transformation, persistence operation, external call, asynchronous boundary, and
resulting response or state. Use concrete symbols, not a generic layered diagram.

Name architectural patterns only when evidence supports them. Qualify conclusions
based on incomplete evidence. Do not invent infrastructure, relationships, or
business semantics to fill gaps.

## Compose the guide

Read the [HTML presentation contract](references/html-output.md) when composing
the artifact. It owns visual design, diagram rendering, and browser behavior.

Organize the document around what this repository contains. Typical sections are
an overview and technology stack; structure and components; interactions and
runtime flows; data and interfaces; integrations and configuration; build, tests,
and deployment; developer navigation; and observations and limitations. Omit
inapplicable sections rather than padding an outline.

Explain where developers should add or investigate endpoints, business logic,
persistence, integrations, background jobs, events, configuration, and tests.
Use observed repository conventions and copyable paths. Do not create a card for
every file or document every trivial endpoint at the expense of clarity.

Use focused diagrams when they answer an architectural question more clearly
than prose. Every relationship must be supported. Display metrics only when
they can be derived from the repository.

## Verify

Check that important source areas were inspected, flows actually traced, and
significant claims tied to verified repository references. Distinguish evidence
from inference in both prose and diagrams. Scan the output for secrets and
replace credential values and sensitive connection strings with placeholders.
Do not include unredacted environment files.

Open the artifact in an isolated browser and verify local/offline readability,
navigation, diagrams, smaller-screen layout, and print styling. Use the shared
[UI-testing rules](../../knowledge/operations.md). If browser validation is
unavailable, report that limit and perform the available structural checks.
