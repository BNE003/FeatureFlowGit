import Foundation

public struct Feature: Identifiable, Codable {
    public let id: UUID
    public let appId: String
    public let title: String
    public let description: String
    public let status: FeatureStatus
    public let createdAt: Date
    public let votesCount: Int
    public var comments: [Comment]?

    enum CodingKeys: String, CodingKey {
        case id
        case appId = "app_id"
        case title
        case description
        case status
        case createdAt = "created_at"
        case votesCount = "votes_count"
        case comments
    }

    public init(id: UUID = UUID(), appId: String, title: String, description: String, status: FeatureStatus = .open, createdAt: Date = Date(), votesCount: Int = 0, comments: [Comment]? = nil) {
        self.id = id
        self.appId = appId
        self.title = title
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.votesCount = votesCount
        self.comments = comments
    }
}

public enum FeatureStatus: String, Codable, CaseIterable {
    case open = "open"
    case planned = "planned"
    case inProgress = "in_progress"
    case completed = "completed"

    public var displayName: String {
        switch self {
        case .open: return "Offen"
        case .planned: return "Geplant"
        case .inProgress: return "In Arbeit"
        case .completed: return "Fertig"
        }
    }

    public var color: String {
        switch self {
        case .open: return "gray"
        case .planned: return "blue"
        case .inProgress: return "orange"
        case .completed: return "green"
        }
    }
}
