//
//  CreateAccountVM.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 05/04/25.
//

import Foundation
import Supabase
import Combine

class CreateAccountVM: ObservableObject {
    
    @Published var password: String = ""
    @Published var errorMessage:String?
    @Published var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()
    @Published var isSuccess :Bool = false
    private let authManager = SupabaseManager.shared
    func signUp(email:String) {
        print(email)
        isLoading = true
        errorMessage = nil
        
        authManager.sendOTPemail(to: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = self?.parseSupabaseError(error)
                }
            } receiveValue: { res in
                print("OTP sent successfully",res)
                ToastManager.shared.show("OTP sent successfully! Check your email.")
                self.isSuccess = true
            }
            .store(in: &cancellables)
    }
    private func parseSupabaseError(_ error: Error) -> String {
        return (error as? AuthError)?.localizedDescription ?? error.localizedDescription
    }
}
