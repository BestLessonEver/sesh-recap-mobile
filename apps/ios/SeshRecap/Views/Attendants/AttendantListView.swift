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
            ZStack {
                Color.bgPrimary
                    .ignoresSafeArea()

                if viewModel.attendants.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.textTertiary)
                        Text("No Attendants")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.textPrimary)
                        Text("Add your first attendant to get started")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)

                        Button {
                            showAddAttendant = true
                        } label: {
                            Text("Add Attendant")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(LinearGradient.brandGradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, 8)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAttendants) { attendant in
                                NavigationLink {
                                    AttendantDetailView(attendant: attendant, viewModel: viewModel)
                                } label: {
                                    BrandAttendantRow(attendant: attendant)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Attendants")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAttendant = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.brandPink)
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
}

struct BrandAttendantRow: View {
    let attendant: Attendant

    var body: some View {
        BrandCard(padding: 16) {
            HStack(spacing: 12) {
                // Avatar
                GradientAvatar(name: attendant.name, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(attendant.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)

                    if let email = attendant.displayEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                if let tags = attendant.tags, !tags.isEmpty {
                    Text(tags.first!)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.brandPink.opacity(0.15))
                        .foregroundStyle(Color.brandPink)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}

#Preview {
    AttendantListView(viewModel: AttendantsViewModel())
}
