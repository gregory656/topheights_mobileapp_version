# Phase 7 — The Field Workbench

**Mission:** Give a technician a useful, offline-capable local workspace for assigned job records, checklists, parts, and handover notes.

**Read first:** [raw_plan.md](./raw_plan.md), features 186–210 and customer journey C. Build on [Phase 6](./phase6.md); continue to [Phase 8](./phase8.md).

## Build

- Add a technician-facing area with a local job queue. Jobs can be created/assigned locally by the person using this device and linked to a site, service ticket, or project.
- Create job detail with customer/site contact notes, work description, priority, planned window, status, and a timestamped activity log. Clearly label local assignments as not synced.
- Provide editable checklist templates and per-job checklist completion with notes and completion time. Include sensible safety/commissioning sections from company-entered templates; do not claim regulatory compliance automatically.
- Record parts used against a job with quantity and optional catalogue product link; update local stock movement only when a known local stock record exists and keep the adjustment traceable.
- Capture work report, test readings with units, customer handover notes, follow-up needs, and optional local photo/document references.
- Make job data available offline through SQLite and design retry-safe local writes. Provide explicit export/share of a job summary when useful.

## Boundaries

No GPS tracking, route optimization, live dispatch, staff authentication/permissions, cloud sync, customer signature as legally verified, safety certification, or remote job queue. Local job completion is a record, not proof the office received it.

## Done when

- A technician can work through a locally available job with no network, update checklists and parts, save a report, close/reopen the app, and retain their work.
- Every completion/report includes who entered it (local profile where available) and when.
- Stock is never decremented silently or allowed to become negative without an explicit, reviewable adjustment.

**Previous:** [Phase 6](./phase6.md) · **Next:** [Phase 8 — Command Centre](./phase8.md).
