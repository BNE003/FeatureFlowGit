import Foundation

public struct Comment: Identifiable, Codable {
    public let id: UUID
    public let featureId: UUID
    public let authorName: String
    public let text: String
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case featureId = "feature_id"
        case authorName = "author_name"
        case text
        case createdAt = "created_at"
    }

    public init(id: UUID = UUID(), featureId: UUID, authorName: String, text: String, createdAt: Date = Date()) {
        self.id = id
        self.featureId = featureId
        self.authorName = authorName
        self.text = text
        self.createdAt = createdAt
    }
}
