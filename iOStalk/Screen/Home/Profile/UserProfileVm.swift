//
//  UserProfileVm.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 28/12/25.
//

import Foundation

@MainActor
class UserProfileVm : ObservableObject{
    
    @Published var posts: [Post] = []
    @Published var allPosts: [Post] = []
    @Published var isLoading = false
        @Published var errorMessage: String?
        

        private let auth = SupabaseManager.shared
    
    private let pageSize = 15
      private var currentPage = 1
      private var canLoadMore = true

    func loadInitialPosts(userId: String) async {
           currentPage = 1
           canLoadMore = true
           posts.removeAll()
        allPosts.removeAll()
           await loadMorePosts(userId: userId)
        applyFilter(isImage: true)
        
       }
    func loadMorePosts(userId: String, isimage:Bool = true) async {
           guard !isLoading, canLoadMore else { return }

           isLoading = true
           defer { isLoading = false }

           do {
               let newPosts = try await auth.fetchPosts(
                   page: currentPage,
                   pageSize: pageSize,
                   userid: userId.uppercased()
               )
               
               print(newPosts.count, "efvqe")

               if newPosts.count < pageSize {
                   canLoadMore = false // no more data
               }
               allPosts.append(contentsOf: newPosts)
               applyFilter(isImage: true)
               posts.append(contentsOf: newPosts)
               currentPage += 1

           } catch {
               errorMessage = error.localizedDescription
               
               print(error.localizedDescription, "errererererr")
           }
       }
    
    
    func applyFilter(isImage: Bool) {
            if isImage {
                posts = allPosts.filter { ($0.isVideo ?? false) == false }
            } else {
                posts = allPosts.filter { ($0.isVideo ?? false) == true }
            }
        }
    
}
