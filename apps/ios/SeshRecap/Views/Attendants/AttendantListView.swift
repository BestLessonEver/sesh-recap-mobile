import SwiftUI

struct AttendantListView: View {
    @ObservedObject var viewModel: AttendantsViewModel
    @State private var searchText = ""
    @State private var showAddAttendant = false
    @State private var showArchived = false

    var filteredAttendants: [Attendant] {
        let source = showArchived ? viewModel.archivedAttendants : viewModel.activeAttendants
        if searchText.isEmpty {
            return source
        }
        return source.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.attendants.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Attendants",
                        systemImage: "person.2",
                        description: Text("Add your first attendant to get started")
                    )
                } else {
                    List {
                        ForEach(filteredAttendants) { attendant in
                            NavigationLink {
                                AttendantDetailView(attendant: attendant, viewModel: viewModel)
                            } label: {
                                AttendantRow(attendant: attendant)
                            }
                        }
                        .onDelete(perform: archiveAttendants)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Attendants")
            .searchable(text: $searchText, prompt: "Search attendants")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showArchived = false
                        } label: {
                            Label("Active", systemImage: showArchived ? "" : "checkmark")
                        }
                        Button {
                            showArchived = true
                        } label: {
                            Label("Archived", systemImage: showArchived ? "checkmark" : "")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAttendant = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadAttendants(forceRefresh: true)
            }
            .sheet(isPresented: $showAddAttendant) {
                AddAttendantView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadAttendants()
            }
        }
    }

    private func archiveAttendants(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let attendant = filteredAttendants[index]
                try? await viewModel.archiveAttendant(attendant.id)
            }
        }
    }
}

struct AttendantRow: View {
    let attendant: Attendant

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(attendant.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(attendant.name)
                    .font(.body)

                if let email = attendant.displayEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let tags = attendant.tags, !tags.isEmpty {
                Text(tags.first!)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AttendantListView(viewModel: AttendantsViewModel())
}
