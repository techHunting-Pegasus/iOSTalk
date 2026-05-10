//
//  UserlistView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 31/10/25.
//

import SwiftUI
struct MyImageView: View {
    let imageUrlString: String

    var body: some View {
        if let url = URL(string: imageUrlString), !imageUrlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
        } else {
            // fallback placeholder if string is invalid or empty
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
        }
    }
}

struct UserlistView: View {
    @StateObject private var userlistVm = UserlistVM()
    var body: some View {
        AppBackgroundView {
            VStack{
                //Header
                HStack{
                  
                    MyImageView(imageUrlString: AppDefaults.userData.imgurl ?? "")
                   

                    Spacer()
                    
                    Text("iOS talk")
                        .foregroundStyle(.white)
                        .font(.system(size: 22, weight: .bold))
                    
                    Spacer()
                    

                    
                }.padding(.horizontal)
                Spacer()
                
             
                
            }

            
            
//            if userlistVm.isLoading{
//                Color.black.opacity(0.4) // Background Dim
//                    .ignoresSafeArea()
//                
//                ProgressView("Creating Account...")
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(10)
//                    .shadow(radius: 10)
//            }
        }.onAppear {
            userlistVm.listalluser()
            print(AppDefaults.userData, "sferer")
            
        }
    }
}

#Preview {
    UserlistView()
}
