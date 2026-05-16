import SwiftUI

// MARK: - PRISM Settings
struct PRISMSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = UserDefaults.standard.string(forKey: "brain_api_key") ?? ""
    @State private var saved = false

    private let v = Color(red: 0.545, green: 0.361, blue: 0.965)
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("BRAIN API KEY")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(v.opacity(0.5)).tracking(2)

                    SecureField("sk-ant-...", text: $apiKey)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(v.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(v.opacity(0.3), lineWidth: 1))
                        .cornerRadius(6)
                        .autocorrectionDisabled()

                    Text("Required to activate PRISM intelligence. Your key is stored locally only.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .lineSpacing(3)
                }
                .padding(.horizontal, 24)

                Button {
                    UserDefaults.standard.set(apiKey, forKey: "brain_api_key")
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                } label: {
                    Text(saved ? "SAVED ✓" : "SAVE KEY")
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
                .padding(.top, 20)

                Spacer()

                Text("PRISM · CONTENT LAYER · v1.0")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(v.opacity(0.2)).tracking(2)
                    .padding(.bottom, 40)
            }
        }
    }
}
