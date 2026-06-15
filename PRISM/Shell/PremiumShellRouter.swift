import SwiftUI

struct PremiumShellRouter: View {
    let config: PremiumShellConfig
    @State private var env: ShellEnvironment

    init(config: PremiumShellConfig) {
        self.config = config
        _env = State(initialValue: ShellEnvironment(config: config))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                switch env.selectedTab {
                case .home:
                    ShellHomeView(env: env)
                case .command:
                    ShellCommandCenterView(env: env)
                case .modules:
                    ShellModulesView(env: env)
                case .activity:
                    ShellActivityView(env: env)
                case .studio:
                    if config.appKind == .prism {
                        PrismImageStudioView(env: env)
                    } else if config.barTabs.contains(.studio) {
                        ImageGenerationView(env: env)
                    } else {
                        ShellHomeView(env: env)
                    }
                case .settings:
                    ShellSettingsView(env: env)
                case .about:
                    ShellAboutView(config: env.config, palette: env.palette)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaPadding(.bottom, 96)

            VStack {
                Spacer()
                ShellHUDTabBar(selection: $env.selectedTab, palette: env.palette, tabs: config.barTabs)
                    .padding(.horizontal, 8)

                ShellFloatingHubOrb(
                    label: env.config.alias,
                    appKind: env.config.appKind,
                    secondaryColor: env.config.refractionPink ?? env.config.accentDeep,
                    state: env.orbState,
                    palette: env.palette,
                    isActive: env.selectedTab == .home
                ) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        if env.selectedTab == .home {
                            env.demoOrbCycle()
                        } else {
                            env.selectedTab = .home
                        }
                    }
                }
                .offset(y: -34)
                .padding(.bottom, 12)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .preferredColorScheme(.dark)
    }
}
