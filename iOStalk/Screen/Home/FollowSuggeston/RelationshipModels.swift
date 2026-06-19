import Foundation

enum UserRelationshipStatus: String, Codable {
    case followPending = "follow_pending"
    case follower = "follower"
    case friendPending = "friend_pending"
    case friend = "friend"
    case pending = "pending"
    case accepted = "accepted"
    
    var normalized: UserRelationshipStatus {
        switch self {
        case .pending:
            return .followPending
        case .accepted:
            return .follower
        default:
            return self
        }
    }
}

struct UserRelationshipRecord: Codable {
    let followerID: String
    let followingID: String
    let status: UserRelationshipStatus
    let friendRequestedBy: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case followerID = "follower_id"
        case followingID = "following_id"
        case status
        case friendRequestedBy = "friend_requested_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum RelationshipState: Equatable {
    case none
    case followRequestedSent
    case followRequestedReceived
    case following
    case followedBy
    case friendRequestedSent
    case friendRequestedReceived
    case friend
}

struct RelationshipUpdatePayload: Encodable {
    let status: String
    let friend_requested_by: String?
}

struct RelationshipInsertPayload: Encodable {
    let follower_id: String
    let following_id: String
    let status: String
    let friend_requested_by: String?
}
