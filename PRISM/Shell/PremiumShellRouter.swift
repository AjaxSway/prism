import SwiftUI
import UIKit

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
                case .channels:
                    if config.appKind == .prism {
                        PrismChannelsView(env: env)
                    } else {
                        ShellModulesView(env: env)
                    }
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
                    ShellAboutView(config: env.config, palette: env.palette, brain: env.brain)
                case .nexus:
                    ShellNexusView(env: env)
                case .gaming:
                    ShellGamingView(env: env)
                case .world:
                    ShellWorldView(env: env)
                }
            }
            .id(env.selectedTab)
            .transition(
                .asymmetric(
                    insertion: .opacity
                        .combined(with: .scale(scale: 0.985))
                        .combined(with: .offset(x: tabSlideOffset(for: env.selectedTab), y: 8)),
                    removal: .opacity.combined(with: .scale(scale: 1.008)).combined(with: .offset(y: -6))
                )
            )
            .animation(.spring(response: 0.42, dampingFraction: 0.84), value: env.selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaPadding(.bottom, 210)

            VStack {
                Spacer()
                ShellHUDTabBar(selection: $env.selectedTab, palette: env.palette, tabs: config.barTabs, appKind: config.appKind)
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
        .shellInteractionOverlay(env: env)
        .onChange(of: env.selectedTab) { _, _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            ShellIntroMusic.shared.playIfAvailable()
        }
    }

    private func tabSlideOffset(for tab: ShellTab) -> CGFloat {
        guard config.appKind == .prism else { return 0 }
        switch tab {
        case .command: return -12
        case .modules: return -6
        case .activity: return 0
        case .studio: return 8
        case .settings: return 12
        case .about: return 16
        case .channels: return -14
        default: return 0
        }
    }
}
