import SwiftUI

struct PRISMSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blotatoKey  = UserDefaults.standard.string(forKey: "blotato_api_key") ?? ""
    @State private var saved = false

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
                    // Brain is hardwired to CORTEX endpoint — no key needed

                    keyField(
                        label: "BLOTATO API KEY",
                        hint: "blt_...",
                        text: $blotatoKey,
                        desc: "Override default key. Leave blank to use system default.",
                        color: c
                    )
                }
                .padding(.horizontal, 24)

                Button {
                    UserDefaults.standard.set(blotatoKey, forKey: "blotato_api_key")
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                } label: {
                    Text(saved ? "SAVED ✓" : "SAVE KEYS")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(saved ? .green : v)
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(v.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(saved ? Color.green.opacity(0.5) : v.opacity(0.4), lineWidth: 1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 28)

                Spacer()

                Text("PRISM · CONTENT LAYER · v1.1")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(v.opacity(0.2)).tracking(2)
                    .padding(.bottom, 40)
            }
        }
    }

    private func keyField(label: String, hint: String, text: Binding<String>, desc: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(color.opacity(0.6)).tracking(2)

            SecureField(hint, text: text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white)
                .padding(14)
                .background(color.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 1))
                .cornerRadius(6)
                .autocorrectionDisabled()

            Text(desc)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .lineSpacing(3)
        }
    }
}
