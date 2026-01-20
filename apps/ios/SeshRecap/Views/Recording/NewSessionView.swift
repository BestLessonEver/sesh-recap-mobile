import SwiftUI

struct NewSessionView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @StateObject private var viewModel: RecordingViewModel

    @ObservedObject var clientsViewModel: ClientsViewModel
    @State private var hasStartedRecording = false

    let onSessionCompleted: ((UUID) -> Void)?

    init(sessionsViewModel: SessionsViewModel, clientsViewModel: ClientsViewModel, onSessionCompleted: ((UUID) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: RecordingViewModel(sessionsViewModel: sessionsViewModel))
        self.clientsViewModel = clientsViewModel
        self.onSessionCompleted = onSessionCompleted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    if viewModel.isRecording || hasStartedRecording {
                        RecordingActiveView(
                            viewModel: viewModel,
                            clients: clientsViewModel.activeClients,
                            onSessionCompleted: onSessionCompleted
                        )
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
                // Load clients if not already loaded
                await clientsViewModel.loadClients()
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
    let clients: [Client]
    @Environment(\.dismiss) private var dismiss: DismissAction
    let onSessionCompleted: ((UUID) -> Void)?

    @State private var showClientPicker = false
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Client Picker
                Button {
                    showClientPicker = true
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.brandPink)
                        Text(viewModel.selectedClient?.name ?? "Select Client")
                            .foregroundStyle(viewModel.selectedClient == nil ? Color.textSecondary : Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding()
                    .background(Color.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Select client")
                .accessibilityValue(viewModel.selectedClient?.name ?? "No client selected")

                // Audio Level Visualizer
                AudioLevelMeter(level: viewModel.audioLevel)
                    .frame(height: 80)

                // Duration
                Text(viewModel.formattedDuration)
                    .font(.system(size: 56, weight: .light, design: .monospaced))
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

                // Notes Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Notes")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    TextEditor(text: $viewModel.sessionNotes)
                        .focused($isNotesFocused)
                        .frame(minHeight: 100, maxHeight: 150)
                        .padding(12)
                        .background(Color.bgSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Group {
                                if viewModel.sessionNotes.isEmpty && !isNotesFocused {
                                    Text("Add notes to include in the recap email...")
                                        .foregroundStyle(Color.textTertiary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                Spacer(minLength: 20)

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

                Spacer(minLength: 20)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showClientPicker) {
            ClientPickerView(clients: clients, selected: $viewModel.selectedClient)
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

struct ClientPickerView: View {
    let clients: [Client]
    @Binding var selected: Client?
    @Environment(\.dismiss) private var dismiss: DismissAction

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selected = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("No Client")
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        if selected == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.brandPink)
                        }
                    }
                }

                ForEach(clients) { client in
                    Button {
                        selected = client
                        dismiss()
                    } label: {
                        HStack {
                            GradientAvatar(name: client.name, size: 32)
                            Text(client.name)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            if selected?.id == client.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.brandPink)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Client")
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
        clientsViewModel: ClientsViewModel()
    )
}
