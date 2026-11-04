# Phase 10 — Trust, Insight & Handoff

**Mission:** Make the local-first product coherent, inspectable, portable, and ready for a future backend without faking integrations that do not exist.

**Read first:** [raw_plan.md](./raw_plan.md), features 241–300, 19, 24, and the end-to-end journeys. This phase consolidates [Phase 1](./phase1.md) through [Phase 9](./phase9.md).

## Build

- Add a clear data-source and integration-status surface: local-only storage, last local edit, and plainly unavailable connections for payments, cloud, support, telemetry, and AI. Do not add nonfunctional toggles that imply a connection is active.
- Create explainable local insights from actual records only: saved order counts, quote aging, open work, recorded manual reading trends, maintenance dates, and inventory changes. Show formulas, time ranges, and data limitations. Avoid predictive claims from sparse data.
- Add import/export and backup/restore for the app's own local data in a versioned format if feasible. Validate imports, preview affected record counts, avoid overwriting by default, and handle schema versions and errors without corrupting existing data.
- Review privacy controls, local file cleanup, migrations, empty/loading/error states, accessibility, responsive layouts, and navigation continuity across all phases. Ensure exported reports clearly identify locally recorded/preliminary data.
- Keep domain logic behind repositories/services so a future backend can replace local implementations without rewriting screen layouts. Define interfaces, but do not introduce a server, API client, cloud credentials, or premature distributed architecture.
- Add a concise in-app “About this data” explanation and a safe reset path for local demo records, clearly separated from customer-data deletion.

## Boundaries

AI assistance, bill/document extraction, live monitoring, device alerts, manufacturer/meter APIs, real-time collaboration, payments, external installer accounts, partner APIs, and cloud synchronization remain future backend/integration work. Never fabricate a connected state, source data, business result, or automated action.

## Done when

- A user can tell what data is local, what is measured versus entered/estimated, and which integrations are actually unavailable.
- Local exports can be validated and restored without silent record loss; summary insights can be traced to the underlying records.
- All ten phase outcomes form a navigable end-to-end local product, while every external action is described honestly as requiring a future connection.

**Previous:** [Phase 9](./phase9.md) · **Source blueprint:** [raw_plan.md](./raw_plan.md).
