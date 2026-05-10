//
//  DetailView.swift
//  reelsView
//
//  Created by Ishpreet Singh on 27/11/25.


import SwiftUI
import AVKit
import Kingfisher

struct UserProfile: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var isMenuOpen : Bool
    @State var user: UserModal = AppDefaults.userData
    @State  private var isImage = true
    @State private var post : [Post] = []
    @State private var followSuggestion = false
    @StateObject private var vm = UserProfileVm()
    @State private var reels: [UserData]  = {
        
        guard let ima1 = Bundle.main.url(forResource: "Hamburger", withExtension: "jpg"),
              let ima2 = Bundle.main.url(forResource: "foos", withExtension: "jpg"),
              let ima3 = Bundle.main.url(forResource: "images", withExtension: "jpeg") else {
            return []
        }
        
        let images = [ima1, ima2, ima3, ima2, ima1]
        return images.map { url in
            UserData(
                url: nil,
                caption: "Local Image",
                player: nil,
                imageurl: url,
                img: UIImage(contentsOfFile: url.path)
            )
        }
    }()
    
    
    
    @State private var selectedIndex: Int = 0
    @State private var isfscreenull: Bool = false
    @Namespace private var carouselNamespace
    
    private var columns: [GridItem] {
        let count = min(vm.posts.count, 3) // max 3 columns
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }
    
    var body: some View {
        
        
        AppBackgroundView {
            
            
            VStack {
                HStack{
                    Image(systemName: "chevron.left")
                        .resizable()
                        .frame(width: 13, height: 20)
                        .foregroundStyle(.white)
                        .onTapGesture {
                            dismiss()
                        }
                    HStack(alignment:.center){
                        CachedImageView(url: user.imgurl ?? "")
                            .frame(width:60, height: 60)
                            .clipShape(Circle())
                        Text(user.name ?? "User")
                            .foregroundStyle(.white)
                    }
                    
                    
                    Spacer()
                }.padding(.horizontal, 20)
                    .padding(.top, 20)
                
                
                
                HStack{
                    VStack(alignment:.leading,spacing: 10){
                        Text(user.email ?? "user@yopmail,com")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                        Text("biowefkjekcej clwkflkwclkw clkj wekj kewj kej ckej ckej kcje kcej kce kcjec ekcm ekc ekc")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    
                    
                    Spacer()
                }
                .padding()
                
                HStack(spacing:20){
                    SelectionButton(title: "Images", isSelected: isImage) {
                        
                        isImage = true
                        
                        vm.applyFilter(isImage: true)
                    }
                    SelectionButton(title: "Videos", isSelected: !isImage) {
                        
                        isImage = false
                        vm.applyFilter(isImage: false)
                    }
                    
                    
                    Spacer()
                    
                    Image(systemName: "person.fill.badge.plus")
                        .foregroundStyle(.white)
                        .font(.system(size: 24))
                        .padding(.trailing, 20)
                        .onTapGesture {
                            withAnimation {
                                followSuggestion = true
                            }
                        }
                }.padding()
                
                
                
                if vm.isLoading {
                           ProgressView()
                               .padding()
                               .frame(maxWidth: .infinity)
                       }
                if !vm.isLoading {
                    if vm.posts.isEmpty {
                        
                        Text("Currently post is not available")
                            .foregroundStyle(.white)
                            .font(.system(size: 18, weight: .semibold))
                    }else{
                        
                        
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(vm.posts.indices, id: \.self) { index in
                                    
                                    let post = vm.posts[index]
                                    let imageUrl = post.isVideo == true
                                    ? post.thumbnail
                                    : post.imgurl
                                    
                                    if let imgurl = imageUrl{
                                        CachedImageView(url: imgurl)
                                            .frame(
                                                width: (UIScreen.main.bounds.width - CGFloat(columns.count + 1) * 14) / CGFloat(columns.count),
                                                height: (UIScreen.main.bounds.width - CGFloat(columns.count + 1) * 14) / CGFloat(columns.count)
                                            )
                                            .cornerRadius(19)
                                            .onTapGesture {
                                                withAnimation {
                                                    isfscreenull = true
                                                    selectedIndex = index
                                                }
                                                
                                            }
                                            .onAppear {
                                                // 👇 Infinite scroll trigger
                                                if index == vm.posts.count - 1 {
                                                    Task {
                                                        await vm.loadMorePosts(userId: user.id ?? "")
                                                    }
                                                }
                                            }
                                        
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                    }

                
                Spacer()
                
            }
            
            
            if  isfscreenull && isImage {
                FullScreenCarousel(
                    post: vm.posts,
                    onDismiss: {
                        withAnimation {
                            isfscreenull = false
                            
                        }
                        
                    },
                    currentindex: $selectedIndex
                )
            }
        }
        .onAppear(perform: {
            isMenuOpen = false
            Task{
                
            }
            Task {
                
                await vm.loadInitialPosts(userId: user.id ?? "")
            }
        })
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $followSuggestion) {
            FollowSuggestion()
        }
    }
}

#Preview {
    UserProfile(isMenuOpen: .constant(false))
}










