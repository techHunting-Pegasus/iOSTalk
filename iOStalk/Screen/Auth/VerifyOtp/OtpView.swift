//
//  OtpView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 27/10/25.
//

import SwiftUI

struct OtpView: View {
    var email: String
    var pass: String
    
    @State private var Otp: String = ""
    
    @State private var isLoading = false
    
    @State private var errorMessage: String? = nil
    @StateObject private var VerifyVm = VerifyOtpVM()
    @State private var timerCount = 0
    @State private var timer: Timer? = nil
    var body: some View {
        AppBackgroundView {
            VStack(spacing: 24) {
                Spacer()
                // App Logo or Title
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                    
                    Text("Verify to iOStalk")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
                
                // Email Field
                CustomInputField(
                    icon: "envelope",
                    placeholder: "Otp",
                    text: $Otp,
                    isSecure: false
                )
                HStack{
                    Text("Otp sent to \(email)")
                        .font(.system(size: 14,weight: .regular))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // add timer for 30 seconds then hide
                    
                    if timerCount > 0 {
                        // Countdown visible
                        Text("\(timerCount)s")
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .semibold))
                    } else {
                        // Resend button visible
                        Text("Resend")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                            .onTapGesture {
                                resendOtp()
                            }
                    }
                    
                    
                }
                
                // Login Button
                ThreeDButton(title: "Verify", isLoading: isLoading) {
                    verifyOtp()
                    
                    
                }
                .padding(.horizontal)
                
                Spacer()
                
            }
            .padding()
            
            if VerifyVm.isLoading {
                Color.black.opacity(0.4) // Background Dim
                    .ignoresSafeArea()
                
                ProgressView("Creating Account...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }.showErrorBanner($VerifyVm.errorMessage)
            .onAppear {
                startTimer()
            }
            .navigationDestination(isPresented: $VerifyVm.isVerified) {
                CompleteProfile(email: email, pass: pass)
            }
        
    }
    private func verifyOtp(){
        guard !Otp.isEmpty else{
            ToastManager.shared.show("Please enter otp")
            return
        }
        VerifyVm.verifyOtp(email: email, otp: Otp)
    }
    private func resendOtp() {
        VerifyVm.resendOtp(email: email)
        startTimer()
    }
    private func startTimer() {
        timer?.invalidate()
        timerCount = 120
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerCount > 0 {
                timerCount -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

#Preview {
    OtpView(email: "fedvc", pass: "sdfd")
}








