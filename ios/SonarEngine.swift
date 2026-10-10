// SonarEngine.swift
//
// Turns the iPhone into a sonar: plays near-ultrasonic tones from the speaker,
// records the microphone, and streams the raw samples to the Mac over UDP
// (phone_receiver.py does the tracking). Also saves a WAV of every take.
//
// Add to an app target (the PushupTimeDev scheme is fine) and add to Info.plist:
//   NSMicrophoneUsageDescription   "Sonar listens for echoes of the tone it plays."
//   NSLocalNetworkUsageDescription "Streams sonar samples to your Mac."
//
// Packet format: 8-byte header (UInt32 sequence, UInt32 flags; bit 0 = phone
// is moving) followed by Float32 mono samples at 48 kHz, little-endian.

import AVFoundation
import CoreMotion
import Foundation
import Network

final class SonarEngine: ObservableObject {
    // iPhone speakers roll off sharply above about 20 kHz, so stay below it.
    var tones: [Double] = [18_500, 19_100, 19_700]
    var amplitude: Float = 0.3

    @Published private(set) var running = false
    @Published private(set) var status = "Idle"
    @Published private(set) var lastFileURL: URL?

    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var sampleIndex: Int64 = 0
    private var file: AVAudioFile?
    private var udp: NWConnection?
    private var seq: UInt32 = 0
    private let motion = CMMotionManager()
    private var phoneMoving = false

    func start(macHost: String?, port: UInt16 = 5005, record: Bool = true) throws {
        let session = AVAudioSession.sharedInstance()
        // .measurement turns off the system's voice processing (gain control,
        // echo cancellation), which would otherwise erase the echo we need.
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.01)
        try session.setActive(true)

        // Prefer the microphone on the screen side: face-up, it points at the chest.
        if let mic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
            try session.setPreferredInput(mic)
            if let front = mic.dataSources?.first(where: { $0.orientation == .front }) {
                try? mic.setPreferredDataSource(front)
            }
        }

        let fs = session.sampleRate
        let outFormat = AVAudioFormat(standardFormatWithSampleRate: fs, channels: 1)!
        let tones = self.tones
        let amp = self.amplitude
        let rampLen = 0.05 * fs
        sampleIndex = 0

        let src = AVAudioSourceNode { [unowned self] _, _, frameCount, abl -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let n = Int(frameCount)
            for frame in 0..<n {
                let i = Double(self.sampleIndex + Int64(frame))
                var v = 0.0
                for f in tones {
                    // Double precision phase, wrapped, so the tone stays clean.
                    let cycles = (f * i / fs).truncatingRemainder(dividingBy: 1.0)
                    v += sin(2.0 * .pi * cycles)
                }
                let gain = min(1.0, i / rampLen)  // fade in, no click
                let s = Float(v / Double(tones.count) * gain) * amp
                for b in buffers {
                    b.mData!.assumingMemoryBound(to: Float.self)[frame] = s
                }
            }
            self.sampleIndex += Int64(n)
            return noErr
        }
        source = src
        engine.attach(src)
        engine.connect(src, to: engine.mainMixerNode, format: outFormat)

        let input = engine.inputNode
        let inFormat = input.outputFormat(forBus: 0)

        if record {
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let url = dir.appendingPathComponent("sonar-\(stamp).wav")
            let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inFormat.sampleRate,
                                           channels: 1, interleaved: false)!
            file = try AVAudioFile(forWriting: url, settings: monoFormat.settings)
            lastFileURL = url
        }

        if let host = macHost, !host.isEmpty {
            let conn = NWConnection(host: NWEndpoint.Host(host),
                                    port: NWEndpoint.Port(rawValue: port)!, using: .udp)
            conn.start(queue: .global(qos: .userInitiated))
            udp = conn
        }

        input.installTap(onBus: 0, bufferSize: 1024, format: inFormat) { [weak self] buffer, _ in
            guard let self, let ch = buffer.floatChannelData?[0] else { return }
            let n = Int(buffer.frameLength)
            if let file = self.file,
               let mono = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: buffer.frameLength) {
                mono.frameLength = buffer.frameLength
                mono.floatChannelData![0].update(from: ch, count: n)
                try? file.write(from: mono)
            }
            if let udp = self.udp {
                var header = [self.seq.littleEndian, (self.phoneMoving ? UInt32(1) : 0).littleEndian]
                var data = Data(bytes: &header, count: 8)
                data.append(UnsafeBufferPointer(start: ch, count: n))
                udp.send(content: data, completion: .contentProcessed { _ in })
                self.seq &+= 1
            }
        }

        // Anti-cheat: shaking the phone is the classic way to fool rep counters.
        // Flag any movement so the Mac can refuse to count while it happens.
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 50.0
            motion.startDeviceMotionUpdates(to: .main) { [weak self] m, _ in
                guard let a = m?.userAcceleration else { return }
                let g = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
                self?.phoneMoving = g > 0.05
            }
        }

        try engine.start()
        running = true
        status = "Sonar on at \(Int(fs)) Hz" + (macHost.map { ", streaming to \($0)" } ?? "")
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        if let src = source { engine.detach(src) }
        source = nil
        file = nil  // closes the WAV
        udp?.cancel()
        udp = nil
        motion.stopDeviceMotionUpdates()
        try? AVAudioSession.sharedInstance().setActive(false)
        running = false
        status = "Stopped"
    }
}
