# Claude Brain Wire — CORTEXNODE · JERICHO · PRISM

## Flip live routing

1. Set `ShellFeatureFlags.brainConnected = true` in `ShellFeatureFlags.swift`
2. Verify `api.cortexnode.ai` session token path (`AuthSessionStore` in each app's `BrainConnector.swift`)
3. Call `await ShellBrainGateway.shared.connect(appKind:)` from Settings → Brain Connection
4. Command Center streams via `ShellBrainGateway.shared.stream(prompt:appKind:)`

## Per-app BrainConnector

| App | File | Entry |
|-----|------|-------|
| CORTEXNODE | `Services/BrainConnector.swift` | `stream(userInput:)` |
| JERICHO | `Services/BrainConnector.swift` | `stream(userInput:)` |
| PRISM | `Services/BrainConnector.swift` | `stream(messages:)` + publishing APIs |

## PRISM-specific (Blotato replacement)

- `PrismRefractionStudioView` — wire draft queue + OAuth per platform
- `PrismImageStudioView` — implement `ShellImageGenerationServing` (replace `ShellPreviewImageGenerationService`)
- Approval gate must block publish until operator confirms

## JERICHO-specific

- Threat monitor, VPN, Night Watch — feed from `JerichoBrainService` (create alongside gateway)

## CORTEXNODE-specific

- Seven-layer map live states from `api.cortexnode.ai/v1/nodes` (create route)
- Signal feed + brain activity viewer

## App Store

- See `APP_STORE_REVIEW_NOTES.md` in each repo root
- IAP: implement `ShellSubscriptionServing` with StoreKit 2 before unlocking paid digital features in-app
- Account deletion: in-app link → https://cortexnode.ai/account-deletion (required by Apple)

## Do not

- Fake LIVE / CONNECTED labels when gateway state is preview
- Paste secrets in chat — Keychain + server session only
- Unlock paid iOS features via Stripe-only without IAP compliance
