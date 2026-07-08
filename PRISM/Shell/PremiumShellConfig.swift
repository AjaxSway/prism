import SwiftUI

enum ShellAppKind: String {
    case cortexNode
    case jericho
    case prism
}

struct PremiumShellConfig {
    let appKind: ShellAppKind
    let displayName: String
    let alias: String
    let ecosystemSubtitle: String
    let roleLine: String
    let identityLine: String
    let orbLabel: String
    let primaryActionTitle: String
    let primaryModuleId: String
    let accent: Color
    let accentDeep: Color
    /// PRISM refraction gradient secondary (violet/pink). Nil uses accent for mono apps.
    let refractionAccent: Color?
    let refractionPink: Color?
    let introHeroImageName: String
    let introVideoResourceName: String?
    let introTaglineTop: String
    let introTaglineAlias: String
    let introTaglineBottom: String
    let introStatusTitle: String
    let storagePrefix: String
    let modules: [ShellModuleDefinition]
    let topologyTitle: String
    let topologyHubLabel: String
    let topologyNodes: [ShellTopologyNode]
    let supportEmailPlaceholder: String
    let monthlyPriceDisplay: String
    let freeTierDisplay: String
    let aiDisclaimer: String
    /// Bottom bar tabs — home uses floating hub orb, not in this list.
    let barTabs: [ShellTab]

    var themeStorageKey: String { "\(storagePrefix).theme" }
    var hasEnteredStorageKey: String { "\(storagePrefix).hasEntered" }
}

struct ShellTopologyNode: Identifiable {
    let id: String
    let name: String
    let status: String
    let offsetX: CGFloat
    let offsetY: CGFloat

    init(id: String? = nil, name: String, status: String, offsetX: CGFloat, offsetY: CGFloat) {
        self.id = id ?? name
        self.name = name
        self.status = status
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}

struct ShellModuleDefinition: Identifiable, Hashable {
    enum Availability {
        case preview
        case locked
    }

    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let availability: Availability
}

enum ShellTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case command = "Command"
    case channels = "Channels"
    case modules = "Modules"
    case activity = "Activity"
    case studio = "Studio"
    case settings = "Settings"
    case about = "About"
    case nexus = "Nexus"
    case gaming = "Gaming"
    case world = "World"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .command: return "terminal.fill"
        case .channels: return "link.circle.fill"
        case .modules: return "square.grid.2x2.fill"
        case .activity: return "clock.arrow.circlepath"
        case .studio: return "photo.on.rectangle.angled"
        case .settings: return "gearshape.fill"
        case .about: return "shield.checkered"
        case .nexus: return "infinity"
        case .gaming: return "gamecontroller.fill"
        case .world: return "globe.americas.fill"
        }
    }
}
