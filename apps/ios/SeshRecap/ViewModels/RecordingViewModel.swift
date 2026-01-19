import Foundation
import AVFoundation

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var error: Error?
    @Published var isProcessing = false

    @Published var selectedAttendant: Attendant?
    @Published var sessionTitle: String = ""

    private var currentSessionId: UUID?
    private let recordingService = RecordingService.shared
    private let sessionsViewModel: SessionsViewModel

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

        isProcessing = true
        error = nil

        do {
            // Create session in database
            let session = try await sessionsViewModel.createSession(
                attendantId: selectedAttendant?.id,
                title: sessionTitle.isEmpty ? nil : sessionTitle
            )
            currentSessionId = session.id

            // Start recording
            try await recordingService.startRecording(sessionId: session.id)

            isRecording = true
            isPaused = false
            isProcessing = false

            // Observe recording state
            observeRecordingState()
        } catch {
            self.error = error
            isProcessing = false
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

    func stopRecording() async {
        guard isRecording, let sessionId = currentSessionId else { return }

        isProcessing = true

        do {
            let chunks = try await recordingService.stopRecording()

            // Update session with audio info
            try await sessionsViewModel.updateSession(sessionId, request: UpdateSessionRequest(
                audioChunks: chunks,
                durationSeconds: Int(duration),
                sessionStatus: .uploading
            ))

            // Trigger transcription
            try await sessionsViewModel.transcribeSession(sessionId)

            isRecording = false
            isPaused = false
            duration = 0
            audioLevel = 0
            currentSessionId = nil
            selectedAttendant = nil
            sessionTitle = ""
        } catch {
            self.error = error
        }

        isProcessing = false
    }

    func cancelRecording() async {
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
        Task {
            for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                guard isRecording else { break }
                duration = recordingService.duration
                audioLevel = recordingService.audioLevel
            }
        }
    }

    // MARK: - Computed Properties

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var canStartRecording: Bool {
        !isRecording && !isProcessing
    }
}
