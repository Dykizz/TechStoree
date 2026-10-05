# Customer frontend integration — 2026-10-05

## Scope and source revisions

- Integration branch: `codex/client-integration`.
- Main backend baseline: `0892bab9266b9be9724362fdf7336717ddadc385`.
- Integrated Son frontend: `84bed971` (already includes Huy's published authentication/profile work).
- Latest inspected Son revision: `07479c237d0b41dd9111721202f1eebac495c0e5`.
- Son's later revisions do not change `client/`. The Cloudinary backend fix in `07479c2` is **not** applied here, following the user's instruction to keep the main backend unchanged.
- Development backend configuration is restored to main's version. The final `api/` diff is empty relative to the main baseline. Son's existing root `start-dev.bat` launcher is retained unchanged; it is not used by this verification session.
- The original checkout's uncommitted profile/survey/image work and its stash remain untouched.

## Completed frontend changes

- Shared customer navigation/footer, consistent red branding and Vietnamese-capable Inter typography; existing approved authentication carousel retained.
- Read-only profile with explicit edit/cancel/save and backend-provided technology interests.
- HttpOnly session refresh usable by all customer routes, concurrent refresh sharing, protected APIs, same-origin write checks and safe login return paths.
- Catalog/cart/checkout/orders use backend responses instead of fabricated product, voucher, order or payment records.
- Backend order preview is authoritative for cart prices and discounts. Failed cart synchronization blocks checkout.
- COD checkout and cancellation use real API routes. Bank transfer requires public recipient configuration and never marks payment as successful merely because a QR is shown.
- Customer surveys use assigned-survey, take and submit APIs; the backend owns completion and voucher rewards.
- Unimplemented product reviews are labeled unavailable rather than represented by sample customer feedback.

## Verification

- `npm ci`: passed after repairing the npm lockfile, without upgrading framework versions.
- `npm run lint`: passed, no warnings/errors.
- `npm run build`: passed, including the new survey and order-detail routes.
- Local HTTP/API smoke checks: **21 passed**, using only a dedicated synthetic customer against the local Docker database.
- Checks cover anonymous access denial, foreign-origin write denial, login without exposing tokens, profile read/save, concurrent refresh, cart mutations and prices, invalid voucher rejection, COD checkout, cancellation, logout, malformed login payloads and assigned survey questions/submission.
- Survey checks cover required-answer rejection, persisted completion without an invented voucher and duplicate-submission rejection.
- Test COD orders are labeled local-only and cancelled. A labeled local survey fixture remains assigned only to the synthetic test account; it issues no voucher. No production database or real customer account is used.
- Prior browser checks covered desktop/mobile navigation, profile route protection and profile edit/cancel. **The latest visual changes have not been rechecked in-browser:** the browser access tool was blocked in this session. Lint/build/API checks do not replace a final visual review.

## Blocking and unverified items

- Main backend's product endpoint currently returns HTTP 500 when Cloudinary is not configured. This is not repaired or concealed by the frontend.
- Retest product listing, details, categories/price/promotion filtering, variant selection, add-to-cart from product pages and reorder after the backend fix is approved and available.
- A survey with a real voucher reward has not been exercised; only the no-reward fixture was submitted.
- Bank transfer verification, password reset and product review submission are not implemented/verified end-to-end.
- Final desktop/mobile visual review and group route/style agreement remain necessary.

## Release decision

**Not ready to merge or push to main.** Local build and the independent customer flows pass, but the product API blocker and final visual review must be resolved first. Any later main update must preserve teammates' work and use an ordinary reviewed merge, never a force push.
