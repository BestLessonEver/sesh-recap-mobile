import SwiftUI

struct ClientListView: View {
    @ObservedObject var viewModel: ClientsViewModel
    @State private var searchText = ""
    @State private var showAddClient = false
    @State private var showArchived = false

    var filteredClients: [Client] {
        let source = showArchived ? viewModel.archivedClients : viewModel.activeClients
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

                if viewModel.clients.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.textTertiary)
                            .accessibilityHidden(true)
                        Text("No Clients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.textPrimary)
                        Text("Add your first client to get started")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)

                        Button {
                            showAddClient = true
                        } label: {
                            Text("Add Client")
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
                            ForEach(filteredClients) { client in
                                NavigationLink {
                                    ClientDetailView(client: client, viewModel: viewModel)
                                } label: {
                                    BrandClientRow(client: client)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Clients")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search clients")
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
                    .accessibilityLabel("Filter clients")
                    .accessibilityHint("Shows \(showArchived ? "archived" : "active") clients")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddClient = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.brandPink)
                    }
                    .accessibilityLabel("Add client")
                }
            }
            .refreshable {
                await viewModel.loadClients(forceRefresh: true)
            }
            .sheet(isPresented: $showAddClient) {
                AddClientView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadClients()
            }
        }
    }
}

struct BrandClientRow: View {
    let client: Client

    var body: some View {
        BrandCard(padding: 16) {
            HStack(spacing: 12) {
                // Avatar
                GradientAvatar(name: client.name, size: 48)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)

                    if let email = client.displayEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                if let tags = client.tags, !tags.isEmpty {
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
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var description = client.name
        if let email = client.displayEmail {
            description += ", \(email)"
        }
        if let tags = client.tags, let firstTag = tags.first {
            description += ", tagged as \(firstTag)"
        }
        return description
    }
}

#Preview {
    ClientListView(viewModel: ClientsViewModel())
}
