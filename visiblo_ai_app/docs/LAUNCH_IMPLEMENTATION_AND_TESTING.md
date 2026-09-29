# VisibloAI Launch Implementation and Testing Tracker

Status: PLANNED. No implementation, database reset, or test pass is implied by this document.

Blueprint: `../VisibloAI_Developer_Launch_Guide_v2.pdf`, all 22 sections.
Scope: backend/API, customer dashboard, Flutter Android/iOS app, Admin, and public commercial copy.
Chatbot feature development is paused; its commercial copy must eventually match the same configuration.

## 1. Agreed commercial rules

| Item | Launch rule |
| --- | --- |
| Starter | INR 1,999 per month |
| Growth | INR 2,999 per month |
| Business Pro | INR 4,999 per month |
| Trial | 14 calendar days, INR 99 activation |
| Free trial path | Eligible 100% activation-fee coupon; payable zero; skip gateway |
| Paid terms | 1, 3, 6, 12 months; recommend 3 months |
| Pricing ownership | Admin configuration, resolved and enforced by backend |
| Trial start | Successful verified payment or atomic zero-value activation, not signup |
| Renewal | Explicit opt-in and valid supported mandate for auto-renewal |

Do not invent duration discounts, trial quotas, tax inclusivity, or plan features. Audit existing configuration first and resolve missing commercial decisions before enabling checkout. Store money in integer paise. Historical orders/invoices retain their original price snapshots when Admin changes future prices. Payment amounts and eligibility must be recalculated server-side.

## 2. How we will work

Finish each phase with implementation, focused automated verification, manual testing, and evidence before marking it complete. Label findings as implemented, partial, missing, or unverified. A successful build or HTTP response alone does not prove the customer workflow works.

Checklist states: `[ ]` pending; `[x]` verified. Record failures and blocked tests in the evidence table below. Do not mark unavailable iOS, payment, provider, or device tests as passed.

## 3. Phase 0: Inventory and controlled test reset

Target requested by owner: Ziba Creations and Visiblo AI under the VisibloAI email. Prior context identifies `visibloai@gmail.com`; verify its exact database identity and both business IDs before mutation.

### Engineering

- [ ] Inspect repository instructions, current changes, deployment configuration, Prisma relations, and existing seed scripts.
- [ ] Identify the exact database/environment and produce a read-only inventory for the two business IDs, ownership, memberships, and dependent record counts.
- [ ] Map subscriptions, trials, orders, payments, invoices, coupons/redemptions, OAuth connections, posts/media, calendars, reviews, rankings, websites, usage, notification tokens, onboarding, consents, and audit records.
- [ ] Separate business-owned records from shared user/account records. Do not delete unrelated tenants, global plans, directories, coupon definitions, or Admin accounts.
- [ ] Define treatment of financial/audit records and external payment mandates before deletion; deleting local rows does not cancel provider subscriptions.
- [ ] Decide whether fresh testing requires deleting the user account or only business data. Business deletion alone may leave completed onboarding and trial eligibility attached to the user. Do not delete the shared account implicitly.
- [ ] Back up affected data and verify recovery; document the exact reset scope and row counts.
- [ ] Stop selected-business queued/scheduled work and account for in-flight jobs before reset. Do not disable other customers' automation.
- [ ] Prepare a dry-run reset script scoped to verified IDs, with dependency order and transaction handling; execute only once the exact scope is settled.
- [ ] Clear only relevant sessions/caches/jobs and app-local selections so tests cannot reuse stale business state.
- [ ] Verify zero unintended changes to other businesses and no orphaned tasks or media references.

Do not delete already published Google/Facebook/Instagram posts or external assets as an implicit part of the database reset. Track those separately if removal is required. Prefer designated test profiles for publication tests.

### Manual acceptance

- [ ] Target test identity can begin the agreed fresh journey without stale workspaces or access.
- [ ] Other users and businesses still work.
- [ ] Reconnecting provider accounts works; old jobs do not publish unexpectedly.

## 4. Phase 1: Shared configuration and entitlements

### Engineering

- [ ] Inventory existing Package/Plan, duration pricing, trial, coupon, billing, and entitlement code before adding tables or APIs.
- [ ] Implement or extend Admin-managed plan/duration prices, active durations, taxes, trial days/fee, features, and quotas.
- [ ] Seed the agreed monthly prices using existing supported configuration paths; preserve existing legitimate configuration.
- [ ] Return authoritative configuration to web/mobile/Admin; remove duplicated price, trial-day, discount, and limit logic.
- [ ] Use business-scoped entitlements consistently in protected APIs and background workers.
- [ ] Preserve existing valid subscriptions and agreed legacy treatment through migration.

### Manual acceptance

- [ ] Monthly amounts show INR 1,999 / 2,999 / 4,999 consistently.
- [ ] Admin changes a test price; a fresh quote on web/mobile reflects it without an app release.
- [ ] An old invoice remains unchanged; checkout handles a stale quote clearly.
- [ ] Each enabled duration has correct configured total, taxes, renewal amount, and server-calculated end date.
- [ ] Disabled durations cannot be purchased through direct API calls.
- [ ] Package restrictions and usage counters agree across mobile, web, and backend.

## 5. Phase 2: Trial activation, coupons, and payments

### Engineering

- [ ] Change new-trial configuration from 7 to 14 days; explicitly decide treatment of already active trials instead of silently extending them.
- [ ] Replace all outdated 7-day/14-day-free commercial text with configuration-driven, accurate wording across activation, settings, paywalls, welcome, emails, website, and chatbot copy.
- [ ] Add/verify Admin coupon controls: activation applicability, discount, active state, validity, total limit, per-customer limit, and eligibility.
- [ ] Validate coupons server-side; applying a code only quotes eligibility and does not prematurely consume it.
- [ ] Revalidate and redeem atomically at activation; concurrent requests must not exceed limits.
- [ ] For payable zero, record a zero-value activation and redemption, skip gateway, and set trial timestamps exactly once.
- [ ] For payable greater than zero, create a server-priced order and verify payment amount, currency, signature, and order/customer association.
- [ ] Make verification and signed webhook processing idempotent across retries and out-of-order events.
- [ ] Expose pending/failed/success states and restore pending payment status after restart.
- [ ] Ensure zero activation creates no fake gateway payment; generate applicable receipt/invoice records using configured rules.
- [ ] Check the intended iOS purchase flow against the release's applicable store requirements before submitting the payment UI.

### Automated and manual acceptance

- [ ] No coupon: verified INR 99 payment starts one 14-day trial.
- [ ] 100% coupon: total zero, no gateway opens, one redemption, one trial.
- [ ] Invalid, expired, disabled, ineligible, and exhausted codes fail without changing access.
- [ ] Coupon removal restores the correct payable amount.
- [ ] Concurrent redemption, repeated taps, and replayed activation cannot grant duplicate access.
- [ ] Failed/cancelled payment does not activate a trial; retry works.
- [ ] Client success without verified payment cannot unlock access.
- [ ] Delayed, duplicate, and reordered webhooks converge to the correct state without duplicate invoices/subscriptions.
- [ ] Trial timestamps and countdown agree on multiple devices and at the expiry boundary.

## 6. Phase 3: Onboarding and business routing

### Engineering

- [ ] Implement/resume: Welcome -> Business setup -> Google connection -> Consent -> Trial/coupon -> Activation -> AI questions -> Preparation -> Dashboard.
- [ ] Persist each step, supported skips, versioned consent, and completion on the backend.
- [ ] Capture goals, services, target area, tone, CTA, hours, and media using existing supported business fields.
- [ ] Show actual queued/processing/completed/failed preparation tasks with recoverable errors.
- [ ] Resolve authenticated launch state from API before routing; define precedence for suspension, valid subscription, trial, onboarding, and pending payment.
- [ ] On fresh login, select an accessible active business when available. An expired sibling business must not block it.
- [ ] Explicitly switching to an expired business shows that business's upgrade state and still permits switching back.
- [ ] Keep billing, support, and permitted history reachable for expired accounts.
- [ ] Migrate existing customers without forcing inappropriate signup steps or restarting trials.

### Manual acceptance

- [ ] Fresh signup follows the complete sequence and reaches a populated, truthful dashboard.
- [ ] Close/reopen at every step; resume saved progress on both same and other device.
- [ ] Google denial, no locations, multiple locations, and expired permissions give useful recovery paths.
- [ ] No automatic publishing starts before required consent and permissions.
- [ ] Visiblo AI active + Ziba expired: fresh login selects active access; switching enforces each business's own status.
- [ ] Incognito, normal browser, Android, and available iOS build show consistent state.

## 7. Phase 4: Calendar, images, and automatic publication

### Engineering

- [ ] Document per-plan posting cadence, platform counts, approval mode, image generation timing, and usage charging from actual code/configuration.
- [ ] Verify 30-day planning does not imply unsupported daily posting or 90 distinct generated images.
- [ ] Separate calendar planning, content/media generation, approval, scheduling, publication, and provider confirmation states.
- [ ] Require usable media before scheduling/publishing channels that need images; surface preparation failures.
- [ ] Enforce consent, connection health, current entitlements, and quotas when workers execute, not only when calendar is created.
- [ ] Verify timezone conversion and UTC due-time comparisons end to end.
- [ ] Verify scheduler authentication, deployed routes, cadence, worker claiming, retries/backoff, and recovery of stuck publishing jobs.
- [ ] Handle provider timeouts/uncertain results without blindly duplicating posts; retain provider IDs and actionable errors.
- [ ] Define measured publication delay allowance based on actual scheduler cadence and provider processing; do not promise exact-second delivery.
- [ ] Prevent duplicate calendars/jobs when generation is retried. Verify edits, cancellations, and renewal/expiry effects on queued work.

### Manual acceptance

- [ ] Generate a calendar for each plan and inspect dates, captions, CTA, media, quotas, and platform assignments.
- [ ] Preview/edit/save survives refresh; rejected drafts stay unpublished.
- [ ] Schedule near-future test posts on Google, Facebook, and Instagram; record due time, worker time, provider ID, and actual visible publication.
- [ ] Verify automatic posting while the app is closed.
- [ ] Missing image, expired token, provider rejection, disconnected channel, and exhausted quota give correct failure/action states.
- [ ] Worker retry or duplicate scheduler request does not create duplicate publication.
- [ ] Cancelling/rescheduling changes the actual worker behavior.
- [ ] Trial expiry or paused automation stops protected future publication while retaining history.
- [ ] Test month boundary, business timezone, calendar refill, and reconnect recovery.

## 8. Phase 5: Remaining feature coverage

For every feature verify loading, empty, success, failure, retry, persistence, correct business ownership, and plan limits.

- [ ] Keyword ranking: correct keyword/location/grid, real provider results, refresh timing, historical persistence, and quota charging.
- [ ] Image generation/creatives: business relevance, branding, preview/edit/download, accessible media, failed generation, retries, and usage/cost accounting.
- [ ] Reviews: sync, manual replies, configured automatic replies, approval preferences, duplicate prevention, and failure handling.
- [ ] Review QR/share: correct business destination, actual mobile scanning, download, and share behavior.
- [ ] Citations: distinguish verified live listings, submitted/pending work, and suggestions; no invented completion.
- [ ] SEO/GBP health: real source data, timestamps, missing-data handling, and actionable errors.
- [ ] AI website: entitled generation, business isolation, edits, publication, correct URL, and persistence.
- [ ] Reports: correct business/date filters, authentic metrics, empty periods, export, and access control.
- [ ] Settings/support: saved business preferences, logout/login, account management, billing, Terms, and Privacy.

## 9. Phase 6: Daily activity and notifications

### Engineering

- [ ] Build/verify activity records from actual job results: generated, scheduled, published, failed, reviews handled, and actions needed.
- [ ] Show automation Active / Needs Setup / Paused / Action Required using real backend state.
- [ ] Add/verify connection sync timestamps and distinct disconnected, syncing, expired permission, and error states.
- [ ] Define daily report timezone and delivery time; show accurate zero-activity days and avoid invented growth claims.
- [ ] Configure trial reminders (7/3/1 days remaining and expiry), payment/subscription alerts, failed jobs, reconnect, approval, and publication notifications.
- [ ] Verify in-app, push, and email channels, device registration/rotation, preferences, deep links, deduplication, and delivery-failure visibility.
- [ ] Instrument blueprint funnel events and error monitoring without exposing credentials or private provider tokens.

### Manual acceptance

- [ ] Daily activity matches database/job evidence and distinguishes completed work from pending work.
- [ ] Failed GBP connection or post produces a useful action and opens the correct business/screen.
- [ ] Notifications work in foreground, background, and terminated app where supported; test permission granted/denied and multiple devices.
- [ ] Logout/account switch prevents notifications or links from exposing another account's data.
- [ ] Reminder retries do not spam duplicates; upgrade stops obsolete expiry reminders.
- [ ] A real device receives push; provider acceptance alone does not count as delivery.

## 10. Phase 7: Release verification

- [ ] Review tenant isolation, Admin permissions, rate limiting, OAuth secret storage/refresh, signed webhooks, and protected worker actions.
- [ ] Test migrations/backups and recovery, deployment compatibility, and rollback procedure.
- [ ] Complete journeys for paid trial, waived trial, expired trial, active paid subscription, renewal, and two-business switching.
- [ ] Test supported Android and iOS builds plus customer web on desktop/mobile; record platform gaps explicitly.
- [ ] Run relevant automated tests and release builds; resolve launch-blocking failures.
- [ ] Deploy reviewed changes and run controlled production smoke tests with designated businesses.
- [ ] Confirm actual scheduled publishing, billing state, and notifications after deployment.
- [ ] Owner signs off remaining non-blocking issues; no critical open billing, access, tenant isolation, or publication defects.

## 11. Responsibilities and evidence

Engineering: code/schema audit, migrations, shared configuration, backend enforcement, targeted tests, build verification, failure diagnosis, and fixes.

Sahil/Admin: confirm reset identities, configure approved commercial values/coupon eligibility, connect owned test profiles, complete provider/device interactions, and review actual posts and notification receipts. Never put passwords, tokens, or payment credentials in this tracker.

Before executing tests, settle the exact reset database/IDs and shared-user treatment, longer-term prices/tax rules, trial package/quotas, coupon eligibility, and test platform access. These do not block the read-only code audit.

| Test ID / phase | Platform/build | Business ID | Expected | Actual/evidence | Status | Fix/retest |
| --- | --- | --- | --- | --- | --- | --- |
| Initial audit | Pending | Pending | Map blueprint to current implementation | Not started | Pending | |

Evidence should include timestamps/timezone, redacted request or job IDs, relevant screenshots, provider post IDs/URLs, and expected vs actual results. Use only approved test data.

## 12. Immediate execution order

1. Audit existing implementation and identify exact two-business reset scope read-only.
2. Resolve shared-account/trial-history handling and backup/reset dependencies.
3. Implement shared Admin pricing and 14-day configuration.
4. Implement and verify coupon waiver plus paid trial paths.
5. Implement launch routing, resumable onboarding, and first dashboard.
6. Perform the controlled reset when the new journey is ready; recreate the two businesses through the app rather than seeding completed onboarding.
7. Test calendar/publication, remaining features, daily reporting, and notifications; fix and retest each failure.
8. Finish cross-platform acceptance, deployment, and production smoke tests.

The reset is deliberately executed after preparation so fresh test accounts exercise the new journey. Until then, preserve existing records for diagnosis.
