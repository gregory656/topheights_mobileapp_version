# Phase 5 — From Assessment to Project

**Mission:** Convert a saved assessment into a local quote draft, site visit request, and customer-visible project timeline.

**Read first:** [raw_plan.md](./raw_plan.md), features 146–165 and customer journey A. Build on [Phase 4](./phase4.md); continue to [Phase 6](./phase6.md).

## Build

- Add locally persisted quote drafts linked to an assessment and selected catalogue items. Store versioned line items, quantities, entered prices, assumptions, validity date, and notes. Mark price entries as user-entered/unverified unless sourced from the local catalogue.
- Support quote revisions as new versions so an accepted/reviewed snapshot remains understandable. Local acceptance is a recorded customer action only; identify it as pending business review and not a binding approval where no approval process exists.
- Add site-assessment requests that capture preferred date/time windows, contact, address/site notes, access constraints, and status. Do not imply a staff member has been assigned or the appointment confirmed.
- Create a project record and editable milestone timeline from a quote/request. Clearly separate **requested**, **planned locally**, and **confirmed by business** states.
- Add a document centre for locally attached/generated project documents when the app supports safe local file handling. Store metadata and references; handle missing files gracefully. Provide a shareable summary of the saved assessment/quote with assumptions and preliminary status.
- Provide project detail, progress editing, and an event history with timestamps so changes are reviewable.

## Boundaries

No e-signature, legally binding electronic approval, technician assignment, availability check, appointment confirmation, project photo upload service, installation certificate, payment/deposit collection, or cloud document vault. No generated prices from unstated business rules.

## Done when

- A user can create and revise a quote draft, request a site visit, view project milestones, and reopen all records after restart.
- Every quote/project status communicates whether it is only saved locally or confirmed externally.
- Version changes preserve the older quote snapshot, and missing attachments do not crash the app.

**Previous:** [Phase 4](./phase4.md) · **Next:** [Phase 6 — My Energy & Care](./phase6.md).
