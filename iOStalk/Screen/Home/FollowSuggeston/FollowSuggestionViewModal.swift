//
//  FollowSuggestionViewModal.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 19/01/26.
//

import Foundation

@MainActor
final class FollowSuggestionViewModal: ObservableObject {
    
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var users: [UserModal] = []
    @Published var incomingFollowRequests: [UserModal] = []
    @Published var incomingFriendRequests: [UserModal] = []
    
    private var relationshipStates: [String: RelationshipState] = [:]
    private let authManager: SupabaseManager
    
    init(authManager: SupabaseManager = .shared) {
        self.authManager = authManager
    }
    
    // MARK: - Public
    func loadData() {
        Task {
            await refreshData()
        }
    }
    
    func relationshipState(for user: UserModal) -> RelationshipState {
        guard let userID = user.id, !userID.isEmpty else {
            return .none
        }
        return relationshipStates[userID] ?? .none
    }
    
    func sendFollowRequest(to user: UserModal) {
        performRelationshipAction {
            try await self.authManager.sendFollowRequest(to: user)
        }
    }
    
    func unfollow(user: UserModal) {
        guard let userID = user.id, !userID.isEmpty else { return }
        performRelationshipAction {
            try await self.authManager.unfollow(userID: userID)
        }
    }
    
    func sendFriendRequest(to user: UserModal) {
        guard let userID = user.id, !userID.isEmpty else { return }
        performRelationshipAction {
            try await self.authManager.sendFriendRequest(userID: userID)
        }
    }
    
    func unfriend(user: UserModal) {
        guard let userID = user.id, !userID.isEmpty else { return }
        performRelationshipAction {
            try await self.authManager.unfriend(userID: userID)
        }
    }
    
    func acceptFollowRequest(from user: UserModal) {
        guard let userID = user.id, !userID.isEmpty else { return }
        performRelationshipAction {
            try await self.authManager.respondToFollowRequest(from: userID, accept: true)
        }
    }
    
    func rejectFollowRequest(from user: UserModal) {
        guard let userID = user.id, !userID.isEmpty else { return }
        performRelationshipAction {
            try await self.authManager.respondToFollowRequest(from: userID, accept: false)
        }
    }
    
    func acceptFriendRequest(from user: UserModal) {
        guard let userID = user.id, !userID.isEmpty else { return }
        performRelationshipAction {
            try await self.authManager.respondToFriendRequest(from: userID, accept: true)
        }
    }
    
    func rejectFriendRequest(from user: UserModal) {
        guard let userID = user.id, !userID.isEmpty else { return }
        performRelationshipAction {
            try await self.authManager.respondToFriendRequest(from: userID, accept: false)
        }
    }
    
    // MARK: - Internal
    private func refreshData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            async let usersRequest = authManager.fetchUsers()
            async let relationshipsRequest = authManager.fetchRelationshipRecords()
            async let currentUserRequest = authManager.currentUserId()
            
            let fetchedUsers = try await usersRequest
            let relationshipRecords = try await relationshipsRequest
            let currentUserID = await currentUserRequest
            
            users = fetchedUsers
            
            guard let currentUserID, !currentUserID.isEmpty else {
                relationshipStates = [:]
                incomingFollowRequests = []
                incomingFriendRequests = []
                return
            }
            
            relationshipStates = buildRelationshipStateMap(
                users: fetchedUsers,
                records: relationshipRecords,
                currentUserID: currentUserID
            )
            
            let userByID = Dictionary(uniqueKeysWithValues: fetchedUsers.compactMap { user -> (String, UserModal)? in
                guard let userID = user.id, !userID.isEmpty else { return nil }
                return (userID, user)
            })
            
            incomingFollowRequests = buildIncomingFollowRequests(
                records: relationshipRecords,
                currentUserID: currentUserID,
                usersByID: userByID
            )
            
            incomingFriendRequests = buildIncomingFriendRequests(
                records: relationshipRecords,
                currentUserID: currentUserID,
                usersByID: userByID
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func performRelationshipAction(_ action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
                await refreshData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func buildRelationshipStateMap(
        users: [UserModal],
        records: [UserRelationshipRecord],
        currentUserID: String
    ) -> [String: RelationshipState] {
        var states: [String: RelationshipState] = [:]
        
        for user in users {
            guard let userID = user.id, !userID.isEmpty else { continue }
            
            let state = authManager.relationshipState(
                with: userID,
                records: records,
                currentUserID: currentUserID
            )
            
            states[userID] = state
        }
        
        return states
    }
    
    private func buildIncomingFollowRequests(
        records: [UserRelationshipRecord],
        currentUserID: String,
        usersByID: [String: UserModal]
    ) -> [UserModal] {
        let incomingRequestIDs = records.compactMap { record -> String? in
            guard record.followingID == currentUserID else { return nil }
            guard record.status.normalized == .followPending else { return nil }
            return record.followerID
        }
        
        return incomingRequestIDs.compactMap { usersByID[$0] }
    }
    
    private func buildIncomingFriendRequests(
        records: [UserRelationshipRecord],
        currentUserID: String,
        usersByID: [String: UserModal]
    ) -> [UserModal] {
        let incomingRequestIDs = records.compactMap { record -> String? in
            guard record.status.normalized == .friendPending else { return nil }
            guard record.friendRequestedBy != currentUserID else { return nil }
            
            let isRelatedToCurrent = (record.followerID == currentUserID || record.followingID == currentUserID)
            guard isRelatedToCurrent else { return nil }
            
            let requesterID = record.friendRequestedBy ?? (record.followerID == currentUserID ? record.followingID : record.followerID)
            return requesterID
        }
        
        return incomingRequestIDs.compactMap { usersByID[$0] }
    }
}
