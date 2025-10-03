import SwiftUI

struct FeatureDetailView: View {
    @ObservedObject var client: SupabaseClient
    let feature: Feature
    let appId: String

    @State private var newCommentAuthor = ""
    @State private var newCommentText = ""
    @State private var isAddingComment = false
    @State private var showCommentForm = false

    var currentFeature: Feature {
        client.features.first(where: { $0.id == feature.id }) ?? feature
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with Vote Button
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 8) {
                        Button(action: {
                            Task {
                                await client.upvoteFeature(currentFeature)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: client.hasVotedForFeature(currentFeature.id) ? "arrow.up.circle.fill" : "arrow.up.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(client.hasVotedForFeature(currentFeature.id) ? .blue : .gray)

                                Text("\(currentFeature.votesCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text("Votes")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .disabled(client.hasVotedForFeature(currentFeature.id))
                    }
                    .frame(width: 80)
                    .padding()
                    #if os(iOS)
                    .background(Color(.systemGray6))
                    #else
                    .background(Color(NSColor.controlBackgroundColor))
                    #endif
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 12) {
                        StatusBadge(status: currentFeature.status)

                        Text(currentFeature.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(relativeDate(from: currentFeature.createdAt))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreibung")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(currentFeature.description)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.top)

                // Comments Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Kommentare (\(currentFeature.comments?.count ?? 0))")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { showCommentForm.toggle() }) {
                            Label("Kommentar", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)

                    // Comment Form
                    if showCommentForm {
                        VStack(spacing: 12) {
                            TextField("Dein Name", text: $newCommentAuthor)
                                .textFieldStyle(.roundedBorder)

                            TextEditor(text: $newCommentText)
                                .frame(height: 100)
                                .padding(4)
                                #if os(iOS)
                                .background(Color(.systemGray6))
                                #else
                                .background(Color(NSColor.controlBackgroundColor))
                                #endif
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        #if os(iOS)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                        #else
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                        #endif
                                )

                            HStack {
                                Button("Abbrechen") {
                                    showCommentForm = false
                                    newCommentAuthor = ""
                                    newCommentText = ""
                                }
                                .foregroundColor(.secondary)

                                Spacer()

                                Button(action: addComment) {
                                    if isAddingComment {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Text("Kommentieren")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .disabled(!isCommentFormValid || isAddingComment)
                            }
                        }
                        .padding()
                        #if os(iOS)
                        .background(Color(.systemGray6))
                        #else
                        .background(Color(NSColor.controlBackgroundColor))
                        #endif
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Comments List
                    if let comments = currentFeature.comments, !comments.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(comments.sorted(by: { $0.createdAt > $1.createdAt })) { comment in
                                CommentView(comment: comment)
                            }
                        }
                        .padding(.horizontal)
                    } else if !showCommentForm {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left")
                                .font(.largeTitle)
                                .foregroundColor(.gray)

                            Text("Noch keine Kommentare")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Sei der Erste und kommentiere!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
                .padding(.bottom)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var isCommentFormValid: Bool {
        !newCommentAuthor.trimmingCharacters(in: .whitespaces).isEmpty &&
        !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addComment() {
        isAddingComment = true

        Task {
            let success = await client.addComment(
                to: currentFeature,
                authorName: newCommentAuthor.trimmingCharacters(in: .whitespaces),
                text: newCommentText.trimmingCharacters(in: .whitespaces)
            )

            await MainActor.run {
                isAddingComment = false

                if success {
                    newCommentAuthor = ""
                    newCommentText = ""
                    showCommentForm = false
                }
            }
        }
    }

    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "de_DE")
        return "Eingereicht " + formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CommentView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.authorName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(relativeDate(from: comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(comment.text)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemGray6))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }

    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
