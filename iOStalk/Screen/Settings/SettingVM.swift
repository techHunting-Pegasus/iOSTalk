//
//  SettingVM.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 16/01/26.
//

import Foundation

@MainActor
class SettingVM: ObservableObject {
    private let authManager = SupabaseManager.shared
    
    func logout(){
        Task {
         try await authManager.supabase.auth.signOut()
            AppDefaults.isLogin = false
            AppDefaults.clear()
        }
    }
}
