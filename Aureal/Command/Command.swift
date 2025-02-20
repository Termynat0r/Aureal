import Foundation


protocol Command {
    var isAnimated: Bool { get }
    func rgbs(capacity: Int, step: Int) -> [CommandColor]
}

struct StaticCommand: Command {
    let color: CommandColor

    var isAnimated: Bool {
        false
    }

    init(color: CommandColor) {
        self.color = color
    }

    func rgbs(capacity: Int, step: Int) -> [CommandColor] {
        return [color].repeated(capacity: capacity)
    }
}

struct SpacedCommand: Command {
    let color: CommandColor

    var isAnimated: Bool {
        true
    }

    init(color: CommandColor) {
        self.color = color
    }

    func rgbs(capacity: Int, step: Int) -> [CommandColor] {
        let step = step / 10

        let colors = [color, .black]
            .stretched(by: 2)

        return colors
            .wrap(first: step % colors.count)
            .repeated(capacity: capacity)
    }
}

class GradientCommand: Command {
    let gradients: [RGBGradient]

    private let colors: [CommandColor]
    private let steps = 200

    var isAnimated: Bool {
        true
    }

    convenience init(from: CommandColor, to: CommandColor) {
        self.init(colors: [from, to, from])
    }

    convenience init(colors: [CommandColor]) {
        let gradients: [RGBGradient]
        if colors.count <= 0 {
            gradients = [RGBGradient(from: CommandColor.black, to: CommandColor.black)]
        } else if colors.count == 1 {
            gradients = [RGBGradient(from: colors[0], to: colors[0])]
        } else {
            var gx = [RGBGradient]()

            for idx in 0..<colors.count - 1 {
                let from = colors[idx]
                let to = colors[idx + 1]

                let next = RGBGradient(from: from, to: to)
                gx.append(next)
            }

            gradients = gx
        }

        self.init(gradients: gradients)
    }

    init(gradients: [RGBGradient]) {
        self.gradients = gradients

        var colors = [CommandColor]()
        for gradient in gradients {
            colors += gradient.colors(steps)
        }

        self.colors = colors
    }

    func rgbs(capacity: Int, step: Int) -> [CommandColor] {
        let step = step % colors.count

        return (0..<capacity).map { idx in
            let offset = (step - idx * (steps / 10)) %% colors.count
            return colors[offset]
        }
    }
}

class RollingGradientCommand: GradientCommand {
    override init(gradients: [RGBGradient]) {
        guard gradients.count > 0 else {
            super.init(gradients: gradients)
            return
        }

        let wrap = RGBGradient(
            from: gradients.last!.to,
            to: gradients.first!.from
        )

        super.init(gradients: gradients + [wrap])
    }
}

struct Patriotism🦅DirectCommand: Command {
    let colors = [CommandColor.red, CommandColor.white, CommandColor.blue].stretched(by: 2)

    var isAnimated: Bool {
        true
    }

    func rgbs(capacity: Int, step: Int) -> [CommandColor] {
        let step = step / 10
        let out = colors
            .wrap(first: step % colors.count)
            .repeated(capacity: capacity)

        return Array(out)
    }
}
