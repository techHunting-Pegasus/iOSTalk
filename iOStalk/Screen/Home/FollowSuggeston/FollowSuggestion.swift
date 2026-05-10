//
//  FollowSuggestion.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 19/01/26.
//

import SwiftUI

struct FollowSuggestion: View {
    
    
    @StateObject var viewmodel  = FollowSuggestionViewModal()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        AppBackgroundView {
            ZStack{
                VStack{ 
                    HStack(spacing: 30){
                        AppImages.backbuttonImage
                            .resizable()
                            .frame(width: 10, height: 20)
                            .foregroundStyle(.white)
                            .onTapGesture {
                                dismiss()
                            }
                        Text(Appstrins.followsuggestion)
                            .foregroundStyle(.white)
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                    }.padding(.leading, 20)
                    Spacer()
                    
                    List {
                        ForEach(viewmodel.users) { user in
                            UserRow(user: user, vm: viewmodel)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
                
                
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewmodel.listalluser()
        }
    }
}
struct UserRow: View {
    
    let user: UserModal
    @ObservedObject var vm : FollowSuggestionViewModal
    
    var body: some View {
        HStack {
            
            // Profile Placeholder
            CachedImageView(url: user.imgurl ?? "")
                .frame(width: 45, height: 45)
                .clipShape(Circle())
                
           
               
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name ?? "")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .medium))
                
            }
            
            Spacer()
            
            Button {
                print("Follow tapped")
                
                print(user.id, "cekjfv")
                
                vm.followuser(followeruser: user)
            } label: {
                Text("Follow")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
            }
        }
        .padding(.vertical, 8)
    }
}


#Preview {
    FollowSuggestion()
}
