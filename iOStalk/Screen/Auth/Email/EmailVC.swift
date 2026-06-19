import SwiftUI

struct EmailVC: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @StateObject private var createAccount = CreateAccountVM()
    
    var body: some View {
        AppBackgroundView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                    
                    Text("Create your account")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
                
                CustomInputField(
                    icon: "envelope",
                    placeholder: "Email",
                    text: $email,
                    isSecure: false
                )
                
                CustomInputField(
                    icon: "lock",
                    placeholder: "Password",
                    text: $password,
                    isSecure: true
                )
                
                CustomInputField(
                    icon: "lock",
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isSecure: true
                )
                
                ThreeDButton(title: "Create Account", isLoading: createAccount.isLoading) {
                    sendOtpForCreateUser()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            
            if createAccount.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ProgressView("Creating Account...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .showErrorBanner($createAccount.errorMessage)
        .navigationDestination(isPresented: $createAccount.isSuccess) {
            OtpView(email: email, pass: password)
        }
    }
    
    private func sendOtpForCreateUser() {
        guard !email.isEmpty else {
            ToastManager.shared.show("Please enter your email")
            return
        }
        
        guard Helper.isValidEmail(email) else {
            ToastManager.shared.show("Email address is not valid")
            return
        }
        
        guard !password.isEmpty else {
            ToastManager.shared.show("Please enter your password")
            return
        }
        
        guard !confirmPassword.isEmpty else {
            ToastManager.shared.show("Please confirm your password")
            return
        }
        
        guard password == confirmPassword else {
            ToastManager.shared.show("Password does not match")
            return
        }
        
        createAccount.signUp(email: email)
    }
}

#Preview {
    EmailVC()
}
