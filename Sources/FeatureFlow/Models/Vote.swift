import Foundation

public struct Vote: Identifiable, Codable {
    public let id: UUID
    public let featureId: UUID
    public let userIdentifier: String
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case featureId = "feature_id"
        case userIdentifier = "user_identifier"
        case createdAt = "created_at"
    }

    public init(id: UUID = UUID(), featureId: UUID, userIdentifier: String, createdAt: Date = Date()) {
        self.id = id
        self.featureId = featureId
        self.userIdentifier = userIdentifier
        self.createdAt = createdAt
    }
}
