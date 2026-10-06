# Customer frontend integration — 2026-10-05

## Scope and source revisions

- Integration branch: `codex/client-integration`.
- Main backend baseline: `0892bab9266b9be9724362fdf7336717ddadc385`.
- Integrated Son frontend: `84bed971` (already includes Huy's published authentication/profile work).
- Latest inspected Son revision: `7173cbced3df7ed2cc96f134b1711d9eb57bb995`, pushed on 2026-10-05 at 15:15 +0700.
- The new frontend changes since `07479c2` are selectively reconciled into the local working tree. This is a manual frontend integration, **not** a full Git merge of Son's branch and not a new merge commit. A full merge would also bring historical backend/admin changes that are outside this pass. Source ancestry still records the earlier `84bed971` integration.
- Main's Docker/pgAdmin commit `1f9bcef` was merged normally into this integration branch on 2026-10-05, with no conflicts. Its `docker-compose.yml` and `servers.json` are preserved exactly. No customer/frontend/API source changed in that main commit.
- The Cloudinary backend fix in `07479c2` is **not** applied here, following the user's instruction to keep the main backend unchanged.
- Development backend configuration is restored to main's version. The final `api/` diff is empty relative to the main baseline. Son's existing root `start-dev.bat` launcher is retained unchanged; it is not used by this verification session.
- Private local Cloudinary configuration was applied through ignored files and an API-only container recreation. PostgreSQL and pgAdmin were left running; no database volumes were removed. Reading products now succeeds without a backend source change. Upload/delete authentication against Cloudinary has not been tested.
- The original checkout's uncommitted profile/survey/image work and its stash remain untouched.
- All 15 pre-integration changed/untracked frontend files were copied and hash-verified in the sibling `backup-before-son-7173cbc-20261005-v2` directory before reconciliation. Ignored credentials were excluded.

### Reconciliation of Son's `7173cbc`

- Logout route: a successful browser sign-out returns HTTP 200 even if the backend is unavailable, as in Son's fix. Unlike an unconditional backend success claim, `signedOut` and `backendRevoked` remain distinct and the response warns when revocation is unconfirmed. Foreign-origin requests remain rejected without clearing cookies.
- Cookie deletion: explicit epoch expiration and matching HttpOnly/SameSite/Secure attributes added for current root-path cookies and legacy auth-path cookies.
- Shared header: failed session checks clear stale user display, guarded by AbortController to avoid stale updates. Successful logout removes legacy cart/voucher browser cache and fully navigates private routes to the homepage (public routes reload). Network/forbidden logout failures show an error rather than pretending cookies were cleared. One shared `logoutCustomer` helper handles the checked response and browser-cache cleanup.
- Profile: Son's separate profile logout handler is represented by the shared header above, already used on `/profile`; no duplicate logout button/handler added. The read-only/edit/cancel/save interface and notifications remain intact.
- Orders: the existing API-backed implementation already verifies the session before loading/displaying orders and redirects anonymous users to login. Retained this guard and real order data instead of overwriting them with Son's older merged-local/sample preview implementation.
- Price filter: the local implementation already avoids the state-sync effect that Son added an ESLint suppression for. No suppression or obsolete effect imported.

## Completed frontend changes

- Shared customer navigation/footer, consistent red branding and Vietnamese-capable Inter typography; existing approved authentication carousel retained.
- Homepage full-width background carousel using the four approved showcase assets, five-second rotation, decoded-image gating, focus/visibility/reduced-motion pauses and functional discovery/catalog/profile links. Hover no longer pauses rotation. Visible slide/pause controls removed per user preference. Product API behavior remains unchanged.
- Shared signed-in notification bell: per-account browser-local history, unread count/filter/read actions, success receipts for survey/profile/order operations and API-confirmed PAID orders. No notification backend, realtime payment verifier or cross-device synchronization added.
- Read-only profile with explicit edit/cancel/save and backend-provided technology interests.
- HttpOnly session refresh usable by all customer routes, concurrent refresh sharing, protected APIs, same-origin write checks and safe login return paths.
- Catalog/cart/checkout/orders use backend responses instead of fabricated product, voucher, order or payment records.
- Backend order preview is authoritative for cart prices and discounts. Failed cart synchronization blocks checkout.
- COD checkout and cancellation use real API routes. Bank transfer requires public recipient configuration and never marks payment as successful merely because a QR is shown.
- Checkout visual refinement: restored the missing `fieldsGrid`/`fieldRow` CSS selectors, added responsive spacing and long-value wrapping, moved each item price below its name/variant, and separated shipping/payment sections from the summary. Replaced the old inline success card with an API-backed receipt component showing actual delivery details, total, order/payment status and conditional bank transfer information. Pending feedback freezes form fields and guards rapid duplicate submission; confirmation/focus/scroll animations respect reduced-motion settings. No backend source, pricing contract or payment confirmation logic changed.
- Customer surveys use assigned-survey, take and submit APIs; the backend owns completion and voucher rewards.
- Unimplemented product reviews are labeled unavailable rather than represented by sample customer feedback.

## Verification

- `npm ci`: passed after repairing the npm lockfile, without upgrading framework versions.
- `npm run lint`: passed, no warnings/errors.
- `npm run build`: passed, including the new survey and order-detail routes.
- After reconciling Son's `7173cbc`: lint (no warnings/errors), production build, the 27 current HTTP/API checks, 13 notification-store checks and homepage component checks passed again. Eleven new mocked logout/cookie tests passed: same-origin rejection, root/legacy expiry, repeated anonymous logout, confirmed/unconfirmed revocation, refresh/retry, client cleanup and storage/network failure handling. These mocked tests do not replace a real browser interaction review.
- After the checkout refinement: lint and production build passed again; 16 local mocked checkout/receipt checks passed for validation, same-render duplicate-submit prevention, pending feedback, successful/failed API responses, unchanged request payload, cart/session guards, COD/transfer/PAID display, QR configuration/encoding, focus/reduced-motion behavior, matching CSS class names and responsive/wrapping rules. The 27 HTTP/API checks, 13 notification checks, 11 logout checks and homepage state checks were rerun successfully. The synthetic local COD test order was cancelled after verification. These are structural/state/API checks, not measured browser layout or live bank-payment verification.
- Release recheck after merging `1f9bcef`: lint/build, all 27 HTTP/API checks, 16 checkout checks, 13 notification checks, 11 logout checks and homepage state checks passed. Compose validation with the ignored local Cloudinary override passed; existing API/pgAdmin containers remain up and PostgreSQL remains healthy. Containers/database volumes were not recreated or deleted just to sync Git; the new pgAdmin persistence mounts have not been exercised through a pgAdmin recreation in this pass.
- Local HTTP/API smoke checks: **21 passed**, using only a dedicated synthetic customer against the local Docker database.
- Checks cover anonymous access denial, foreign-origin write denial, login without exposing tokens, profile read/save, concurrent refresh, cart mutations and prices, invalid voucher rejection, COD checkout, cancellation, logout, malformed login payloads and assigned survey questions/submission.
- Survey checks cover required-answer rejection, persisted completion without an invented voucher and duplicate-submission rejection.
- After loading real local Cloudinary configuration: **27 current HTTP/API checks passed**, including product/category listing, real variants and min/max prices, category/price/search/sort/pagination filters, promotion filtering, unknown-product rejection, cart/preview, COD checkout/cancellation and catalog-based reorder. The existing completed survey fixture is verified as completed and rejects retaking/submitting again, rather than attempting to submit it a second time. Earlier first-submission checks remain historical evidence, not a new submission in this pass.
- The current catalog contains no active promotions. The sale filter's empty result was verified; calculations with an active promotion and an actual reward voucher are not exercised by this dataset.
- HTTP 200 confirmed for homepage, catalog, product detail, login/register and all four local showcase images.
- Homepage component-state smoke checks (mocked React hooks, not a browser): passed for image-readiness gating, five-second interval, transition locking, wraparound, removal of visible controls, absence of hover-pause handlers and focus/hidden-tab/reduced-motion pauses. Local homepage HTTP 200 contains the new hero and destination links.
- Notification-store unit checks use mocked browser storage/events, not real backend mutations or live payments. Account isolation, duplicate/read handling, reload persistence, bounded history, unsafe-link rejection, PAID ownership gating, storage failures and cross-tab refresh/removal passed.
- Test COD orders are labeled local-only and cancelled. A labeled local survey fixture remains assigned only to the synthetic test account; it issues no voucher. No production database or real customer account is used.
- Prior browser checks covered desktop/mobile navigation, profile route protection and profile edit/cancel. Automated browser access remains blocked in this session. The user manually reviewed and accepted the latest checkout appearance and explicitly authorized integrating the completed client into main on 2026-10-05. A separate latest mobile visual review is not recorded; lint/build/API checks are not a browser layout measurement.

## Blocking and unverified items

- The product HTTP 500 blocker is resolved on this machine by private local Cloudinary configuration, not by a frontend fallback or backend source fix. The shared Compose file still does not pass Cloudinary keys itself; the ignored local override supplies them to the API only. Teammates need their own secure configuration. Never commit secrets or recreate database volumes to apply this configuration.
- Product API and catalog-based cart/reorder operations passed HTTP checks. Final in-browser variant-selection/add-to-cart and carousel visual interaction remain unverified in this session.
- A survey with a real voucher reward has not been exercised; only the no-reward fixture was submitted.
- Bank transfer verification, password reset and product review submission are not implemented/verified end-to-end.
- Keep the remaining mobile visual, real-reward voucher and bank-transfer checks visible to the group; this is an integration of the completed current client, not certification for live commercial payments.
- The newly reviewed work is committed separately for logout, homepage, notifications and checkout. Publish from the integration branch via a PR, recheck main and the expected head before merging, and never force push. Do not imply that Son's entire latest branch has been merged by Git; its new frontend logout work was selectively reconciled while keeping main's backend unchanged.

## Release decision

**Ready for the user-authorized main integration of the completed client.** The main infrastructure commit is included, the product blocker is resolved locally through private configuration, and the release checks pass. The user accepted the checkout and authorized push/merge following the lead's request. Use the integration PR and a normal merge after checking the current remote head; preserve backend/admin/infrastructure files and exclude ignored credentials and local test artifacts. This approval does not establish Cloudinary upload/delete permissions, real bank-payment verification or a new mobile visual review.
