import Foundation
import AudioToolbox

// MARK: - Constants

extension AudioObjectID {
    /// Convenience for `kAudioObjectSystemObject`.
    static let system = AudioObjectID(kAudioObjectSystemObject)
    /// Convenience for `kAudioObjectUnknown`.
    static let unknown = kAudioObjectUnknown

    /// `true` if this object has the value of `kAudioObjectUnknown`.
    var isUnknown: Bool { self == .unknown }

    /// `false` if this object has the value of `kAudioObjectUnknown`.
    var isValid: Bool { !isUnknown }
}

// MARK: - Concrete Property Helpers

extension AudioObjectID {
    /// Reads the value for `kAudioHardwarePropertyDefaultSystemOutputDevice`.
    static func readDefaultSystemOutputDevice() throws -> AudioDeviceID {
        try AudioObjectID.system.readDefaultSystemOutputDevice()
    }

    static func readProcessList() throws -> [AudioObjectID] {
        try AudioObjectID.system.readProcessList()
    }

    /// Reads `kAudioHardwarePropertyTranslatePIDToProcessObject` for the specific pid.
    static func translatePIDToProcessObjectID(pid: pid_t) throws -> AudioObjectID {
        try AudioObjectID.system.translatePIDToProcessObjectID(pid: pid)
    }

    /// Reads `kAudioHardwarePropertyProcessObjectList`.
    func readProcessList() throws -> [AudioObjectID] {
        try requireSystemObject()

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0

        var err = AudioObjectGetPropertyDataSize(self, &address, 0, nil, &dataSize)

        guard err == noErr else { throw "Error reading data size for \(address): \(err)" }

        var value = [AudioObjectID](repeating: .unknown, count: Int(dataSize) / MemoryLayout<AudioObjectID>.size)

        err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &value)

        guard err == noErr else { throw "Error reading array for \(address): \(err)" }

        return value
    }

    /// Reads `kAudioHardwarePropertyTranslatePIDToProcessObject` for the specific pid, should only be called on the system object.
    func translatePIDToProcessObjectID(pid: pid_t) throws -> AudioObjectID {
        try requireSystemObject()

        let processObject = try read(
            kAudioHardwarePropertyTranslatePIDToProcessObject,
            defaultValue: AudioObjectID.unknown,
            qualifier: pid
        )

        guard processObject.isValid else {
            throw "Invalid process identifier: \(pid)"
        }

        return processObject
    }

    func readProcessBundleID() -> String? {
        if let result = try? readString(kAudioProcessPropertyBundleID) {
            result.isEmpty ? nil : result
        } else {
            nil
        }
    }

    func readProcessIsRunning() -> Bool {
        (try? readBool(kAudioProcessPropertyIsRunning)) ?? false
    }

    /*
     public var kAudioProcessPropertyPID: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyBundleID: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyDevices: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyIsRunning: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyIsRunningInput: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyIsRunningOutput: AudioObjectPropertySelector { get }
     */

    /// Reads the value for `kAudioHardwarePropertyDefaultSystemOutputDevice`, should only be called on the system object.
    func readDefaultSystemOutputDevice() throws -> AudioDeviceID {
        try requireSystemObject()

        return try read(kAudioHardwarePropertyDefaultSystemOutputDevice, defaultValue: AudioDeviceID.unknown)
    }

    /// Reads the value for `kAudioDevicePropertyDeviceUID` for the device represented by this audio object ID.
    func readDeviceUID() throws -> String { try readString(kAudioDevicePropertyDeviceUID) }

    /// Reads the value for `kAudioTapPropertyFormat` for the device represented by this audio object ID.
    func readAudioTapStreamBasicDescription() throws -> AudioStreamBasicDescription {
        try read(kAudioTapPropertyFormat, defaultValue: AudioStreamBasicDescription())
    }

    private func requireSystemObject() throws {
        if self != .system { throw "Only supported for the system object." }
    }
}

// MARK: - Generic Property Access

extension AudioObjectID {
    func read<T, Q>(_ selector: AudioObjectPropertySelector,
                    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
                    defaultValue: T,
                    qualifier: Q) throws -> T
    {
        try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: defaultValue, qualifier: qualifier)
    }

    func read<T>(_ selector: AudioObjectPropertySelector,
                    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
                    defaultValue: T) throws -> T
    {
        try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: defaultValue)
    }

    func read<T, Q>(_ address: AudioObjectPropertyAddress, defaultValue: T, qualifier: Q) throws -> T {
        var inQualifier = qualifier
        let qualifierSize = UInt32(MemoryLayout<Q>.size(ofValue: qualifier))
        return try withUnsafeMutablePointer(to: &inQualifier) { qualifierPtr in
            try read(address, defaultValue: defaultValue, inQualifierSize: qualifierSize, inQualifierData: qualifierPtr)
        }
    }

    func read<T>(_ address: AudioObjectPropertyAddress, defaultValue: T) throws -> T {
        try read(address, defaultValue: defaultValue, inQualifierSize: 0, inQualifierData: nil)
    }

    func readString(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) throws -> String {
        try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: "" as CFString) as String
    }

    func readBool(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) throws -> Bool {
        let value: Int = try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: 0)
        return value == 1
    }

    private func read<T>(_ inAddress: AudioObjectPropertyAddress, defaultValue: T, inQualifierSize: UInt32 = 0, inQualifierData: UnsafeRawPointer? = nil) throws -> T {
        var address = inAddress

        var dataSize: UInt32 = 0

        var err = AudioObjectGetPropertyDataSize(self, &address, inQualifierSize, inQualifierData, &dataSize)

        guard err == noErr else {
            throw "Error reading data size for \(inAddress): \(err)"
        }

        var value: T = defaultValue
        err = withUnsafeMutablePointer(to: &value) { ptr in
            AudioObjectGetPropertyData(self, &address, inQualifierSize, inQualifierData, &dataSize, ptr)
        }

        guard err == noErr else {
            throw "Error reading data for \(inAddress): \(err)"
        }

        return value
    }
}

// MARK: - Debugging Helpers

private extension UInt32 {
    var fourCharString: String {
        String(cString: [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF),
            0
        ])
    }
}

extension AudioObjectPropertyAddress: @retroactive CustomStringConvertible {
    public var description: String {
        let elementDescription = mElement == kAudioObjectPropertyElementMain ? "main" : mElement.fourCharString
        return "\(mSelector.fourCharString)/\(mScope.fourCharString)/\(elementDescription)"
    }
}

public struct AudioInputDevice: Identifiable, Hashable {
    public let id: AudioDeviceID // AudioDeviceID (UInt32) is Hashable and can serve as Identifiable's id.
    public let uid: String // Unique identifier for the device (persistent across reboots)
    public let name: String

    public init(id: AudioDeviceID, uid: String, name: String) {
        self.id = id
        self.uid = uid
        self.name = name
    }
}

extension AudioObjectID {
    static func getAllInputDevices() throws -> [AudioInputDevice] {
        let allDeviceIDs = try AudioObjectID.system.getAllHardwareDevices()
        var inputDevices: [AudioInputDevice] = []

        for deviceID in allDeviceIDs {
            do {
                let inputChannelCount = try deviceID.getTotalInputChannelCount()
                if inputChannelCount > 0 {
                    let deviceName = try deviceID.getDeviceName()
                    let deviceUID = try deviceID.readDeviceUID()
                    inputDevices.append(AudioInputDevice(id: deviceID, uid: deviceUID, name: deviceName))
                }
            } catch {
                print("CoreAudioUtils: Could not fully query device \(deviceID): \(error)")
            }
        }
        return inputDevices
    }

    func getAllHardwareDevices() throws -> [AudioDeviceID] {
        try requireSystemObject()

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var err = AudioObjectGetPropertyDataSize(self, &address, 0, nil, &dataSize)
        guard err == noErr else {
            throw "CoreAudioUtils: Error reading data size for \(kAudioHardwarePropertyDevices.fourCharString): \(err)"
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        if deviceCount == 0 {
            return []
        }
        var deviceIDs = [AudioDeviceID](repeating: .unknown, count: deviceCount)

        err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &deviceIDs)
        guard err == noErr else {
            throw "CoreAudioUtils: Error reading device array for \(kAudioHardwarePropertyDevices.fourCharString): \(err)"
        }

        return deviceIDs
    }

    func getTotalInputChannelCount() throws -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var err = AudioObjectGetPropertyDataSize(self, &address, 0, nil, &dataSize)

        if err == kAudioHardwareUnknownPropertyError || dataSize == 0 {
            return 0
        }
        guard err == noErr else {
            throw "CoreAudioUtils: Error reading data size for input stream configuration on device \(self): \(err)"
        }

        let bufferListPtr = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { bufferListPtr.deallocate() }

        err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, bufferListPtr)
        guard err == noErr else {
            throw "CoreAudioUtils: Error reading input stream configuration for device \(self): \(err)"
        }

        let audioBufferList = bufferListPtr.assumingMemoryBound(to: AudioBufferList.self)
        var totalInputChannels: UInt32 = 0

        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for i in 0..<Int(buffers.count) {
            totalInputChannels += buffers[i].mNumberChannels
        }

        return totalInputChannels
    }

    func getDeviceName() throws -> String {
        return try readString(kAudioDevicePropertyDeviceNameCFString)
    }
} 