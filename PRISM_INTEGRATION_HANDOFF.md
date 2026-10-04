# PRISM Publishing — Integration Candidate Handoff (2026-10-04)

## Candidate (THIRD, isolated — the one to use)
- Worktree: `~/Developer/_isolated_worktrees/prism-integrate-20261004`
- Branch: `prism/integrate-publishing-20261004`
- Commit: `0e76d86`
- Base: common base `7a49437`.

## Integration decision (evidence-based)
Read BOTH overlapping implementations before merging:
- My earlier branch `prism/publish-repair-20261004` (commit `0989b34`) fixed the 3 defects but weakly.
- The other session's branch `prism-publishing-dispatch-receipts-20260928` was STRICTLY BETTER:
  dependency-injection seams (`DispatcherChannelSource`, injectable publish closures), richer
  `DispatchResult` (`.unsupported`/`.unverified`/`isAccepted`), `GatewayRefreshState` enum
  (`.idle/.loaded/.sessionExpired/.unreachable`), and real dispatcher tests.
→ Adopted the other branch as the base (merging mine in would have REGRESSED it). My boolean
  `lastRefreshFailed` was superseded by their `GatewayRefreshState` — dropped it.

## Net-new work added on top (neither branch had this)
Receipt-classifier integrity your directive flagged:
- Match EXACT requested account IDs (not just platform). Missing requested account → `.failed`.
- Reject duplicate per-account results; unexpected accounts don't rescue a missing requested one.
- Per-account evaluation; partial success across accounts → `.failed`.
- Provider post ID counts as a verifiable receipt (added `GatewayPublishResult.postId` + `.receipt`);
  an id-only response → `.success`, NOT downgraded to `.unverified`.

## Verification (actual results)
- `xcodebuild test -only-testing:PRISMTests` on iPhone 17 sim → **TEST SUCCEEDED, 34 tests, 0 failures**:
  - 20 pre-existing unit tests
  - 8 `NativePlatformDispatcherTests` (other session's real dispatch() tests, via DI)
  - 6 `PublishAccountIntegrityTests` (my account-level tests)
- Earlier full run (build + UI walkthrough) also green on the merge baseline (28) before +6.

## Deployed-backend finding (CORRECTED — earlier 401 conclusion retracted)
RETRACTED: my earlier claim that "401 proves the session expired and the backend works, only login
remains" was unsound. The curl requests sent NO auth; the router is mounted `app.use(auth, prismGatewayRouter)`
so the `auth` middleware returns 401 BEFORE routing — even for nonexistent paths. GET /publish also
does not exercise POST /publish. So 401 established nothing.
Verified instead by reading DEPLOYED source (`routes/prism-gateway.js`, `server.js:710-720`):
- `router.get('/oauth/connections')`, `router.post('/publish', publishLimiter, …CSRF/origin guards)`.
- Mounted authed at `server.js:720`.
→ Routes + methods exist IN THE SOURCE TREE. Whether this is exactly what production RUNS is still
  unverified. Whether a backend deploy is needed: UNVERIFIED. No deploy performed.

## PRISM auth (CORRECTED — not SIGNAL ZERO's model)
PRISM's `AuthSessionStore` auto-issues a DEVICE-scoped session JWT via `POST /v1/auth/session-token`
(device id + bundle id), caches in Keychain, refreshes <60s before expiry, re-exchanges on 401.
→ There is NO interactive George-login for PRISM's gateway session. My earlier "re-auth needed" was
  imported from SIGNAL ZERO and is wrong for PRISM. The real dependency is confirming a CONNECTED
  social account via /oauth/connections, not a founder login.

## Still blocked (genuine dependencies — need George)
1. **Live connected-accounts list**: `/oauth/connections` needs the Founder/user session, which is
   EXPIRED (per CLI `status` earlier, HTTP 401). Cannot enumerate real accounts until you re-auth.
2. **Device install + on-device UI check** of the publishing/connection-error screens: build/sim done;
   physical-device tap not available to this tool. (Install/screenshot capability not yet re-verified.)
3. **Actual publication**: outgoing action — requires your approval of the concrete post below AND a
   connected account. No real post has been demonstrated yet; I will not claim one until a receipt
   (URL or provider post ID) returns from a live account.

## PROPOSED POST (prepared, awaiting approval — NOT sent; copy corrected)
- Platform: **X** (first target; `router.post('/publish')` + `/oauth/x/start` present in deployed source — production-run status still unverified)
- Destination account: **UNKNOWN until a connected account is verified.** `/oauth/connections`
  returns the real list via PRISM's device-session (AuthSessionStore) — must be fetched from the
  app/an authorized call. A placeholder is NOT a publication-ready destination.
- Media: `~/Developer/PRISM/PRISM-LOGO-1024.png` (approved brand logo)
- Text (no "live", no "every platform", no unsupported guarantees):
  > Building in public with CORTEX PRISM — one brain, one approval step before anything is published.
  > More to share soon.
- Facebook/TikTok are explicitly **not supported** by the gateway yet; the post must not imply they are.

## Next executable action
When you re-auth the Founder/user session: (a) GET /oauth/connections to confirm the exact X
account_id, (b) fill the destination above, (c) you approve, (d) dispatch ONE post, (e) verify the
returned receipt (URL or post_id) and the visible platform URL. Promotion of this branch into the
other session's work still needs that session's owner to coordinate (not merged here).
