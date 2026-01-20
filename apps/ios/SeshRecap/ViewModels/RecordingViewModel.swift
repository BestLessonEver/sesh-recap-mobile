import Foundation
import AVFoundation
import Combine

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var error: Error?

    @Published var selectedClient: Client?
    @Published var sessionTitle: String = ""

    private var currentSessionId: UUID?
    private let recordingService = RecordingService.shared
    private let sessionsViewModel: SessionsViewModel
    private var observationTask: Task<Void, Never>?

    init(sessionsViewModel: SessionsViewModel) {
        self.sessionsViewModel = sessionsViewModel
    }

    // MARK: - Microphone Permission

    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func checkMicrophonePermission() -> Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return AVAudioSession.sharedInstance().recordPermission == .granted
        }
    }

    // MARK: - Recording Control

    func startRecording() async {
        print("🎙️ START RECORDING TAPPED")
        guard !isRecording else { return }

        // Pre-warm audio session FIRST (await it!)
        await recordingService.prepareAudioSession()

        if !checkMicrophonePermission() {
            let granted = await requestMicrophonePermission()
            if !granted {
                error = RecordingError.permissionDenied
                return
            }
        }

        error = nil

        do {
            // Create session in database
            let session = try await sessionsViewModel.createSession(
                clientId: selectedClient?.id,
                title: sessionTitle.isEmpty ? nil : sessionTitle
            )
            currentSessionId = session.id

            // Start recording
            try await recordingService.startRecording(sessionId: session.id)

            isRecording = true
            isPaused = false

            // Observe recording state
            observeRecordingState()
        } catch {
            self.error = error
        }
    }

    func pauseRecording() {
        recordingService.pauseRecording()
        isPaused = true
    }

    func resumeRecording() {
        recordingService.resumeRecording()
        isPaused = false
    }

    /// Stops recording and returns the session ID immediately.
    /// Transcription is triggered in the background - check session status for updates.
    func stopRecording() async -> UUID? {
        guard isRecording, let sessionId = currentSessionId else { return nil }

        stopObservingRecordingState()
        let recordedDuration = duration

        do {
            let chunks = try await recordingService.stopRecording()

            // Update session with audio info and set status to uploading
            try await sessionsViewModel.updateSession(sessionId, request: UpdateSessionRequest(
                audioChunks: chunks,
                durationSeconds: Int(recordedDuration),
                sessionStatus: .uploading
            ))

            // Trigger transcription in background (fire and forget)
            Task {
                do {
                    try await sessionsViewModel.transcribeSession(sessionId)
                } catch {
                    print("Background transcription error: \(error)")
                }
            }

            // Reset state
            isRecording = false
            isPaused = false
            duration = 0
            audioLevel = 0
            currentSessionId = nil
            selectedClient = nil
            sessionTitle = ""

            return sessionId
        } catch {
            print("Stop recording error: \(error)")
            self.error = error
            return nil
        }
    }

    func cancelRecording() async {
        stopObservingRecordingState()
        recordingService.cancelRecording()

        if let sessionId = currentSessionId {
            try? await sessionsViewModel.deleteSession(sessionId)
        }

        isRecording = false
        isPaused = false
        duration = 0
        audioLevel = 0
        currentSessionId = nil
    }

    // MARK: - State Observation

    private func observeRecordingState() {
        print("🔵 Starting observation task")
        stopObservingRecordingState()

        // Use a Task-based polling loop that respects @MainActor isolation
        observationTask = Task { @MainActor [weak self] in
            print("🔵 Task loop starting, isRecording: \(self?.isRecording ?? false)")
            var loopCount = 0
            while !Task.isCancelled {
                guard let self = self else {
                    print("🔵 Task: self is nil, breaking")
                    break
                }
                guard self.isRecording else {
                    print("🔵 Task: isRecording is false, breaking")
                    break
                }

                let newLevel = self.recordingService.audioLevel
                self.audioLevel = newLevel
                self.duration = self.recordingService.duration

                loopCount += 1
                if loopCount % 20 == 0 {
                    print("🔄 Loop \(loopCount): level=\(newLevel)")
                }

                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }
            print("🔵 Observation task ended after \(loopCount) iterations")
        }

        // Fire immediately to get initial values
        audioLevel = recordingService.audioLevel
        duration = recordingService.duration
        print("🔵 Task started, initial audioLevel: \(audioLevel)")
    }

    private func stopObservingRecordingState() {
        observationTask?.cancel()
        observationTask = nil
    }

    // MARK: - Computed Properties

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var canStartRecording: Bool {
        !isRecording
    }
}
