import Foundation

enum EffectColorMode: Equatable {
    case none
    case count(Int)
    case dynamic

    var count: Int {
        switch self {
        case .none:
            return 0
        case .count(let count):
            return count
        case .dynamic:
            return 3
        }
    }
}

protocol Effect {
    var name: String { get }
    var colorMode: EffectColorMode { get }

    func command(for colors: [CommandColor]) -> Command
}

struct DirectEffect: Effect {
    let name: String
    let builder: (([CommandColor]) -> Command)
    let colorMode: EffectColorMode

    func command(for colors: [CommandColor]) -> Command {
        return builder(colors)
    }
}
