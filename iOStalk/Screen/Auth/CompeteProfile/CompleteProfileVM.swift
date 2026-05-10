//
//  CompleteProfileVM.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 28/10/25.
//

import Foundation
import Combine
import Supabase
import UIKit

class CompleteProfileVM: ObservableObject {
    
 
    @Published var errorMessage:String?
    @Published var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()
    @Published var isSuccess :Bool = false
    private let authManager = SupabaseManager.shared
    
    @Published var userSaved = false
    
    func completeProfile(name:String, image:UIImage, email: String, password: String) {
        
        isLoading = true
        errorMessage = nil
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
        let mainPath = "profile_pics/\(name)_\(timestamp).jpg"
        Task{
            do {
                let url = try await authManager.uploadImage(image, path: mainPath)
                print("Image uploaded: \(url)")
                let user = try await authManager.supabase.auth.user()
                
                let usermodal = UserModal(id: user.id.uuidString, name: name, email: email, imgurl: url, pass: password)
   
      
                authManager.saveUserData(value: usermodal)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        print("User save completed")
                        DispatchQueue.main.async { [weak self] in
                            self?.isLoading = false
                        }
                    } receiveValue: { res in
                        print(res, "ergrtgrtgvrtgrtgrtg")
                      
                            self.userSaved = true
                            AppDefaults.isLogin = true
                        
                    }
                    .store(in: &cancellables)

            } catch {
                print(" Upload failed:", error)
                DispatchQueue.main.async(execute: {
                    self.isLoading = false
                })
               
            }
        }
        
    }
    private func parseSupabaseError(_ error: Error) -> String {
        return (error as? AuthError)?.localizedDescription ?? error.localizedDescription
    }
}
