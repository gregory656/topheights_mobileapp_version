# Phase 8 — The Command Centre

**Mission:** Give the business operator a local view and practical controls for the records the customer and field workflows have created.

**Read first:** [raw_plan.md](./raw_plan.md), features 211–240 and the Command dashboard layout. Build on [Phase 7](./phase7.md); continue to [Phase 9](./phase9.md).

## Build

- Create an operator dashboard with counts and drill-downs derived from SQLite: local orders, quote drafts awaiting review, site requests, open projects, service tickets, technician jobs, and known low-stock catalogue items.
- Make each metric's definition and local data scope discoverable. Distinguish order-request totals from revenue/cash, quote value from sales, and known local stock from physical verified stock.
- Add working local management screens for customers/sites, orders, quotes, projects, tickets, jobs, and product/inventory records already created in prior phases. Use search, filters, status updates, and audit/event records where a record changes.
- Add stock movements and simple local goods receipt/adjustment entry with reason and timestamp. Preserve history instead of erasing changes.
- Support export of selected operational lists to a portable format if straightforward; include a date range and column labels. Guard against exporting unnecessary personal details.
- Adapt to desktop/tablet layouts with an information-dense but readable navigation and tables/cards that also remain usable on mobile.

## Boundaries

This is a single-device operator workspace, not a secure multi-staff Command SaaS. No real permission enforcement, financial ledger, tax accounting, payroll, supplier integrations, automated forecasting, or business-wide analytics. Label demo/local scope wherever it could be mistaken for live company data.

## Done when

- Dashboard figures reconcile to visible local records and each opens the relevant filtered list.
- Operators can update workflow records and the change is reflected in customer/technician views on that device.
- Money and inventory labels accurately distinguish locally recorded estimates from verified business facts.

**Previous:** [Phase 7](./phase7.md) · **Next:** [Phase 9 — The Customer Relationship](./phase9.md).
