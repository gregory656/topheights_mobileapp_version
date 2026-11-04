# Phase 4 — Energy Studio, With Its Working Out Shown

**Mission:** Let a customer capture real household/site loads and save a transparent preliminary energy assessment locally.

**Read first:** [raw_plan.md](./raw_plan.md), features 46–75. Build on [Phase 1](./phase1.md) storage and continue to [Phase 5](./phase5.md).

## Build

- Create a guided questionnaire for property/use case, grid access, location entered by the user, budget range if supplied, and current bill/consumption when known. Make skipped and estimated inputs explicit.
- Add an editable appliance library and appliance inventory. Each entry stores quantity, rated watts, operating hours, critical-load selection, and whether wattage is measured, label-read, user-estimated, or an illustrative default.
- Implement deterministic, documented arithmetic for estimated daily energy (Wh/kWh) and peak simultaneous load, with validation, unit labels, and assumptions visible alongside results. Keep calculation logic separate from widgets and database code.
- Allow a user to change backup-duration and daytime/nighttime assumptions and compare saved scenarios. Persist assessments and versions locally so they can resume later.
- Present a demand summary and a confidence/completeness panel that calls out missing real measurements, starting surge, seasonal solar resource, roof/shading, and professional review needs.
- Offer a saved draft system-design record only where actual catalogue components/specifications can be selected. Do not automatically claim safe sizing from incomplete data.

## Boundaries

Do not invent solar-resource values, tariffs, losses, appliance ratings as if measured, payback, savings, ROI, certified design, code compliance, cable/protection sizing, or compatibility. No bill upload extraction, AI, weather API, or engineer submission. Any baseline value must be visibly identified as an editable assumption.

## Done when

- A customer can enter/edit loads, see the calculation and its units, understand its assumptions, save multiple named scenarios, and reopen them after restart.
- Invalid or incomplete inputs cannot produce confident recommendations; the UI identifies what information is missing.
- Calculation code is independently callable and results are reproducible for identical inputs.

**Previous:** [Phase 3](./phase3.md) · **Next:** [Phase 5 — From Assessment to Project](./phase5.md).
