# Phase 3 — Cart to Order

**Mission:** Turn catalogue browsing into a dependable, persistent local purchase request and order history without pretending to process money.

**Read first:** [raw_plan.md](./raw_plan.md), features 121–145 and customer journey B. Build on [Phase 2](./phase2.md); continue to [Phase 4](./phase4.md).

## Build

- Add a SQLite-backed cart with product references, quantity, price snapshot, currency, and timestamps. Recalculate totals from integer minor units and make quantity/remove actions reliable.
- Build a clear review flow for customer contact details, a saved or one-time delivery address, delivery/installation preference, line items, subtotal, known fees, and unknown fees. Never invent delivery charges, tax, stock reservations, or availability rules.
- Let the customer save a local order request. Record the order and its item/price snapshots transactionally so later product edits do not rewrite order history. Give it an unambiguous local reference and a status such as **Draft**, **Submitted locally**, or **Cancelled**.
- Build order history and order detail with a simple, honest timeline. Since there is no server, a submitted-local order means saved on this device only; it has not reached Top Heights.
- Create a printable/shareable order summary using available Flutter packages/platform support if already appropriate, or provide a clean in-app summary. Label it as an order request, not a tax invoice or paid receipt.
- Support local cancellation/editing according to simple draft/local states. Record changes with timestamps rather than presenting them as remote fulfilment events.

## Boundaries

No M-Pesa/card/bank integration, payment verification, invoice/tax compliance claim, notification sending, delivery tracking, stock reservation, refunds, or successful-payment state. Never collect or store card credentials. Integration points may be represented by a disabled, clearly labelled “available when connected” explanation.

## Done when

- Cart and local order history survive app restart, and order records preserve their original line item and price snapshots.
- Totals are exact, invalid quantities are rejected, and unknown fees are clearly shown as unknown.
- The interface never tells the user an order was received by the business or paid when neither event occurred.

**Previous:** [Phase 2](./phase2.md) · **Next:** [Phase 4 — Energy Studio](./phase4.md).
