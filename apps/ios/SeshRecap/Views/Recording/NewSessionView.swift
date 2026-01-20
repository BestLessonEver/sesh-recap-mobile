import SwiftUI

struct NewSessionView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @StateObject private var viewModel: RecordingViewModel

    @ObservedObject var attendantsViewModel: AttendantsViewModel
    @State private var hasStartedRecording = false

    let onSessionCompleted: ((UUID) -> Void)?

    init(sessionsViewModel: SessionsViewModel, attendantsViewModel: AttendantsViewModel, onSessionCompleted: ((UUID) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: RecordingViewModel(sessionsViewModel: sessionsViewModel))
        self.attendantsViewModel = attendantsViewModel
        self.onSessionCompleted = onSessionCompleted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    if viewModel.isRecording || hasStartedRecording {
                        RecordingActiveView(viewModel: viewModel, onSessionCompleted: onSessionCompleted)
                    } else {
                        // Show loading while auto-starting
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Color.brandPink)
                            Text("Starting recording...")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .interactiveDismissDisabled(viewModel.isRecording)
            .task {
                // Auto-start recording immediately when view appears
                if !hasStartedRecording {
                    hasStartedRecording = true
                    await viewModel.startRecording()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                    dismiss()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
}

struct RecordingActiveView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.dismiss) private var dismiss: DismissAction
    let onSessionCompleted: ((UUID) -> Void)?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Audio Level Visualizer
            AudioLevelMeter(level: viewModel.audioLevel)
                .frame(height: 100)

            // Duration
            Text(viewModel.formattedDuration)
                .font(.system(size: 60, weight: .light, design: .monospaced))
                .foregroundStyle(Color.textPrimary)

            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isPaused ? Color.warning : Color.error)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                Text(viewModel.isPaused ? "Paused" : "Recording")
                    .foregroundStyle(Color.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(viewModel.isPaused ? "Recording paused" : "Recording in progress")

            Spacer()

            // Controls
            HStack(spacing: 40) {
                // Cancel
                Button {
                    Task {
                        await viewModel.cancelRecording()
                        dismiss()
                    }
                } label: {
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.textTertiary)
                        Text("Cancel")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(minWidth: 44, minHeight: 60)
                }
                .accessibilityLabel("Cancel recording")
                .accessibilityHint("Discards the current recording")

                // Pause/Resume
                Button {
                    if viewModel.isPaused {
                        viewModel.resumeRecording()
                    } else {
                        viewModel.pauseRecording()
                    }
                } label: {
                    VStack {
                        Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.warning)
                        Text(viewModel.isPaused ? "Resume" : "Pause")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(minWidth: 44, minHeight: 60)
                }
                .accessibilityLabel(viewModel.isPaused ? "Resume recording" : "Pause recording")

                // Stop
                Button {
                    Task {
                        if let sessionId = await viewModel.stopRecording() {
                            dismiss()
                            onSessionCompleted?(sessionId)
                        } else {
                            dismiss()
                        }
                    }
                } label: {
                    VStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.error)
                        Text("Stop")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(minWidth: 44, minHeight: 60)
                }
                .accessibilityLabel("Stop and save recording")
            }

            Spacer()
        }
        .padding()
    }
}

struct AudioLevelMeter: View {
    let level: Float

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(width: (geometry.size.width - 116) / 30)
                        .scaleEffect(y: barScale(for: index), anchor: .center)
                        .animation(.easeOut(duration: 0.1), value: level)
                }
            }
        }
    }

    private func barScale(for index: Int) -> CGFloat {
        let threshold = Float(index) / 30.0
        let scale = max(0.1, min(1.0, CGFloat((level - threshold + 0.3) * 2)))
        return scale
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / 30.0
        if level > threshold {
            if index > 24 {
                return .error
            } else if index > 18 {
                return .brandGold
            } else {
                return .brandPink
            }
        }
        return Color.textTertiary.opacity(0.3)
    }
}

struct AttendantPickerView: View {
    let attendants: [Attendant]
    @Binding var selected: Attendant?
    @Environment(\.dismiss) private var dismiss: DismissAction

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selected = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("No Attendant")
                        Spacer()
                        if selected == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ForEach(attendants) { attendant in
                    Button {
                        selected = attendant
                        dismiss()
                    } label: {
                        HStack {
                            Text(attendant.name)
                            Spacer()
                            if selected?.id == attendant.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Attendant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NewSessionView(
        sessionsViewModel: SessionsViewModel(),
        attendantsViewModel: AttendantsViewModel()
    )
}
