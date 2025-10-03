import SwiftUI

struct FeatureListView: View {
    @ObservedObject var client: SupabaseClient
    let appId: String

    @State private var searchText = ""
    @State private var sortOption: SortOption = .votes

    enum SortOption: String, CaseIterable {
        case votes = "Votes"
        case date = "Datum"

        var displayName: String { rawValue }
    }

    var filteredAndSortedFeatures: [Feature] {
        var features = client.features

        // Filter by search text
        if !searchText.isEmpty {
            features = features.filter { feature in
                feature.title.localizedCaseInsensitiveContains(searchText) ||
                feature.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort
        switch sortOption {
        case .votes:
            features.sort { $0.votesCount > $1.votesCount }
        case .date:
            features.sort { $0.createdAt > $1.createdAt }
        }

        return features
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and Sort Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Features durchsuchen...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            #if os(iOS)
            .background(Color(.systemGray6))
            #else
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .cornerRadius(10)
            .padding()

            // Sort Picker
            Picker("Sortierung", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Divider()
                .padding(.top, 8)

            // Feature List
            if client.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if filteredAndSortedFeatures.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text(searchText.isEmpty ? "Noch keine Features" : "Keine Ergebnisse")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(searchText.isEmpty ? "Sei der Erste und schlage ein Feature vor!" : "Versuche eine andere Suche")
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAndSortedFeatures) { feature in
                            NavigationLink(destination: FeatureDetailView(client: client, feature: feature, appId: appId)) {
                                FeatureRowView(feature: feature, client: client)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await client.fetchFeatures(appId: appId)
        }
        .refreshable {
            await client.fetchFeatures(appId: appId)
        }
    }
}

struct FeatureRowView: View {
    let feature: Feature
    @ObservedObject var client: SupabaseClient

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Vote Button
            VStack(spacing: 4) {
                Button(action: {
                    Task {
                        await client.upvoteFeature(feature)
                    }
                }) {
                    Image(systemName: client.hasVotedForFeature(feature.id) ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.title2)
                        .foregroundColor(client.hasVotedForFeature(feature.id) ? .blue : .gray)
                }
                .disabled(client.hasVotedForFeature(feature.id))

                Text("\(feature.votesCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            .frame(width: 50)

            // Feature Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(feature.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()

                    StatusBadge(status: feature.status)
                }

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Label("\(feature.comments?.count ?? 0)", systemImage: "bubble.left")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Text(relativeDate(from: feature.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatusBadge: View {
    let status: FeatureStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }

    private var backgroundColor: Color {
        switch status {
        case .open: return .gray
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
}
