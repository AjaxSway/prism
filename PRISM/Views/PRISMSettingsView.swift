import SwiftUI

struct PRISMSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = CortexStoreManager.shared
    @State private var restoreStatus: RestoreStatus = .idle

    enum RestoreStatus { case idle, working, done, failed }


    private let v  = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let c  = Color(red: 0.133, green: 0.827, blue: 0.933)
    private let bg = Color(red: 0.008, green: 0.012, blue: 0.027)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("PRISM · SETTINGS")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(v).tracking(3)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20)).foregroundColor(v.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 32)

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PLATFORM CHANNELS")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(c.opacity(0.6)).tracking(2)
                        HStack(spacing: 8) {
                            Circle().fill(c).frame(width: 6, height: 6)
                                .shadow(color: c.opacity(0.9), radius: 3)
                            Text("Connect platforms in the Channels tab")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(c.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(c.opacity(0.35), lineWidth: 1))
                        .cornerRadius(6)
                        Text("PRISM posts directly to each platform. No third-party keys required.")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CORTEX BRAIN")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(v.opacity(0.6)).tracking(2)
                        HStack(spacing: 8) {
                            Circle().fill(v).frame(width: 6, height: 6)
                                .shadow(color: v.opacity(0.9), radius: 3)
                            Text("api.cortexnode.ai — HARDWIRED")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(v.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(v.opacity(0.35), lineWidth: 1))
                        .cornerRadius(6)
                        Text("The intelligence backbone is built in. No key required.")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Restore Purchases — Apple requires this to be accessible outside the paywall
                Button {
                    restoreStatus = .working
                    Task {
                        await store.restorePurchases()
                        restoreStatus = store.purchaseError == nil ? .done : .failed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { restoreStatus = .idle }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: restoreStatus == .done ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                            .font(.system(size: 16))
                        Text(restoreStatus == .working ? "RESTORING…" : restoreStatus == .done ? "RESTORED ✓" : restoreStatus == .failed ? "RESTORE FAILED" : "RESTORE PURCHASES")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .tracking(2)
                    }
                    .foregroundColor(restoreStatus == .done ? .green : restoreStatus == .failed ? .red : v.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(v.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(v.opacity(0.25), lineWidth: 1))
                    .cornerRadius(6)
                    .padding(.horizontal, 24)
                }
                .buttonStyle(.plain)
                .disabled(restoreStatus == .working)
                .padding(.bottom, 8)

                // Replay intro
                Button {
                    UserDefaults.standard.set(false, forKey: "hasSeenIntro_PRISM")
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                        Text("REPLAY SYSTEM INTRO")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .tracking(2)
                    }
                    .foregroundColor(v.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(v.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(v.opacity(0.25), lineWidth: 1))
                    .cornerRadius(6)
                    .padding(.horizontal, 24)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)

                VStack(spacing: 4) {
                    Text("© 2026 CORTEX Inc. All rights reserved.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(v.opacity(0.25)).tracking(1)
                    Text("PRISM is a product of CORTEXNODE INC.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(v.opacity(0.18)).tracking(1)
                }
                .padding(.bottom, 40)
            }
        }
    }

}
