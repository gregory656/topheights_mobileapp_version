# Phase 2 — The Living Catalogue

**Mission:** Make Shop a useful, searchable solar and electrical catalogue whose products and specifications are actual editable local records.

**Read first:** [raw_plan.md](./raw_plan.md), features 21–45. Build on the shell and SQLite rules in [Phase 1](./phase1.md). Continue to [Phase 3](./phase3.md).

## Build

- Create product and category models/repositories with stable IDs, SKU/model, name, category, description, KES price stored as integer minor units, optional stock quantity, availability state, professional-installation flag, warranty text, image reference, and structured technical specifications.
- Use SQLite migrations for catalogue tables and indexes. Do not use floating point for money. Distinguish an unknown price/stock value from zero or out-of-stock.
- Build category browsing for the actual areas in the plan: solar panels, inverters, batteries, electrical equipment, lighting, solar heating/pumps, efficiency products, and kits. Empty categories should explain how data is added; do not fill them with fabricated inventory.
- Implement working local search across names/SKUs/specification fields, useful filters, sort, product detail, and side-by-side comparison for a small selected set.
- Provide a practical local catalogue editor for entering/updating/removing products and categories, including validation and confirmation before destructive changes. This is device-local data entry, not staff permissions.
- Add favourites and recently viewed as persisted local relationships. Show stock only when a recorded quantity/status exists and label it as locally recorded.
- Compatibility language must be conservative: show recorded specifications and explicitly explain which fields are missing. Do not declare electrical compatibility unless a documented deterministic rule can establish it from complete data.

## Boundaries

No supplier feed, barcode service, product scraping, online reviews, price alerts, location-aware inventory, or manufacturer datasheet promises. Images may be selected from local assets/files only if supported cleanly; no made-up manufacturer imagery or logos.

## Done when

- A user can create a real local product, find it by name/SKU/specification, open its detail, compare it, favourite it, edit it, and see the changes after restart.
- Missing price, stock, warranty, or technical data is visibly unknown rather than silently invented.
- Empty catalogue and empty search results provide usable guidance.

**Previous:** [Phase 1](./phase1.md) · **Next:** [Phase 3 — Cart to Order](./phase3.md).
