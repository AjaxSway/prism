import SwiftUI
import StoreKit

// MARK: - CORTEX Paywall
// Shown when a user tries to access a Pro or Operator feature on the Free tier.
// Cinematic HUD aesthetic. No dark patterns. Clear value, clear price, easy dismiss.

struct CortexPaywallView: View {
    @State private var store = CortexStoreManager.shared
    @Environment(\.dismiss) private var dismiss

    var requiredTier: CortexStoreManager.Tier = .pro
    var featureName: String = ""

    @State private var selectedProduct: Product? = nil
    @State private var purchaseSuccess = false
    @State private var showError = false

    private let accent = CortexPalette.primary

    var body: some View {
        ZStack {
            CortexPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 60)
                        .padding(.horizontal, 24)

                    if !featureName.isEmpty {
                        featureCallout
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                    }

                    tierCards
                        .padding(.horizontal, 16)
                        .padding(.top, 28)

                    freeComparison
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    purchaseButton
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    restoreButton
                        .padding(.top, 12)

                    legalNote
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 48)
                }
            }

            if store.isPurchasing {
                purchasingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(accent.opacity(0.5))
                }
            }
        }
        .onAppear {
            selectedProduct = requiredTier == .operator_ ? store.operatorProduct : store.proProduct
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.purchaseError ?? "Something went wrong. Please try again.")
        }
        .onChange(of: store.purchaseError) { _, err in
            if err != nil { showError = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text("UNLOCK CORTEX")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(accent)
                .tracking(4)

            Text("Five Systems.\nOne Brain.")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("One subscription covers every app in the CORTEX universe.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CortexPalette.neural)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Feature Callout

    private var featureCallout: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundColor(accent)
            Text("\(featureName) requires \(requiredTier.label).")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(CortexPalette.neural)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.2), lineWidth: 0.5))
        )
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        VStack(spacing: 12) {
            if let pro = store.proProduct {
                tierCard(
                    product: pro,
                    tier: .pro,
                    badge: "PRO",
                    tagline: "Personal Intelligence OS",
                    features: [
                        "CORTEX — full iOS app",
                        "SIGNAL ZERO — iPhone + Mac terminal",
                        "PRISM — core publishing (3 platforms)",
                        "Persistent memory",
                        "Premium voice",
                        "Up to 100 automations/mo"
                    ],
                    accentColor: accent
                )
            }

            if let op = store.operatorProduct {
                tierCard(
                    product: op,
                    tier: .operator_,
                    badge: "OPERATOR",
                    tagline: "Full System Access",
                    features: [
                        "Everything in Pro",
                        "JERICHO — 24/7 threat protection",
                        "CORTEXNODE — full system map",
                        "PRISM — all platforms, unlimited posts",
                        "Unlimited automations",
                        "Advanced analytics"
                    ],
                    accentColor: Color(red: 0.6, green: 0.3, blue: 1.0),
                    isRecommended: true,
                    originalValue: "$298/mo if purchased individually"
                )
            }

            if store.isLoading {
                HStack { ProgressView().tint(accent); Text("Loading...").font(.system(size: 12, design: .monospaced)).foregroundColor(CortexPalette.neural) }
                    .padding()
            }
        }
    }

    private func tierCard(product: Product, tier: CortexStoreManager.Tier, badge: String, tagline: String, features: [String], accentColor: Color, isRecommended: Bool = false, originalValue: String? = nil) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            selectedProduct = product
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(badge)
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(accentColor)
                                .tracking(3)
                            if isRecommended {
                                Text("BEST VALUE")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .tracking(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(tagline)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(CortexPalette.neural)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("/ month")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(CortexPalette.neural)
                    }
                }

                if let val = originalValue {
                    Text(val)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(accentColor.opacity(0.7))
                }

                Divider().background(accentColor.opacity(0.1))

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 5, height: 5)
                                .shadow(color: accentColor.opacity(0.8), radius: 3)
                            Text(feature)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(isSelected ? 0.1 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(accentColor.opacity(isSelected ? 0.6 : 0.15), lineWidth: isSelected ? 1.5 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Free Comparison

    private var freeComparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FREE TIER INCLUDES")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(CortexPalette.neural)
                .tracking(3)
            HStack(spacing: 16) {
                freeFeature("1 briefing/day")
                freeFeature("Basic voice")
                freeFeature("Core memory")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(CortexPalette.surface.opacity(0.5))
        )
    }

    private func freeFeature(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(CortexPalette.neural)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(CortexPalette.neural)
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task {
                let success = await store.purchase(product)
                if success {
                    purchaseSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
                }
            }
        } label: {
            HStack(spacing: 10) {
                if purchaseSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("UNLOCKED")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .tracking(2)
                } else {
                    Text(selectedProduct.map { "UNLOCK \($0.displayName.uppercased())" } ?? "SELECT A PLAN")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .tracking(2)
                    if let p = selectedProduct {
                        Text("· \(p.displayPrice)/mo")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .opacity(0.7)
                    }
                }
            }
            .foregroundColor(purchaseSuccess ? .black : (selectedProduct != nil ? .black : accent))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(purchaseSuccess ? CortexPalette.positive : (selectedProduct != nil ? accent : accent.opacity(0.15)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accent.opacity(selectedProduct != nil ? 0 : 0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedProduct == nil || store.isPurchasing || purchaseSuccess)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(CortexPalette.neural)
                .underline()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legal Note

    private var legalNote: some View {
        Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your iPhone Settings → Subscriptions. Payment charged to your Apple ID account at confirmation of purchase.")
            .font(.system(size: 10))
            .foregroundColor(CortexPalette.neural.opacity(0.5))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
    }

    // MARK: - Purchasing Overlay

    private var purchasingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.4).tint(accent)
                Text("PROCESSING...")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(accent)
                    .tracking(3)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CortexPalette.background)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.3), lineWidth: 1))
            )
        }
    }
}

// MARK: - Paywall Modifier
// Usage: .cortexPaywall(required: .pro, feature: "Persistent Memory")

struct CortexPaywallModifier: ViewModifier {
    @State private var store = CortexStoreManager.shared
    @State private var showPaywall = false
    let required: CortexStoreManager.Tier
    let feature: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                if store.currentTier < required { showPaywall = true }
            }
            .sheet(isPresented: $showPaywall) {
                NavigationStack {
                    CortexPaywallView(requiredTier: required, featureName: feature)
                }
            }
    }
}

extension View {
    func cortexPaywall(required: CortexStoreManager.Tier, feature: String = "") -> some View {
        modifier(CortexPaywallModifier(required: required, feature: feature))
    }
}
