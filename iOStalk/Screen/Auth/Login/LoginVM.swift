import Foundation
import Supabase

@MainActor
final class LoginVM: ObservableObject {
    
    // MARK: - Inputs
    @Published var email: String = ""
    @Published var password: String = ""
    
    // MARK: - UI State
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies
    private let authManager: SupabaseManager
    
    init(authManager: SupabaseManager = .shared) {
        self.authManager = authManager
    }
    
    // MARK: - Public
    func login() async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !normalizedEmail.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        
        guard Helper.isValidEmail(normalizedEmail) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            _ = try await authManager.signInWithEmailAndPassword(email: normalizedEmail, password: password)
            AppDefaults.isLogin = true
        } catch {
            errorMessage = parseLoginError(error)
        }
    }
    
    // MARK: - Private
    private func parseLoginError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        return error.localizedDescription
    }
}
