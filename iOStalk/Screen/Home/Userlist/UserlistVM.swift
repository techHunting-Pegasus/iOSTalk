//
//  UserlistVM.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 31/10/25.
//


import Foundation
import Combine
import Supabase
import UIKit
@MainActor
class UserlistVM: ObservableObject {
    
 
    @Published var errorMessage:String?
    @Published var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()
    @Published var isSuccess :Bool = false
    private let authManager = SupabaseManager.shared
    @Published var users :[UserModal] = []
    
    @Published var userSaved = false
    
    func listalluser() {
        
        isLoading = true
        errorMessage = nil
        
        Task{
            do {
                let user = try await authManager.fetchUsers()
                self.isLoading = false
                users = user
                
            } catch {
                print("user failed:", error)
                errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
        
    }
   
    
    private func parseSupabaseError(_ error: Error) -> String {
        return (error as? AuthError)?.localizedDescription ?? error.localizedDescription
    }
}
