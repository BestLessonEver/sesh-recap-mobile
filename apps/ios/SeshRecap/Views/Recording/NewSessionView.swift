import SwiftUI

struct NewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RecordingViewModel

    @ObservedObject var attendantsViewModel: AttendantsViewModel

    init(sessionsViewModel: SessionsViewModel, attendantsViewModel: AttendantsViewModel) {
        _viewModel = StateObject(wrappedValue: RecordingViewModel(sessionsViewModel: sessionsViewModel))
        self.attendantsViewModel = attendantsViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if viewModel.isRecording {
                    RecordingActiveView(viewModel: viewModel)
                } else {
                    RecordingSetupView(viewModel: viewModel, attendantsViewModel: attendantsViewModel)
                }
            }
            .navigationTitle(viewModel.isRecording ? "Recording" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.isRecording {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.isRecording)
            .onChange(of: viewModel.isRecording) { _, isRecording in
                if !isRecording && viewModel.isProcessing == false {
                    // Recording stopped successfully, dismiss
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
}

struct RecordingSetupView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @ObservedObject var attendantsViewModel: AttendantsViewModel
    @State private var showAttendantPicker = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Session Info
            VStack(spacing: 16) {
                TextField("Session Title (optional)", text: $viewModel.sessionTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button {
                    showAttendantPicker = true
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                        Text(viewModel.selectedAttendant?.name ?? "Select Attendant")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }

            Spacer()

            // Start Button
            Button {
                Task {
                    await viewModel.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 100, height: 100)
                        .shadow(color: .red.opacity(0.4), radius: 10, y: 5)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }
            .disabled(!viewModel.canStartRecording)

            Text("Tap to start recording")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .sheet(isPresented: $showAttendantPicker) {
            AttendantPickerView(
                attendants: attendantsViewModel.activeAttendants,
                selected: $viewModel.selectedAttendant
            )
        }
        .task {
            await attendantsViewModel.loadAttendants()
        }
    }
}

struct RecordingActiveView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Audio Level Visualizer
            AudioLevelMeter(level: viewModel.audioLevel)
                .frame(height: 100)

            // Duration
            Text(viewModel.formattedDuration)
                .font(.system(size: 60, weight: .light, design: .monospaced))

            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isPaused ? .orange : .red)
                    .frame(width: 12, height: 12)
                Text(viewModel.isPaused ? "Paused" : "Recording")
                    .foregroundStyle(.secondary)
            }

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
                            .foregroundStyle(.gray)
                        Text("Cancel")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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
                            .foregroundStyle(.orange)
                        Text(viewModel.isPaused ? "Resume" : "Pause")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Stop
                Button {
                    Task {
                        await viewModel.stopRecording()
                        dismiss()
                    }
                } label: {
                    VStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                        Text("Stop")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(viewModel.isProcessing)
            }

            Spacer()
        }
        .padding()
        .overlay {
            if viewModel.isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                    Text("Processing...")
                        .foregroundStyle(.white)
                }
            }
        }
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
                return .red
            } else if index > 18 {
                return .orange
            } else {
                return .green
            }
        }
        return .gray.opacity(0.3)
    }
}

struct AttendantPickerView: View {
    let attendants: [Attendant]
    @Binding var selected: Attendant?
    @Environment(\.dismiss) private var dismiss

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
