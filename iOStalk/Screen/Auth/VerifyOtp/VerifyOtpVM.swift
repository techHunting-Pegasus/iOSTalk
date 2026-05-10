//
//  VerifyOtpVM.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 27/10/25.
//

import Foundation
import Supabase
import Combine

class VerifyOtpVM: ObservableObject {
    
    @Published var errorMessage:String?
    @Published var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private let authManager = SupabaseManager.shared
    @Published var isVerified = false
    func verifyOtp(email:String, otp:String) {
        print(email, otp)
        isLoading = true
        errorMessage = nil
        
        authManager.veryfyOtp(email: email, Otp: otp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = self?.parseSupabaseError(error)
                }
            } receiveValue: { res in
                self.isVerified = true
                
            }
            .store(in: &cancellables)
    }
    func resendOtp(email:String) {
        print(email)
        isLoading = true
        errorMessage = nil
        
        authManager.resendOtp(to: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = self?.parseSupabaseError(error)
                }
            } receiveValue: { res in
                print("otp sent again",res)
               
            }
            .store(in: &cancellables)
    }
    
    private func parseSupabaseError(_ error: Error) -> String {
        return (error as? AuthError)?.localizedDescription ?? error.localizedDescription
    }
}
