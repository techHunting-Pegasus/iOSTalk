import SwiftUI

struct LoginView: View {
    
    @StateObject private var loginVM = LoginVM()
    @State private var isShowingCreateAccount = false
    
    var body: some View {
        NavigationStack {
            AppBackgroundView {
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                        
                        Text("Welcome to iOStalk")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                    }
                    
                    CustomInputField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $loginVM.email,
                        isSecure: false
                    )
                    
                    CustomInputField(
                        icon: "lock",
                        placeholder: "Password",
                        text: $loginVM.password,
                        isSecure: true
                    )
                    
                    ThreeDButton(title: "Log In", isLoading: loginVM.isLoading) {
                        Task {
                            await loginVM.login()
                        }
                    }
                    .padding(.horizontal)
                    .disabled(loginVM.isLoading)
                    
                    HStack(spacing: 6) {
                        Text("New to iOStalk?")
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Button("Create Account") {
                            isShowingCreateAccount = true
                        }
                        .font(.system(size: 15, weight: .semibold))
                    }
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationDestination(isPresented: $isShowingCreateAccount) {
                EmailVC()
            }
        }
        .showErrorBanner($loginVM.errorMessage)
    }
}

#Preview {
    LoginView()
}
