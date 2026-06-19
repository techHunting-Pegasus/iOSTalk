//
//  SettingVM.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 16/01/26.
//

import Foundation

@MainActor
final class SettingVM: ObservableObject {
    
    @Published var isPrivateAccount = false
    @Published var isUpdatingPrivacy = false
    @Published var errorMessage: String?
    
    private let authManager: SupabaseManager
    
    init(authManager: SupabaseManager = .shared) {
        self.authManager = authManager
        self.isPrivateAccount = AppDefaults.userData.isPrivateAccount ?? false
    }
    
    func refreshPrivacyState() {
        isPrivateAccount = AppDefaults.userData.isPrivateAccount ?? false
    }
    
    func updatePrivacySetting(isPrivate: Bool) {
        Task {
            await setPrivacy(isPrivate: isPrivate)
        }
    }
    
    func logout() {
        Task {
            do {
                try await authManager.supabase.auth.signOut()
                AppDefaults.isLogin = false
                AppDefaults.clear()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func setPrivacy(isPrivate: Bool) async {
        isUpdatingPrivacy = true
        errorMessage = nil
        defer { isUpdatingPrivacy = false }
        
        do {
            let profile = try await authManager.updateCurrentUserPrivacySetting(isPrivateAccount: isPrivate)
            isPrivateAccount = profile.isPrivateAccount ?? false
        } catch {
            isPrivateAccount = AppDefaults.userData.isPrivateAccount ?? false
            errorMessage = error.localizedDescription
        }
    }
}
