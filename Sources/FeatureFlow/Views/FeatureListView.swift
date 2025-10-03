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
        HStack(alignment: .top, spacing: 16) {
            // Feature Content
            VStack(alignment: .leading, spacing: 10) {
                // Title
                Text(feature.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Status Badge
                StatusBadge(status: feature.status)

                // Description (optional, can be hidden for cleaner look)
                if !feature.description.isEmpty {
                    Text(feature.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Vote Button - Prominent rounded style
            VStack(spacing: 6) {
                Button(action: {
                    Task {
                        await client.upvoteFeature(feature)
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
                .disabled(client.hasVotedForFeature(feature.id))

                Text("\(feature.votesCount)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.5, blue: 0.95),
                        Color(red: 0.3, green: 0.6, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .opacity(client.hasVotedForFeature(feature.id) ? 0.6 : 1.0)
        }
        .padding(20)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
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
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(backgroundColor.opacity(0.15))
            .foregroundColor(backgroundColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
        case .open: return Color.gray
        case .planned: return Color.blue
        case .inProgress: return Color.orange
        case .completed: return Color.green
        }
    }
}
