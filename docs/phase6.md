# Phase 6 — My Energy & Care, Before the Smart Meter

**Mission:** Give owners a real local record of installed systems, documents, maintenance, and service requests even when no device is connected.

**Read first:** [raw_plan.md](./raw_plan.md), features 76–100 and 166–185. Build on [Phase 5](./phase5.md); continue to [Phase 7](./phase7.md).

## Build

- Create customer-managed installation/site records with equipment references, serial numbers (optional), installation/handover dates, address, and notes. Allow multiple sites.
- Build My Energy around verified locally entered data: system list, equipment, handover/warranty documents, service history, and next actions. Provide an empty state when no installation is recorded.
- Allow manual energy readings with value, unit, meter/device, date/time, and source. Plot only those recorded readings; distinguish measured from user-entered and never label them live telemetry.
- Add maintenance records and reminders with user-entered dates and manufacturer guidance fields. Explain that reminders are local to this installation of the app.
- Add fault/service tickets linked to a site or order: category, description, severity chosen by user, contact preference, optional attachment reference, local ID, status, and event history.
- Provide searchable local document metadata and an installation handover pack view. Include deletion/edit controls and clear privacy/storage explanations.

## Boundaries

No inverter/meter integration, live generation, battery state, grid import/export, forecast, verified savings/carbon, remote diagnostics, WhatsApp, call-centre chat, warranty eligibility decision, or support-team delivery. Never imply the business has received a locally saved ticket.

## Done when

- A customer can register multiple local systems, add manual readings/service history, create a ticket, and see all linked history after restart.
- Charts and insight labels state their source and period; no data is shown as live if it was entered manually.
- Ticket state clearly distinguishes a local draft from a request actually sent to support.

**Previous:** [Phase 5](./phase5.md) · **Next:** [Phase 7 — Field Workbench](./phase7.md).
