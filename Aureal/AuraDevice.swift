import Combine
import Foundation

enum AuraDeviceConnectionState {
    case disconnected
    case connecting
    case connected
}

class AuraUSBDevice: CustomStringConvertible {
    let hidDevice: HIDDevice

    var rgbDevice: AuraConnectedDevice?
    var addressables = [AuraConnectedDevice]()
    var firmware: String?

    @Published var connectionState = AuraDeviceConnectionState.disconnected

    init(hidDevice: HIDDevice) {
        self.hidDevice = hidDevice
    }

    var name: String {
        hidDevice.name
    }

    var description: String {
        "<" +
            "firmware: \(String(describing: firmware)), " +
            "connectionState: \(connectionState), " +
            "root: \(String(describing: rgbDevice)), " +
            "addressables: \(addressables)" +
            ">"
    }
}

struct AuraUSBDeviceConfiguration {
    private let data: Data

    init(data: Data) {
        self.data = data

        for i in stride(from: 0, to: data.count, by: 6) {
            print(
                String(
                    format: "%02X: %02X %02X %02X %02X %02X %02X ",
                    arguments: [
                        i,
                        data[i + 0],
                        data[i + 1],
                        data[i + 2],
                        data[i + 3],
                        data[i + 4],
                        data[i + 5],
                    ]
                )
            )
        }

        // config: 60 bytes
//        00: 1E 9F 02 01 00 00 <- 2 addressable devices
//        06: 78 3C 00 01 00 00 <- addressable device 1: 0x78 (120) LEDs
//        0C: 78 3C 00 00 00 00 <- addressable device 2: 0x78 (120) LEDs
//        12: 00 00 00 00 00 00
//        18: 00 00 00 08 0A 02 <- mainboard: 8 mainboard LEDs
//        1E: 01 F4 00 00 00 00
//        24: 00 00 00 00 00 00
//        2A: 00 00 00 00 00 00
//        30: 00 00 00 00 00 00
//        36: 00 00 00 00 00 00
        
/* Config for product-id 0x1872:

 00: 1F FF 04 01 00 02 <- adressable devices says 4, although only 1
 06: 00 78 01 3E 00 02 <- adressable device with 0x78 (120) LEDs is correct
 0C: 00 78 01 3E 00 02
 12: 00 3C 01 3E 00 02
 18: 00 00 00 FF 00 00 <- FF mainboard LEDs? Maybe something to do with the required "ec 3b 00 00 ff" command
 1E: 00 00 00 00 00 00
 24: 00 00 00 00 00 00
 2A: 00 00 00 00 00 00
 30: 00 00 00 00 00 00
 36: 00 00 00 00 00 00
 
 */
    }

    var addressableChannelCount: UInt8 {
        1
    }

    var mainboardLEDCount: UInt8 {
        data[0x1b]
    }

    private func offsetForDevice(at index: UInt8) -> Int {
        return 6 * (Int(index) + 1)
    }

    func addressableLEDCount(at index: UInt8) -> UInt8 {
        let offset = offsetForDevice(at: index)

        return data[offset + 0x01]
    }

    var rootDevice: AuraConnectedDevice {
        .init(
            effectChannel: 0x0,
            directChannel: 0x4,
            numberOfLEDs: mainboardLEDCount,
            type: .fixed,
            name: "Root"
        )
    }

    var addressableDevices: [AuraConnectedDevice] {
        (0..<addressableChannelCount).map { index -> AuraConnectedDevice in
            .init(
                effectChannel: index + 1,
                directChannel: index,
                numberOfLEDs: addressableLEDCount(at: index),
                type: .addressable,
                name: "Device: \(index + 1)"
            )
        }
    }
}

enum AuraConnectedDeviceType {
    case fixed
    case addressable
}

struct AuraConnectedDevice {
    let effectChannel: UInt8
    let directChannel: UInt8
    let numberOfLEDs: UInt8
    let type: AuraConnectedDeviceType

    let name: String?
}
