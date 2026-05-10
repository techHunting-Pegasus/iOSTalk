//
//  FollowSuggestionViewModal.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 19/01/26.
//

import Foundation


class FollowSuggestionViewModal : ObservableObject{
    @Published var errorMessage:String?
    @Published var isLoading: Bool = false
    
    
    
    private let authManager = SupabaseManager.shared
    

    @Published var users : [UserModal] = []

    @Published var userSaved = false


    func listalluser() {
        
        isLoading = true
        errorMessage = nil
        
        Task{
            do {
                let user = try await authManager.fetchUsers()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.users = user
                }
              
            } catch {
                print("user failed:", error)
                errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
        
    }
    
    func followuser(followeruser:UserModal){
        
        isLoading = true
        errorMessage = nil
        
     
          authManager.followuser(following_id: followeruser.id ?? "", status: .pending)
                
    }
    
}
