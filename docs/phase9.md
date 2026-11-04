# Phase 9 — The Customer Relationship

**Mission:** Add local account preferences, transparent rewards/referrals records, and an in-app activity inbox that responds to real app events.

**Read first:** [raw_plan.md](./raw_plan.md), features 101–120 and 261–275. Build on [Phase 8](./phase8.md); continue to [Phase 10](./phase10.md).

## Build

- Complete the local profile experience: personal/business profile fields, multiple delivery addresses, language/accessibility preferences, notification preferences, privacy/data controls, and account data clearing/export appropriate to local-only storage.
- Add an in-app notification/activity centre backed by SQLite. Generate entries only from actual local events such as an order request saved, quote revised, job completed, or reminder date approaching. Mark read/unread and link each entry to its source record.
- Implement opt-in local reminders only if supported by existing platform configuration. Clearly explain device-local delivery and request platform permission at the appropriate point. If notifications are unavailable on a platform, show in-app reminders only.
- Build Top Boss Rewards as a transparent ledger. Permit operator/user manual entries with reason, date, status, and locally defined rules; show earned/pending/redeemed balances as locally recorded and editable. Provide referral tracking as a saved invitation record without sending it.
- Include editable consent/communication preference records, and clearly separate transactional local activity from marketing preferences. Do not claim legal compliance based solely on a UI toggle.
- Use the “Top Boss” tone selectively and allow the user to opt out; retain the professional Top Heights brand voice elsewhere.

## Boundaries

No OTP/authentication, remote push, SMS/email/WhatsApp, automatic campaigns, referral link attribution, externally approved rewards, membership eligibility engine, analytics-based segmentation, or promise of a benefit. Do not store payment card/bank credentials.

## Done when

- Profile/preferences, local activity, and reward ledger persist across restart and can be edited with history where appropriate.
- Each notification points to a real local event and each reward shows why it is present and whether it is pending or confirmed.
- Users can find how to export/clear local data and can change their display-name/tone preference.

**Previous:** [Phase 8](./phase8.md) · **Next:** [Phase 10 — Trust, Insight & Handoff](./phase10.md).
