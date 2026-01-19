import Foundation
import AVFoundation
import Combine

class RecordingService: NSObject, ObservableObject {
    static let shared = RecordingService()

    // MARK: - Published Properties

    @Published private(set) var isRecording = false
    @Published private(set) var isPaused = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var audioLevel: Float = 0
    @Published private(set) var error: RecordingError?

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }
    private var chunkTimer: Timer?
    private var durationTimer: Timer?
    private var levelTimer: Timer?

    private var currentSessionId: UUID?
    private var currentChunkNumber = 0
    private var uploadedChunks: [String] = []
    private var isAudioSessionPrepared = false

    private let chunkDuration: TimeInterval = 30 // seconds
    private let recordingDirectory: URL

    private var currentRecordingURL: URL {
        recordingDirectory.appendingPathComponent("chunk_\(currentChunkNumber).m4a")
    }

    // MARK: - Initialization

    override private init() {
        recordingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SeshRecapRecordings", isDirectory: true)

        super.init()

        try? FileManager.default.createDirectory(
            at: recordingDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Audio Session Preparation

    func prepareAudioSession() async {
        guard !isAudioSessionPrepared else { return }
        do {
            try await configureAudioSession()
            isAudioSessionPrepared = true
        } catch {
            print("Failed to prepare audio session: \(error)")
        }
    }

    // MARK: - Recording Control

    func startRecording(sessionId: UUID) async throws {
        guard !isRecording else { return }

        currentSessionId = sessionId
        currentChunkNumber = 0
        uploadedChunks = []

        if !isAudioSessionPrepared {
            try await configureAudioSession()
        }
        try await MainActor.run {
            try startNewChunk()
        }

        await MainActor.run {
            self.isRecording = true
            self.isPaused = false
            self.duration = 0
        }

        startTimers()
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }

        audioRecorder?.pause()
        durationTimer?.invalidate()
        levelTimer?.invalidate()
        chunkTimer?.invalidate()
        isPaused = true
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }

        audioRecorder?.record()
        startTimers()
        isPaused = false
    }

    func stopRecording() async throws -> [String] {
        guard isRecording else { return uploadedChunks }

        stopTimers()

        audioRecorder?.stop()

        // Upload final chunk
        try await uploadCurrentChunk()

        cleanupRecordingFiles()

        await MainActor.run {
            self.isRecording = false
            self.isPaused = false
            self.audioLevel = 0
        }

        isAudioSessionPrepared = false

        let chunks = uploadedChunks
        currentSessionId = nil
        uploadedChunks = []

        return chunks
    }

    func cancelRecording() {
        stopTimers()
        audioRecorder?.stop()
        cleanupRecordingFiles()

        isRecording = false
        isPaused = false
        audioLevel = 0
        duration = 0
        currentSessionId = nil
        uploadedChunks = []
        isAudioSessionPrepared = false
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() async throws {
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        // Give audio hardware time to fully initialize
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms
    }

    // MARK: - Chunk Management

    private func startNewChunk() throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: currentRecordingURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }

    private func uploadCurrentChunk() async throws {
        guard let sessionId = currentSessionId else { return }

        let chunkURL = currentRecordingURL
        guard FileManager.default.fileExists(atPath: chunkURL.path) else { return }

        let chunkData = try Data(contentsOf: chunkURL)
        let fileName = "\(sessionId)/chunk_\(currentChunkNumber).m4a"

        let uploadedPath = try await StorageService.shared.uploadAudio(
            data: chunkData,
            path: fileName
        )

        uploadedChunks.append(uploadedPath)

        try? FileManager.default.removeItem(at: chunkURL)
    }

    @objc private func chunkTimerFired() {
        Task {
            do {
                audioRecorder?.stop()

                try await uploadCurrentChunk()

                await MainActor.run {
                    self.currentChunkNumber += 1
                }

                try startNewChunk()
            } catch {
                await MainActor.run {
                    self.error = .uploadFailed(error)
                }
            }
        }
    }

    // MARK: - Timers

    private func startTimers() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.duration += 1
        }

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }

        chunkTimer = Timer.scheduledTimer(
            timeInterval: chunkDuration,
            target: self,
            selector: #selector(chunkTimerFired),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopTimers() {
        durationTimer?.invalidate()
        levelTimer?.invalidate()
        chunkTimer?.invalidate()
        durationTimer = nil
        levelTimer = nil
        chunkTimer = nil
    }

    private func updateAudioLevel() {
        audioRecorder?.updateMeters()
        let level = audioRecorder?.averagePower(forChannel: 0) ?? -160
        let normalizedLevel = max(0, (level + 60) / 60)
        audioLevel = normalizedLevel
    }

    // MARK: - Cleanup

    private func cleanupRecordingFiles() {
        try? FileManager.default.removeItem(at: recordingDirectory)
        try? FileManager.default.createDirectory(
            at: recordingDirectory,
            withIntermediateDirectories: true
        )
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            error = .recordingFailed
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        self.error = .encodingFailed(error)
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case encodingFailed(Error?)
    case uploadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record sessions"
        case .recordingFailed:
            return "Recording failed. Please try again."
        case .encodingFailed(let error):
            return error?.localizedDescription ?? "Audio encoding failed"
        case .uploadFailed(let error):
            return "Failed to upload: \(error.localizedDescription)"
        }
    }
}
