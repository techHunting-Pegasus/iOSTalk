//
//  UploadPostVM.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 02/12/25.
//

import Foundation
import UIKit
import Combine
import AVFoundation

class UploadPostVM : ObservableObject{
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var uploadSuccess = false
    @Published var imageNude = false
    @Published var videoNude = false
    
    private let auth = SupabaseManager.shared
    
    
    private var cancellables = Set<AnyCancellable>()
    
    
    func uploadPost(
        images: [UIImage]? = nil,
        videoURL: URL? = nil,
        VideoData:Data? = nil,
        caption: String,
        isPublic: Bool,
    ) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.uploadSuccess = false
        }
        
        
        
        
        do {
            guard let userId = await auth.currentUserId() else {
                throw NSError(domain: "UploadPostVM", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            let hashtags =   Helper.extractHashtags(from: caption)
            let category = Helper.detectCategory(from: hashtags)

            // Image Upload
            var uploadedImageUrls: [String] = []
            if let images = images, !images.isEmpty {
                
//                for img in images{
//                    ContentClassifier.shared.classifyImage(image:img) { strr in
//                        print("dfvefrvef", strr, "dfvefrvef")
//                    }
//                }
                let hasNSFW  = await  containsNSFWImage(images)
                if hasNSFW {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.imageNude = true
                    }
                    
                    ToastManager.shared.show("Nude image detected. Please upload proper images.")
                    
                    return
                }
                
                uploadedImageUrls = try await uploadImages(images, userId: userId)
            }
            
            // Video Upload
            var videoUrl: String?
            var thumbnailUrl: String?
            
            if let videoData = VideoData, let videoURL = videoURL {
                
                let isVideoNSFW = try await VisionObjectDetector.shared.checkVideoNudity(
                    videoURL: videoURL
                )
               
              
                if isVideoNSFW {
                    DispatchQueue.main.async(execute: {
                        self.isLoading = false
                        self.videoNude = true
                    })
                    
                    
                    ToastManager.shared.show("Nude content detected in video. Please upload proper video.")
                    return
                }
                
                
                videoUrl = try await uploadVideo(videoData: videoData, userId: userId)
                if let thumbnail = await generateThumbnail(url: videoURL) {
                    thumbnailUrl = try await auth.uploadImage(thumbnail, path: "posts/\(userId)/thumb_\(UUID().uuidString).jpg")
                }
            }
            
            // Create Post
            let isVideo = videoUrl != nil
            let post = Post(
                user_id: userId,
                caption: caption,
                isPublic: isPublic,
                category: category,
                hastags: hashtags,
                isVideo: isVideo,
                thumbnail: thumbnailUrl,
                imgurl: uploadedImageUrls.first,
                likes: 0,
                comments: 0
            )
            
            let savedPost: Post = try await auth.saveSupabaseData(value: post, table: .Post)
            
            // Save Post Media
            if !uploadedImageUrls.isEmpty {
                let postImage = Postimage(urls: uploadedImageUrls, user_id: userId, post_id: savedPost.id ?? 0)
                _ =   try await auth.saveSupabaseData(value: postImage, table: .Postimage)
            }
            
            if let videoUrl = videoUrl {
                let postVideo = Postvideo(url: videoUrl, post_id: savedPost.id ?? 0, user_id: userId, thumbnail: thumbnailUrl)
                _ =  try await auth.saveSupabaseData(value: postVideo, table: .Postvideo)
            }
            DispatchQueue.main.async {
                self.uploadSuccess = true
            }
            
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Upload error:", error)
        }
        DispatchQueue.main.async {
            self.isLoading = false
        }
        
    }
    
    private  func containsNSFWImage(_ images: [UIImage]) async -> Bool {
        
        for image in images {
            do {
                let confidence = try await VisionObjectDetector.shared.checkImageNudity(image: image)
                
                if confidence >= 70 {   // threshold
                    return true        // stop immediately
                }
            } catch {
                continue
            }
        }
        return false
    }
    private func uploadImages(_ images: [UIImage], userId: String) async throws -> [String] {
        return try await withThrowingTaskGroup(of: String.self) { group in
            var urls: [String] = []
            
            for img in images {
                group.addTask {
                    let path = "posts/\(userId)/\(UUID().uuidString).jpg"
                    return try await self.auth.uploadImage(img, path: path)
                }
            }
            
            for try await url in group {
                urls.append(url)
            }
            
            return urls
        }
    }
    
    private func uploadVideo(videoData: Data, userId: String) async throws -> String {
        let path = "posts/\(userId)/\(UUID().uuidString).mp4"
        return try await auth.uploadVideo(videoData: videoData, path: path)
    }
    
    
    func generateThumbnail(url: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 720, height: 1280) // optional
            
            let time = CMTime(seconds: 1, preferredTimescale: 600) // take frame at 1 sec
            
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    print("Thumbnail error:", error?.localizedDescription ?? "Unknown")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    // MARK: - Helpers
    
    private func currentTimestamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: Date())
    }
    
    
    
    
    
    
    
    func isvideo(_ pathExtension: String) -> Bool {
        
        return ["mp4", "mov", "avi"].contains(pathExtension)
    }
    func saveDataToDocumentsDir(_ data: Data, with fileName: String) -> URL? {
        // We get the URL for the document directory
        let documentsURL = URL.documentsDirectory
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        // Now try saving our data to the fileURL
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file \(error)")
            return nil
        }
    }
    
}



