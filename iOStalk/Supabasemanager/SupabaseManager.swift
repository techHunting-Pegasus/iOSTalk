//
//  SupabaseManager.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 04/04/25.
//

import Foundation
import Supabase
import Combine
import UIKit

final class SupabaseManager {
    static let shared = SupabaseManager()
    let supabase: SupabaseClient
    private let bucketName = "user_images"
    private let VideobucketName = "user_video"
    private let Usercollection = "Users"
    private let userfollow = "user_followers"
    
    private(set) var cachedUser: User?
    private init() {
           let supabaseURL = URL(string: "https://mfjbhqpaowrfaocevyyg.supabase.co")!
           let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mamJocXBhb3dyZmFvY2V2eXlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1ODI0MjMsImV4cCI6MjA3NzE1ODQyM30.zx2SVnTkxpWQZoUti3tTICa5VJenyrDTO5tcZQd5OoU"
           self.supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
       }
    

    
}

enum Table {
    case Post
    case Postimage
    case Postvideo
    
    var name: String {
        switch self {
        case .Post:
            return "Posts"
        case .Postimage:
            return "Postimage"
        case .Postvideo:
            return "Postvideo"
        }
    }
}
extension SupabaseManager {
    
    
    func fetchCurrentUser() async -> User? {
            do {
                let user = try await supabase.auth.user()
                cachedUser = user
                return user
            } catch {
                print("Error fetching user:", error)
                return nil
            }
        }
        
        func currentUserId() async -> String? {
            if let cachedUser {
                return cachedUser.id.uuidString
            }
            if let user = await fetchCurrentUser() {
                return user.id.uuidString
            }
            if let storedUserID = AppDefaults.userData.id, !storedUserID.isEmpty {
                return storedUserID
            }
            return nil
        }
    

    
    func sendOTPemail(to email: String) -> Future<Void, Error> {
            return Future { promise in
                Task {
                    do {
                  try await self.supabase.auth.signInWithOTP(email: email,  shouldCreateUser: true)
                        promise(.success(())) // No return needed for OTP
                    } catch {
                        print(error)
                        promise(.failure(error))
                    }
                }
            }
        }
    
    func veryfyOtp(email:String,Otp: String) ->Future<Void, Error> {
        return Future { promise in
            Task {
                do {
                    try await self.supabase.auth.verifyOTP(email: email, token: Otp, type: .email)
                    promise(.success(())) // No return needed for OTP
                } catch {
                    print(error)
                    promise(.failure(error))
                }
            }
        }
    }
    func resendOtp(to email: String) ->Future<Void, Error> {
        return Future { promise in
            Task {
                do {
                try await self.supabase.auth.resend(email: email, type: .signup)
                    promise(.success(())) 
                } catch {
                    print(error)
                    promise(.failure(error))
                }
            }
        }
    }
    
    func signInWithEmailAndPassword(email: String, password: String) async throws -> UserModal {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let session = try await supabase.auth.signIn(email: normalizedEmail, password: password)
            cachedUser = session.user
            return try await fetchUserProfile(forUserID: session.user.id.uuidString)
        } catch {
            // Supports legacy accounts where profile passwords were saved in Users table.
            if let legacyProfile = await fetchLegacyProfile(email: normalizedEmail, password: password) {
                AppDefaults.userData = legacyProfile
                return legacyProfile
            }
            throw error
        }
    }
    
    private func fetchUserProfile(forUserID userID: String) async throws -> UserModal {
        guard !userID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Invalid user identifier."]
            )
        }
        
        let profile: UserModal = try await supabase.database
            .from(Usercollection)
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value
        
        AppDefaults.userData = profile
        return profile
    }
    
    private func fetchLegacyProfile(email: String, password: String) async -> UserModal? {
        do {
            let profile: UserModal = try await supabase.database
                .from(Usercollection)
                .select()
                .eq("email", value: email)
                .eq("pass", value: password)
                .single()
                .execute()
                .value
            
            return profile
        } catch {
            return nil
        }
    }
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "ImageConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
            }

            // Upload the image
        _ = try await supabase.storage
                .from(bucketName)
                .upload(
                    path: path, // e.g. "profiles/user123.jpg"
                    file: imageData,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )

            // Generate a public URL if your bucket is public
        let publicURL = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: path)

            print("✅ Uploaded to:", publicURL.absoluteString)
            return publicURL.absoluteString
        }
    
    func uploadVideo(videoData: Data, path: String) async throws -> String {
            
            let options = FileOptions(
                cacheControl: "3600",
                contentType: "video/mp4", // Adjust content type based on video format
                upsert: false
            )

          _ = try await supabase.storage
                .from(VideobucketName) // Your bucket name
                .upload(path: path, file: videoData, options: options)
        
        let publicURL = try supabase.storage
                .from(VideobucketName)
                .getPublicURL(path: path)


            // Handle success or error
        print("✅ Uploaded to:", publicURL.absoluteString)
        return publicURL.absoluteString
        }
    
    func saveUserData(value: UserModal) -> Future<UserModal, Error> {
        return Future { promise in
            Task {
                do {
                    let response : UserModal = try await self.supabase.database
                        .from(self.Usercollection)
                        .upsert(value)
                        .select()
                        .single()
                        .execute()
                        .value
  
                    promise(.success(response))
                  
                } catch {
                    print("Supabase save error:", error)
                    promise(.failure(error))
                }
            }
        }
    }
    func UpdateserData(value: UserModal) -> Future<PostgrestResponse<Void>, Error> {
        return Future { promise in
            Task {
                do {
                    let response = try await self.supabase.database
                        .from(self.Usercollection)
                        .update(value)
                        .eq("id", value: value.id ?? "")
                        .select()
                        .execute()
                       
                    
                    // Check the HTTP status explicitly
                    promise(.success(response))
                  
                } catch {
                    print("Supabase save error:", error)
                    promise(.failure(error))
                }
            }
        }
    }
    
//    func saveSupabaseData<T: Codable>(value: T, table: Table) -> Future<T, Error> {
//        return Future { promise in
//            Task {
//                do {
//                    let response : T = try await self.supabase.database
//                        .from(table.name)
//                        .upsert(value)
//                        .select()
//                        .single()
//                        .execute()
//                        .value
//
//                    
//                    promise(.success(response))
//
//                } catch {
//                    print("Supabase save error:", error)
//                    promise(.failure(error))
//                }
//            }
//        }
//    }
    func saveSupabaseData<T: Codable>(value: T, table: Table) async throws -> T {
        do {
            let response: T = try await self.supabase.database
                .from(table.name)
                .upsert(value)
                .select()
                .single()
                .execute()
                .value
            return response
        } catch {
            print("Supabase save error:", error)
            throw error
        }
    }
    
    
    func fetchUsers() async throws -> [UserModal]  {
        
        let myuserid =  await currentUserId()
           do {
               let response : [UserModal] = try await supabase.database
                   .from("Users")
                   .select()
                   .neq("id", value: myuserid ?? "")
                   .execute()
                   .value
               
              
               
               return response
               
           } catch {
               print("Fetch user error:", error)
               throw error
           }
       }
    
    
    
    
    func fetchPosts(page: Int, pageSize: Int, userid:String) async throws -> [Post] {
        
        
        let from = (page - 1) * pageSize
        let to = from + pageSize - 1 // Supabase range is inclusive

        let posts: [Post] = try await supabase.database
            .from(Table.Post.name)
            .select()
            .eq("user_id", value: userid)
            .order("created_at", ascending: false)
            .range(from: from, to: to)
            .execute()
            .value

        return posts
    }

    
    func userData() async throws -> UserModal?  {
        let myuserid = await currentUserId()
           do {
               let response : UserModal = try await supabase.database
                   .from(self.Usercollection)
                   .select()
                   .eq("id", value: myuserid ?? "")
                   .single()
                   .execute()
                   .value
            
             
               
               AppDefaults.userData =  response
               
               return  response
           } catch {
               print("Fetch user error:", error)
               throw error
           }
       }
    
    func updateCurrentUserPrivacySetting(isPrivateAccount: Bool) async throws -> UserModal {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1101,
                userInfo: [NSLocalizedDescriptionKey: "Current user not found."]
            )
        }
        
        let updatedProfile: UserModal = try await supabase.database
            .from(Usercollection)
            .update(["is_private_account": isPrivateAccount])
            .eq("id", value: currentUserID)
            .select()
            .single()
            .execute()
            .value
        
        AppDefaults.userData = updatedProfile
        return updatedProfile
    }
    
    func fetchRelationshipRecords() async throws -> [UserRelationshipRecord] {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            return []
        }
        
        let records: [UserRelationshipRecord] = try await supabase.database
            .from(userfollow)
            .select()
            .or("follower_id.eq.\(currentUserID),following_id.eq.\(currentUserID)")
            .execute()
            .value
        
        return records
    }
    
    func sendFollowRequest(to targetUser: UserModal) async throws {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1201,
                userInfo: [NSLocalizedDescriptionKey: "Current user not found."]
            )
        }
        
        guard let targetUserID = targetUser.id, !targetUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1202,
                userInfo: [NSLocalizedDescriptionKey: "Target user id is missing."]
            )
        }
        
        guard currentUserID != targetUserID else {
            return
        }
        
        let existingRelationship = try await fetchDirectedRelationship(
            followerID: currentUserID,
            followingID: targetUserID
        )
        
        if let existingRelationship {
            switch existingRelationship.status.normalized {
            case .followPending, .follower, .friendPending, .friend:
                return
            case .pending, .accepted:
                return
            }
        }
        
        let followStatus: UserRelationshipStatus = (targetUser.isPrivateAccount ?? false)
            ? .followPending
            : .follower
        
        let payload = RelationshipInsertPayload(
            follower_id: currentUserID,
            following_id: targetUserID,
            status: followStatus.rawValue,
            friend_requested_by: nil
        )
        
        try await supabase.database
            .from(userfollow)
            .insert(payload)
            .execute()
    }
    
    func unfollow(userID: String) async throws {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1203,
                userInfo: [NSLocalizedDescriptionKey: "Current user not found."]
            )
        }
        
        try await supabase.database
            .from(userfollow)
            .delete()
            .eq("follower_id", value: currentUserID)
            .eq("following_id", value: userID)
            .execute()
    }
    
    func sendFriendRequest(userID: String) async throws {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1204,
                userInfo: [NSLocalizedDescriptionKey: "Current user not found."]
            )
        }
        
        let pairRelationship = try await fetchPairRelationshipRecords(
            firstUserID: currentUserID,
            secondUserID: userID
        )
        
        if pairRelationship.contains(where: { $0.status.normalized == .friend || $0.status.normalized == .friendPending }) {
            return
        }
        
        guard let followerRecord = pairRelationship.first(where: { $0.status.normalized == .follower }) else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1205,
                userInfo: [NSLocalizedDescriptionKey: "Friend request can only be sent after follow is accepted."]
            )
        }
        
        let payload = RelationshipUpdatePayload(
            status: UserRelationshipStatus.friendPending.rawValue,
            friend_requested_by: currentUserID
        )
        
        try await supabase.database
            .from(userfollow)
            .update(payload)
            .eq("follower_id", value: followerRecord.followerID)
            .eq("following_id", value: followerRecord.followingID)
            .execute()
    }
    
    func respondToFollowRequest(from followerUserID: String, accept: Bool) async throws {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1206,
                userInfo: [NSLocalizedDescriptionKey: "Current user not found."]
            )
        }
        
        guard let requestRecord = try await fetchDirectedRelationship(
            followerID: followerUserID,
            followingID: currentUserID
        ) else {
            return
        }
        
        let normalizedStatus = requestRecord.status.normalized
        guard normalizedStatus == .followPending else {
            return
        }
        
        if accept {
            let payload = RelationshipUpdatePayload(
                status: UserRelationshipStatus.follower.rawValue,
                friend_requested_by: nil
            )
            
            try await supabase.database
                .from(userfollow)
                .update(payload)
                .eq("follower_id", value: followerUserID)
                .eq("following_id", value: currentUserID)
                .execute()
        } else {
            try await supabase.database
                .from(userfollow)
                .delete()
                .eq("follower_id", value: followerUserID)
                .eq("following_id", value: currentUserID)
                .execute()
        }
    }
    
    func respondToFriendRequest(from userID: String, accept: Bool) async throws {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1207,
                userInfo: [NSLocalizedDescriptionKey: "Current user not found."]
            )
        }
        
        let pairRelationship = try await fetchPairRelationshipRecords(
            firstUserID: currentUserID,
            secondUserID: userID
        )
        
        guard let friendRequestRecord = pairRelationship.first(where: {
            $0.status.normalized == .friendPending && $0.friendRequestedBy != currentUserID
        }) else {
            return
        }
        
        let payload = RelationshipUpdatePayload(
            status: accept ? UserRelationshipStatus.friend.rawValue : UserRelationshipStatus.follower.rawValue,
            friend_requested_by: nil
        )
        
        try await supabase.database
            .from(userfollow)
            .update(payload)
            .eq("follower_id", value: friendRequestRecord.followerID)
            .eq("following_id", value: friendRequestRecord.followingID)
            .execute()
    }
    
    func unfriend(userID: String) async throws {
        guard let currentUserID = await currentUserId(), !currentUserID.isEmpty else {
            throw NSError(
                domain: "SupabaseManager",
                code: 1208,
                userInfo: [NSLocalizedDescriptionKey: "Current user not found."]
            )
        }
        
        let pairRelationship = try await fetchPairRelationshipRecords(
            firstUserID: currentUserID,
            secondUserID: userID
        )
        
        guard let friendRecord = pairRelationship.first(where: { $0.status.normalized == .friend }) else {
            return
        }
        
        let payload = RelationshipUpdatePayload(
            status: UserRelationshipStatus.follower.rawValue,
            friend_requested_by: nil
        )
        
        try await supabase.database
            .from(userfollow)
            .update(payload)
            .eq("follower_id", value: friendRecord.followerID)
            .eq("following_id", value: friendRecord.followingID)
            .execute()
    }
    
    func relationshipState(
        with targetUserID: String,
        records: [UserRelationshipRecord],
        currentUserID: String
    ) -> RelationshipState {
        if let currentToTargetRecord = records.first(where: {
            $0.followerID == currentUserID && $0.followingID == targetUserID
        }) {
            return mapRelationshipState(record: currentToTargetRecord, currentUserID: currentUserID, isCurrentToTarget: true)
        }
        
        if let targetToCurrentRecord = records.first(where: {
            $0.followerID == targetUserID && $0.followingID == currentUserID
        }) {
            return mapRelationshipState(record: targetToCurrentRecord, currentUserID: currentUserID, isCurrentToTarget: false)
        }
        
        return .none
    }
    
    private func fetchDirectedRelationship(
        followerID: String,
        followingID: String
    ) async throws -> UserRelationshipRecord? {
        let records: [UserRelationshipRecord] = try await supabase.database
            .from(userfollow)
            .select()
            .eq("follower_id", value: followerID)
            .eq("following_id", value: followingID)
            .execute()
            .value
        
        return records.first
    }
    
    private func fetchPairRelationshipRecords(
        firstUserID: String,
        secondUserID: String
    ) async throws -> [UserRelationshipRecord] {
        let relationFilter = "and(follower_id.eq.\(firstUserID),following_id.eq.\(secondUserID)),and(follower_id.eq.\(secondUserID),following_id.eq.\(firstUserID))"
        
        let records: [UserRelationshipRecord] = try await supabase.database
            .from(userfollow)
            .select()
            .or(relationFilter)
            .execute()
            .value
        
        return records
    }
    
    private func mapRelationshipState(
        record: UserRelationshipRecord,
        currentUserID: String,
        isCurrentToTarget: Bool
    ) -> RelationshipState {
        switch record.status.normalized {
        case .followPending:
            return isCurrentToTarget ? .followRequestedSent : .followRequestedReceived
        case .follower:
            return isCurrentToTarget ? .following : .followedBy
        case .friendPending:
            if record.friendRequestedBy == currentUserID {
                return .friendRequestedSent
            }
            return .friendRequestedReceived
        case .friend:
            return .friend
        case .pending:
            return isCurrentToTarget ? .followRequestedSent : .followRequestedReceived
        case .accepted:
            return isCurrentToTarget ? .following : .followedBy
        }
    }
}
