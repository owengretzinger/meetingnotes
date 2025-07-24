import SwiftUI
import AudioToolbox
import OSLog
import AVFoundation

enum TapTarget {
    case singleProcess(AudioProcess)
    case systemAudio(processObjectIDs: [AudioObjectID])

    var displayName: String {
        switch self {
        case .singleProcess(let process):
            return process.name
        case .systemAudio:
            return "System Audio Output"
        }
    }

    var iconImage: NSImage {
        switch self {
        case .singleProcess(let process):
            return process.icon
        case .systemAudio:
            let genericAppIcon = NSWorkspace.shared.icon(for: .applicationBundle)
            genericAppIcon.size = NSSize(width: 32, height: 32)
            return genericAppIcon
        }
    }

    var loggingProcessName: String {
        switch self {
        case .singleProcess(let process):
            return process.name
        case .systemAudio:
            return "SystemAudioOutput"
        }
    }
}

@Observable
final class ProcessTap {

    typealias InvalidationHandler = (ProcessTap) -> Void

    let target: TapTarget
    let muteWhenRunning: Bool
    private let logger: Logger

    private(set) var errorMessage: String? = nil

    init(target: TapTarget, muteWhenRunning: Bool = false) {
        self.target = target
        self.muteWhenRunning = muteWhenRunning
        self.logger = Logger(subsystem: "owen.meetingnotes", category: "\(String(describing: ProcessTap.self))(\(target.loggingProcessName))")
    }

    @ObservationIgnored
    private var processTapID: AudioObjectID = .unknown
    @ObservationIgnored
    private var aggregateDeviceID = AudioObjectID.unknown
    @ObservationIgnored
    private var deviceProcID: AudioDeviceIOProcID?
    @ObservationIgnored
    private(set) var tapStreamDescription: AudioStreamBasicDescription?
    @ObservationIgnored
    private var invalidationHandler: InvalidationHandler?

    @ObservationIgnored
    private(set) var activated = false

    var displayName: String {
        target.displayName
    }

    @MainActor
    func activate() {
        guard !activated else { return }
        activated = true

        logger.debug(#function)
        self.errorMessage = nil

        do {
            try prepare()
        } catch {
            logger.error("\(error, privacy: .public)")
            self.errorMessage = error.localizedDescription
        }
    }

    func invalidate() {
        guard activated else { return }
        defer { activated = false }

        logger.debug(#function)

        invalidationHandler?(self)
        self.invalidationHandler = nil

        if aggregateDeviceID.isValid {
            var err: OSStatus

            err = AudioDeviceStop(aggregateDeviceID, deviceProcID)
            if err != noErr { 
                logger.warning("Failed to stop aggregate device: \(err, privacy: .public)")
            }

            if let deviceProcID {
                err = AudioDeviceDestroyIOProcID(aggregateDeviceID, deviceProcID)
                if err != noErr {
                    logger.warning("Failed to destroy device I/O proc: \(err, privacy: .public)")
                }
                self.deviceProcID = nil
            }

            err = AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            if err != noErr {
                logger.warning("Failed to destroy aggregate device: \(err, privacy: .public)")
            }
            aggregateDeviceID = .unknown
        }

        if processTapID.isValid {
            let errTapDestroy = AudioHardwareDestroyProcessTap(processTapID)
            if errTapDestroy != noErr {
                logger.warning("Failed to destroy audio tap: \(errTapDestroy, privacy: .public)")
            }
            self.processTapID = .unknown
        }
    }

    private func prepare() throws {
        errorMessage = nil

        let tapDescription: CATapDescription
        switch self.target {
        case .singleProcess(let process):
            tapDescription = CATapDescription(stereoMixdownOfProcesses: [process.objectID])
            logger.debug("Configuring tap for single process objectID: \(process.objectID)")
        case .systemAudio(let processObjectIDs):
            if processObjectIDs.isEmpty {
                logger.warning("System audio tap configured with an empty list of processObjectIDs. This might not capture any audio or behave unexpectedly.")
            }
            tapDescription = CATapDescription(stereoMixdownOfProcesses: processObjectIDs)
            logger.debug("Configuring tap for system audio output using \(processObjectIDs.count) explicit processes.")
        }
        
        tapDescription.uuid = UUID()
        tapDescription.muteBehavior = muteWhenRunning ? .mutedWhenTapped : .unmuted
        var tapID: AUAudioObjectID = .unknown
        let errTapCreation = AudioHardwareCreateProcessTap(tapDescription, &tapID)

        guard errTapCreation == noErr else {
            errorMessage = "Process/System tap creation failed with error \(errTapCreation)"
            throw errorMessage ?? "Unknown error creating tap."
        }

        logger.debug("Created process/system tap #\(tapID, privacy: .public). Associated UUID: \(tapDescription.uuid.uuidString)")
        self.processTapID = tapID

        let allDeviceIDs = try AudioObjectID.system.getAllHardwareDevices()
        var outputUIDs: [String] = []
        var outputDeviceIDs: [AudioDeviceID] = []
        for devID in allDeviceIDs {
            do {
                let outputChans = try devID.getTotalOutputChannelCount()
                if outputChans > 0 {
                    let devUID = try devID.readDeviceUID()
                    outputUIDs.append(devUID)
                    outputDeviceIDs.append(devID)
                }
            } catch {
                logger.warning("Ignored device \(devID): \(error.localizedDescription)")
            }
        }

        if outputUIDs.isEmpty {
            throw "No hardware output devices found!"
        }

        let systemOutputID: AudioDeviceID
        do {
            logger.debug("Attempting to read default system output device ID...")
            systemOutputID = try AudioDeviceID.readDefaultSystemOutputDevice()
            logger.debug("Successfully read default system output device ID: \(systemOutputID)")
        } catch {
            logger.error("Failed to read default system output device ID: \(error)")
            throw error // Propagate error
        }

        let mainSubdeviceUID: String
        do {
            logger.debug("Attempting to read device UID for systemOutputID: \(systemOutputID)...")
            mainSubdeviceUID = try systemOutputID.readDeviceUID()
            logger.debug("Successfully read mainSubdeviceUID: \(mainSubdeviceUID)")
        } catch {
            logger.error("Failed to read device UID for systemOutputID \(systemOutputID): \(error)")
            throw error // Propagate error
        }
        
        let subDeviceListForAggregate: [[String: Any]]
        let aggregateDeviceName: String
        let aggregateUID = UUID().uuidString

        switch self.target {
        case .systemAudio:
            aggregateDeviceName = "Tap-SysAgg-\(mainSubdeviceUID.prefix(8))"
            subDeviceListForAggregate = [
                [kAudioSubDeviceUIDKey: mainSubdeviceUID]
            ]
            logger.debug("System mode: mainSubdeviceUID for aggregate: \(mainSubdeviceUID). Aggregate name: \(aggregateDeviceName)")
        case .singleProcess:
            aggregateDeviceName = "Tap-\(self.displayName)-Agg"
            subDeviceListForAggregate = outputUIDs.map { [kAudioSubDeviceUIDKey: $0] }
            logger.debug("Process mode: Aggregate subDeviceList from outputUIDs. Aggregate name: \(aggregateDeviceName)")
        }

        let descriptionForAggregate: [String: Any] = [
            kAudioAggregateDeviceNameKey: aggregateDeviceName,
            kAudioAggregateDeviceUIDKey: aggregateUID,
            kAudioAggregateDeviceMainSubDeviceKey: mainSubdeviceUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceSubDeviceListKey: subDeviceListForAggregate,
            kAudioAggregateDeviceTapListKey: [
                [
                    kAudioSubTapDriftCompensationKey: true,
                    kAudioSubTapUIDKey: tapDescription.uuid.uuidString
                ]
            ]
        ]
        logger.debug("Aggregate device description prepared. Main sub-device UID: \(mainSubdeviceUID), Tap UUID: \(tapDescription.uuid.uuidString)")
        
        aggregateDeviceID = AudioObjectID.unknown
        do {
            logger.debug("Calling AudioHardwareCreateAggregateDevice...")
            let errAggDeviceCreation = AudioHardwareCreateAggregateDevice(descriptionForAggregate as CFDictionary, &aggregateDeviceID)
            if errAggDeviceCreation != noErr {
                logger.error("AudioHardwareCreateAggregateDevice failed with error: \(errAggDeviceCreation).")
                throw "Failed to create aggregate device: \(errAggDeviceCreation)"
            }
            logger.debug("Successfully created aggregate device #\(self.aggregateDeviceID, privacy: .public)")
        } catch {
            logger.error("EXCEPTION during AudioHardwareCreateAggregateDevice block: \(error)")
            throw error // Propagate error
        }

        do {
            logger.debug("Attempting to read audio tap stream basic description for tapID #\(tapID)...")
            self.tapStreamDescription = try tapID.readAudioTapStreamBasicDescription()
            logger.debug("Successfully read tap stream description: \(String(describing: self.tapStreamDescription))")
        } catch {
            logger.error("Failed to read audio tap stream basic description for tapID #\(tapID): \(error)")
            throw error // Propagate error
        }
    }

    func run(on queue: DispatchQueue, ioBlock: @escaping AudioDeviceIOBlock, invalidationHandler: @escaping InvalidationHandler) throws {
        assert(activated, "\(#function) called with inactive tap!")
        assert(self.invalidationHandler == nil, "\(#function) called with tap already active!")

        errorMessage = nil
        logger.debug("Run tap!")
        self.invalidationHandler = invalidationHandler

        var err = AudioDeviceCreateIOProcIDWithBlock(&deviceProcID, aggregateDeviceID, queue, ioBlock)
        guard err == noErr else { throw "Failed to create device I/O proc: \(err)" }

        err = AudioDeviceStart(aggregateDeviceID, deviceProcID)
        guard err == noErr else { throw "Failed to start audio device: \(err)" }
    }

    deinit { invalidate() }

}

private extension AudioDeviceID {
    func getTotalOutputChannelCount() throws -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var err = AudioObjectGetPropertyDataSize(self, &address, 0, nil, &dataSize)
        if err == kAudioHardwareUnknownPropertyError || dataSize == 0 {
            return 0
        }
        guard err == noErr else {
            throw "Error reading data size for output stream configuration: \(err)"
        }
        let bufferListPtr = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { bufferListPtr.deallocate() }
        err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, bufferListPtr)
        guard err == noErr else {
            throw "Error reading output stream configuration: \(err)"
        }
        let audioBufferList = bufferListPtr.assumingMemoryBound(to: AudioBufferList.self)
        var totalOutputChannels: UInt32 = 0
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for i in 0..<Int(buffers.count) {
            totalOutputChannels += buffers[i].mNumberChannels
        }
        return totalOutputChannels
    }
}

@Observable
final class ProcessTapRecorder {

    let fileURL: URL
    let tapDisplayName: String
    let icon: NSImage

    private(set) var currentAudioLevel: Float = 0.0

    private let queue = DispatchQueue(label: "ProcessTapRecorder", qos: .userInitiated)
    private let logger: Logger

    @ObservationIgnored
    private weak var _tap: ProcessTap?

    private(set) var isRecording = false

    init(fileURL: URL, tap: ProcessTap) {
        self.tapDisplayName = tap.displayName
        self.fileURL = fileURL
        self._tap = tap
        self.logger = Logger(subsystem: "owen.meetingnotes", category: "\(String(describing: ProcessTapRecorder.self))(\(fileURL.lastPathComponent))")
        
        self.icon = tap.target.iconImage
    }

    private var tap: ProcessTap {
        get throws {
            guard let _tap else { throw "Process tap unavailable" }
            return _tap
        }
    }

    @ObservationIgnored
    private var currentFile: AVAudioFile?

    @MainActor
    func start() throws {
        logger.debug(#function)
        
        guard !isRecording else {
            logger.warning("\(#function, privacy: .public) while already recording")
            return
        }

        self.isRecording = true

        let tap = try tap

        if !tap.activated {
            tap.activate()
            if let errorMessage = tap.errorMessage {
                logger.error("Tap activation error: \(errorMessage)")
                self.isRecording = false
                throw errorMessage
            }
        }

        guard var streamDescription = tap.tapStreamDescription else {
            logger.error("Tap stream description not available.")
            self.isRecording = false
            throw "Tap stream description not available."
        }

        guard let format = AVAudioFormat(streamDescription: &streamDescription) else {
            logger.error("Failed to create AVAudioFormat from stream description.")
            self.isRecording = false
            throw "Failed to create AVAudioFormat."
        }

        logger.info("Using audio format: \(format, privacy: .public)")

        let settings: [String: Any] = [
            AVFormatIDKey: streamDescription.mFormatID,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount
        ]
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        do {
            let file = try AVAudioFile(forWriting: fileURL, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: format.isInterleaved)
            self.currentFile = file
        } catch {
            logger.error("Failed to create AVAudioFile for writing: \(error, privacy: .public)")
            self.isRecording = false
            throw error
        }

        #if DEBUG
        let systemModeActive: Bool
        if case .systemAudio = tap.target {
            systemModeActive = true
        } else {
            systemModeActive = false
        }
        print("DEBUG: About to call tap.run... (system mode? \(systemModeActive))")
        #endif

        try tap.run(on: queue) { [weak self] inNow, inInputData, inInputTime, outOutputData, inOutputTime in
            guard let self else { return }
            var localAudioLevel: Float = 0.0
            
            do {
                guard let currentFile = self.currentFile else {
                    DispatchQueue.main.async { if self.currentAudioLevel != 0.0 { self.currentAudioLevel = 0.0 } }
                    return
                }
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: inInputData, deallocator: nil) else {
                    print("ProcessTapRecorder: Failed to create PCM buffer")
                    DispatchQueue.main.async { if self.currentAudioLevel != 0.0 { self.currentAudioLevel = 0.0 } }
                    return
                }
                
                var rms: Float = 0.0
                if let floatChannelData = buffer.floatChannelData, buffer.frameLength > 0 {
                    let channelData = floatChannelData[0]
                    let frameLength = Int(buffer.frameLength)
                    var sumOfSquares: Float = 0.0
                    for i in 0..<frameLength {
                        let sample = channelData[i]
                        sumOfSquares += sample * sample
                    }
                    rms = sqrt(sumOfSquares / Float(frameLength))
                    
                    #if DEBUG
                    if case .systemAudio = (try? self.tap)?.target {
                        print("SYSTEM MODE: buffer.frameLength = \(frameLength), RMS = \(rms)")
                        if rms == 0.0 {
                            print("SYSTEM MODE: WARNING: Audio buffer is silent (RMS == 0.0)")
                        }
                    }
                    #endif
                }
                
                localAudioLevel = min(max(rms * 2.0, 0.0), 1.0)

                if buffer.frameLength == 0 {
                    print("ProcessTapRecorder: Warning - received zero frames!")
                }

                try currentFile.write(from: buffer)

            } catch {
                self.logger.error("Buffer write error: \(error, privacy: .public)")
                print("ProcessTapRecorder: Buffer write error:", error)
                localAudioLevel = 0.0
            }
            
            DispatchQueue.main.async {
                self.currentAudioLevel = localAudioLevel
            }

        } invalidationHandler: { [weak self] tap in
            guard let self else { return }
            DispatchQueue.main.async {
                self.handleInvalidation()
            }
        }
        print("ProcessTapRecorder: Recording started (isRecording set to true).")
    }

    @MainActor
    func stop() {
        logger.debug(#function)
        guard isRecording else { return }
        
        self.currentAudioLevel = 0.0
        self.isRecording = false

        guard let tapToInvalidate = try? self.tap else {
            logger.warning("Tap unavailable during stop. Cleaning up recorder state.")
            self.currentFile = nil
            return
        }
        
        tapToInvalidate.invalidate()
            
        self.currentFile = nil
    }

    @MainActor
    private func handleInvalidation() {
        logger.debug("Handling tap invalidation in recorder.")
        if isRecording {
            logger.info("Tap invalidated while recording. Stopping recording.")
            self.currentFile = nil
            self.isRecording = false
            self.currentAudioLevel = 0.0
        }
    }
} 