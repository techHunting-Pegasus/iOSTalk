import SwiftUI
import Combine

struct EmailVC: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var Confirmpassword: String = ""
    @State private var isLoading = false
    
    @State private var errorMessage: String? = nil
    @StateObject private var CreateAccount = CreateAccountVM()
    var body: some View {
        NavigationStack {
            AppBackgroundView {
                VStack(spacing: 24) {
                    Spacer()

                    // App Logo or Title
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)

                        Text("Welcome to iOStalk")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                    }

                    // Email Field
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

                    // Password Field
                    CustomInputField(
                        icon: "lock",
                        placeholder: "Confirm Password",
                        text: $Confirmpassword,
                        isSecure: true
                        
                    )

                    // Login Button
                    ThreeDButton(title: "Sign In", isLoading: isLoading) {
                        
                        
                        SendotpforCreateuser()
                    }
                    .padding(.horizontal)

                    Spacer()
                  
                }
                .padding()
                
                if CreateAccount.isLoading {
                    Color.black.opacity(0.4) // Background Dim
                                        .ignoresSafeArea()

                                    ProgressView("Creating Account...")
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(radius: 10)
                }
            }.showErrorBanner($CreateAccount.errorMessage)
                .navigationDestination(isPresented: $CreateAccount.isSuccess) {
                    OtpView(email: email, pass: password)
                }
          
        }
    }
    private func SendotpforCreateuser(){
        guard !email.isEmpty else {
            ToastManager.shared.show("Please enter your email")
            return
        }
        guard  Helper.isValidEmail(email) else{
            ToastManager.shared.show("Email id is not vaild")
            return
        }
        guard !password.isEmpty else {
            ToastManager.shared.show("Please enter your password")
            return
        }

        guard !Confirmpassword.isEmpty else {
            ToastManager.shared.show("Please enter your comfimr password")
            return
        }
        guard password == Confirmpassword else{
            ToastManager.shared.show("Password does not match")
            return
        }
        

        CreateAccount.signUp(email: email)
    }

}
#Preview {
    EmailVC()
}
