import Foundation

public class SupabaseClient: ObservableObject {
    // TODO: Replace with actual Supabase credentials
    private let supabaseURL = "https://ssaaaryvzpmfefvnfpxf.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzYWFhcnl2enBtZmVmdm5mcHhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODc3NjksImV4cCI6MjA3NTA2Mzc2OX0.FTmAcAW9Eu4knfVab6KcV89YPNt__2FFWdYEsvIvAlQ"

    private let useMockData = false // TEMPORARY: Set to false when Supabase works

    @Published public var features: [Feature] = []
    @Published public var isLoading = false
    @Published public var error: String?

    private let deviceId: String

    public init() {
        // TEMPORARY: Reset votes for testing
        UserDefaults.standard.removeObject(forKey: "FeatureFlowVotedFeatures")

        // Generate a persistent device identifier for voting
        if let savedId = UserDefaults.standard.string(forKey: "FeatureFlowDeviceId") {
            self.deviceId = savedId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "FeatureFlowDeviceId")
            self.deviceId = newId
        }
    }

    // MARK: - Features

    public func fetchFeatures(appId: String) async {
        print("🚀 fetchFeatures called with appId: \(appId)")
        print("🎯 useMockData: \(useMockData)")

        if useMockData {
            await fetchMockFeatures(appId: appId)
            return
        }

        await MainActor.run { isLoading = true }
        print("⏳ Loading started...")

        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/features?app_id=eq.\(appId)&select=*")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 30 // 30 Sekunden Timeout
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            print("🔍 Fetching features from: \(url.absoluteString)")
            print("🔑 Using API Key: \(String(supabaseAnonKey.prefix(20)))...")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status: \(httpResponse.statusCode)")
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            print("📦 Response data: \(responseString)")

            let decoder = JSONDecoder()

            // Custom date decoder für Supabase Format
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Versuche verschiedene Formate
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Fallback: ISO8601
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Fallback 2: Standard ISO8601 ohne Mikrosekunden
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                if let date = formatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }

            let fetchedFeatures = try decoder.decode([Feature].self, from: data)

            print("✅ Decoded \(fetchedFeatures.count) features")

            await MainActor.run {
                self.features = fetchedFeatures.sorted { $0.votesCount > $1.votesCount }
                self.isLoading = false
            }
        } catch {
            print("❌ Error fetching features: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func fetchMockFeatures(appId: String) async {
        await MainActor.run { isLoading = true }

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        let mockFeatures = [
            Feature(
                id: UUID(),
                appId: appId,
                title: "Dark Mode",
                description: "Bitte fügt einen Dark Mode hinzu, damit die App abends besser nutzbar ist.",
                status: .planned,
                createdAt: Date().addingTimeInterval(-86400 * 5),
                votesCount: 42,
                comments: [
                    Comment(id: UUID(), featureId: UUID(), authorName: "Anna", text: "Super Idee! Brauche ich auch.", createdAt: Date().addingTimeInterval(-86400 * 3))
                ]
            ),
            Feature(
                id: UUID(),
                appId: appId,
                title: "Export als PDF",
                description: "Es wäre toll, wenn man die Daten als PDF exportieren könnte.",
                status: .open,
                createdAt: Date().addingTimeInterval(-86400 * 3),
                votesCount: 28,
                comments: []
            ),
            Feature(
                id: UUID(),
                appId: appId,
                title: "Push-Benachrichtigungen",
                description: "Ich hätte gerne Push-Benachrichtigungen für neue Updates.",
                status: .inProgress,
                createdAt: Date().addingTimeInterval(-86400 * 7),
                votesCount: 35,
                comments: [
                    Comment(id: UUID(), featureId: UUID(), authorName: "Max", text: "Ja bitte!", createdAt: Date().addingTimeInterval(-86400 * 6)),
                    Comment(id: UUID(), featureId: UUID(), authorName: "Lisa", text: "Mit Einstellungen bitte, um sie auch ausschalten zu können.", createdAt: Date().addingTimeInterval(-86400 * 5))
                ]
            ),
            Feature(
                id: UUID(),
                appId: appId,
                title: "Widget Support",
                description: "Ein Home-Screen Widget wäre super praktisch.",
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 14),
                votesCount: 56,
                comments: []
            ),
            Feature(
                id: UUID(),
                appId: appId,
                title: "Offline-Modus",
                description: "Die App sollte auch offline funktionieren und später synchronisieren.",
                status: .open,
                createdAt: Date().addingTimeInterval(-86400 * 2),
                votesCount: 19,
                comments: []
            )
        ]

        await MainActor.run {
            self.features = mockFeatures
            self.isLoading = false
        }
    }

    // MARK: - Submit Feature

    public func submitFeature(appId: String, title: String, description: String) async -> Bool {
        if useMockData {
            return await submitMockFeature(appId: appId, title: title, description: description)
        }

        await MainActor.run { isLoading = true }

        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/features")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            let newFeature: [String: Any] = [
                "app_id": appId,
                "title": title,
                "description": description,
                "status": "open",
                "votes_count": 0
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: newFeature)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                await fetchFeatures(appId: appId)
                await MainActor.run { isLoading = false }
                return true
            }

            await MainActor.run { isLoading = false }
            return false
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }

    private func submitMockFeature(appId: String, title: String, description: String) async -> Bool {
        await MainActor.run { isLoading = true }

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 800_000_000)

        let newFeature = Feature(
            appId: appId,
            title: title,
            description: description,
            status: .open,
            votesCount: 0
        )

        await MainActor.run {
            self.features.insert(newFeature, at: 0)
            self.isLoading = false
        }

        return true
    }

    // MARK: - Voting

    public func upvoteFeature(_ feature: Feature) async {
        if useMockData {
            await upvoteMockFeature(feature)
            return
        }

        // Check if already voted
        if hasVoted(for: feature.id) {
            print("⚠️ Already voted for feature: \(feature.title)")
            return
        }

        print("👍 Upvoting feature: \(feature.title) (current votes: \(feature.votesCount))")

        do {
            // SCHRITT 1: Speichere Vote in DB
            let voteURL = URL(string: "\(supabaseURL)/rest/v1/votes")!
            var voteRequest = URLRequest(url: voteURL)
            voteRequest.httpMethod = "POST"
            voteRequest.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            voteRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            voteRequest.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            let vote: [String: Any] = [
                "feature_id": feature.id.uuidString,
                "user_identifier": deviceId
            ]

            voteRequest.httpBody = try JSONSerialization.data(withJSONObject: vote)

            print("📤 Step 1: Creating vote in database...")

            let (voteData, voteResponse) = try await URLSession.shared.data(for: voteRequest)

            guard let httpResponse = voteResponse as? HTTPURLResponse else {
                print("❌ No HTTP response")
                return
            }

            print("📡 Vote response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 201 {
                let responseString = String(data: voteData, encoding: .utf8) ?? "No response"
                print("❌ Vote creation failed: \(responseString)")
                return
            }

            print("✅ Vote created successfully")

            // SCHRITT 2: Erhöhe vote_count direkt
            let newVoteCount = feature.votesCount + 1
            print("📤 Step 2: Updating vote_count to \(newVoteCount)...")

            let updateURL = URL(string: "\(supabaseURL)/rest/v1/features?id=eq.\(feature.id.uuidString)")!
            var updateRequest = URLRequest(url: updateURL)
            updateRequest.httpMethod = "PATCH"
            updateRequest.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            updateRequest.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            let updateBody: [String: Any] = [
                "votes_count": newVoteCount
            ]

            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: updateBody)

            let (updateData, updateResponse) = try await URLSession.shared.data(for: updateRequest)

            if let updateHttpResponse = updateResponse as? HTTPURLResponse {
                print("📡 Update response status: \(updateHttpResponse.statusCode)")

                if updateHttpResponse.statusCode == 204 || updateHttpResponse.statusCode == 200 {
                    print("✅ Vote count updated to \(newVoteCount)")

                    // SCHRITT 3: Speichere lokal und aktualisiere UI
                    saveVote(for: feature.id)

                    print("🔄 Refreshing features...")
                    await fetchFeatures(appId: feature.appId)
                } else {
                    let responseString = String(data: updateData, encoding: .utf8) ?? "No response"
                    print("❌ Update failed with status \(updateHttpResponse.statusCode): \(responseString)")
                }
            }

        } catch {
            print("❌ Error upvoting: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    private func upvoteMockFeature(_ feature: Feature) async {
        if hasVoted(for: feature.id) {
            return
        }

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000)

        await MainActor.run {
            if let index = self.features.firstIndex(where: { $0.id == feature.id }) {
                var updatedFeature = self.features[index]
                updatedFeature = Feature(
                    id: updatedFeature.id,
                    appId: updatedFeature.appId,
                    title: updatedFeature.title,
                    description: updatedFeature.description,
                    status: updatedFeature.status,
                    createdAt: updatedFeature.createdAt,
                    votesCount: updatedFeature.votesCount + 1,
                    comments: updatedFeature.comments
                )
                self.features[index] = updatedFeature
                self.features.sort { $0.votesCount > $1.votesCount }
            }
        }

        saveVote(for: feature.id)
    }

    // MARK: - Comments

    public func addComment(to feature: Feature, authorName: String, text: String) async -> Bool {
        if useMockData {
            return await addMockComment(to: feature, authorName: authorName, text: text)
        }

        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/comments")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let comment: [String: Any] = [
                "feature_id": feature.id.uuidString,
                "author_name": authorName,
                "text": text
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: comment)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                await fetchFeatures(appId: feature.appId)
                return true
            }

            return false
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
            return false
        }
    }

    private func addMockComment(to feature: Feature, authorName: String, text: String) async -> Bool {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        let newComment = Comment(
            featureId: feature.id,
            authorName: authorName,
            text: text
        )

        await MainActor.run {
            if let index = self.features.firstIndex(where: { $0.id == feature.id }) {
                var updatedFeature = self.features[index]
                var comments = updatedFeature.comments ?? []
                comments.append(newComment)

                updatedFeature = Feature(
                    id: updatedFeature.id,
                    appId: updatedFeature.appId,
                    title: updatedFeature.title,
                    description: updatedFeature.description,
                    status: updatedFeature.status,
                    createdAt: updatedFeature.createdAt,
                    votesCount: updatedFeature.votesCount,
                    comments: comments
                )
                self.features[index] = updatedFeature
            }
        }

        return true
    }

    // MARK: - Vote Tracking

    private func hasVoted(for featureId: UUID) -> Bool {
        let votedFeatures = UserDefaults.standard.stringArray(forKey: "FeatureFlowVotedFeatures") ?? []
        return votedFeatures.contains(featureId.uuidString)
    }

    private func saveVote(for featureId: UUID) {
        var votedFeatures = UserDefaults.standard.stringArray(forKey: "FeatureFlowVotedFeatures") ?? []
        votedFeatures.append(featureId.uuidString)
        UserDefaults.standard.set(votedFeatures, forKey: "FeatureFlowVotedFeatures")
    }

    public func hasVotedForFeature(_ featureId: UUID) -> Bool {
        return hasVoted(for: featureId)
    }
}
