import Foundation

class EffectRunner {
    var effect: Command?

    private let controller: AuraUSBController

    init(controller: AuraUSBController) {
        self.controller = controller
    }

    var step: Int = 0
    var isDirect = false

    var command: Command?
    var device: AuraUSBDevice?
    var allAddressables = [AuraConnectedDevice]()

    private var observation: Any? = nil
    private var activity: NSObjectProtocol?
    private var timer: Timer?

    deinit {
        timer?.invalidate()
        timer = nil
        if let activity = activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        activity = nil
    }

    func run(command: Command?, on device: AuraUSBDevice) throws {
        step = 0

        self.command = command
        self.device = device
        self.allAddressables = [device.rgbDevice].compactMap { $0 } + device.addressables


        timer?.invalidate()
        timer = nil

        if let activity = activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        activity = nil

        if let command = command,
           command.isAnimated {
            let interval: TimeInterval = 0.01
            let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
                do {
                    try self?.tick()
                } catch {
                    print("oh no: ", error)
                }
            }
            timer.tolerance = interval
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer

            activity = ProcessInfo
                .processInfo
                .beginActivity(
                    options: .userInitiated,
                    reason: "Animating RGBs"
                )
        }

        try tick()
    }

    private func tick() throws {
        guard let device = device else {
            return
        }
        
        guard let command = command else {
            return
        }

        let ledCountPerCommand = 20

        for auraUSBDevice in allAddressables {
            if auraUSBDevice.type == .fixed {
                try controller.setEffect(
                    effect: .direct,
                    effectChannel: auraUSBDevice.effectChannel,
                    to: device.hidDevice
                )
            } else {
                let rgbs = command.rgbs(
                    capacity: Int(auraUSBDevice.numberOfLEDs),
                    step: step
                )
                
                let groups = rgbs.chunked(into: ledCountPerCommand)
                for (index, group) in groups.enumerated() {
                    try controller.setDirect(
                        group,
                        startLED: UInt8(index*group.count),
                        channel: auraUSBDevice.directChannel,
                        apply: index >= groups.count - 1,
                        to: device.hidDevice
                    )
                }
            }
        }

        step += 1
        
    }
}
