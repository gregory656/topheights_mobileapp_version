# Phase 1 — The Sunlit Foundation

**Mission:** Replace the Flutter counter demo with the real Top Heights app shell: a recognizable brand, responsive navigation, useful home screen, and durable local data foundation.

**Read first:** [raw_plan.md](./raw_plan.md), especially sections 1–3, 19, and 24. This phase establishes the shared rules used by [Phase 2](./phase2.md) through [Phase 10](./phase10.md).

## Build

- Inspect the existing Flutter project and preserve its supported platforms. The current app is a starter in `lib/main.dart`; organize code into small feature, shared UI, and data layers instead of growing one file.
- Establish the Top Heights visual system from the source plan: warm white/neutral canvas, forest/electric green accents, charcoal text, clear type hierarchy, strong contrast, comfortable tap targets, restrained motion, and reduced-motion respect. Avoid generic purple demo styling.
- Create a responsive app shell. On narrow screens use the five destinations **Home, Shop, Energy Studio, My Energy, Account**; on wider screens use an appropriate navigation rail or equivalent. Make navigation usable with keyboard and screen readers too.
- Build a real Home screen with welcoming brand copy, clear actions to Shop and Energy Studio, and honest empty states for orders, projects, devices, and service. Home should begin reflecting records created in later phases.
- Add local SQLite persistence and migrations using a Flutter-compatible SQLite package. Keep SQL/data access out of widgets; use repositories and typed models. Enable foreign keys, transactions where related records change together, and migration versioning.
- Create the first schema only for app settings/profile and the migration mechanism. Do not prebuild speculative tables for every future module.
- Add an obvious local-demo indicator or settings entry so users know records live on this device and can be cleared during development.

## Boundaries

No login/OTP, server, cloud sync, external API, live monitoring, payment claim, or fictitious business data. Local persistence is real for this install and device; it is not a multi-user production account. Do not seed invented Top Heights products, prices, stock, addresses, or customers.

## Done when

- The app opens to a polished Top Heights Home and every destination is reachable on phone and wide layouts.
- Profile/settings changes persist after closing and reopening the app.
- SQLite schema creation and a forward migration path are in place; a fresh install and an upgrade do not lose user data.
- Loading, empty, and recoverable-error states look intentional. No starter counter/demo copy remains.

**Next:** [Phase 2 — The Living Catalogue](./phase2.md).
