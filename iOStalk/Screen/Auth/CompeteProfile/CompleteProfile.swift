//
//  CompleteProfile.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 28/10/25.
//

import SwiftUI
import PhotosUI

struct CompleteProfile: View {
    var email:String
    var pass: String
    @State private var firstname: String = ""
    @State private var lastname: String = ""
    
    @State private var isLoading = false
    
    @State private var errorMessage: String? = nil
    @StateObject private var completeVm = CompleteProfileVM()
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    var body: some View {
        
            AppBackgroundView {
                
                VStack(spacing: 24) {
                    Text("Complete profile")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 110, height: 110)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { oldValue, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                            }
                        }
                    }
                    
                    
                    // Email Field
                    CustomInputField(
                        icon: "envelope",
                        placeholder: "First name",
                        text: $firstname,
                        isSecure: false
                    )
                    CustomInputField(
                        icon: "envelope",
                        placeholder: "Last name",
                        text: $lastname,
                        isSecure: false
                    )
                    
                    // Login Button
                    ThreeDButton(title: "Submit", isLoading: isLoading) {
                        
                        
                        SendotpforCreateuser()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    Spacer()
                    
                }
                .padding()
                
                if completeVm.isLoading {
                    Color.black.opacity(0.4) // Background Dim
                        .ignoresSafeArea()
                    
                    ProgressView("Creating Account...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }.showErrorBanner($completeVm.errorMessage)
                .navigationDestination(isPresented: $completeVm.isSuccess) {
                    //                    OtpView(email: email)
                }
             
            
        
    }
    private func SendotpforCreateuser(){
        guard !firstname.isEmpty else {
            ToastManager.shared.show("Please enter your first name")
            return
        }
        guard !lastname.isEmpty else {
            ToastManager.shared.show("Please enter your last name")
            return
        }
        guard  let img = selectedImage else{
            ToastManager.shared.show("Please select and image")
            return
        }
        completeVm.completeProfile(name: "\(firstname + lastname)", image: img, email: email, password: pass)
        
        
        
        
    }
}

#Preview {
    CompleteProfile(email: "wdfw", pass: "defewf")
}



