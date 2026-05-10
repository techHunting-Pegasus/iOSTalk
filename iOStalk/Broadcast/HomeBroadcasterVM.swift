//
//  HomeviewModel.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 25/03/26.
//

import Foundation
import Combine
import SwiftUI
import WebKit

class WebViewTestDelegate: NSObject, WKNavigationDelegate {
    var completion: (Bool) -> Void
    private var strongSelf: WebViewTestDelegate?

    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init()
        // We hold a strong reference to ourselves because WKWebView's
        // navigationDelegate is a weak property.
        self.strongSelf = self
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Give the page 1 second to execute any JavaScript that might
        // replace "Loading" text with "404" or a Player.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            webView.evaluateJavaScript("document.body.innerText") { [weak self] (result, error) in
                guard let text = result as? String else {
                    self?.finish(false)
                    return
                }
                
                let lowerText = text.lowercased()
                
                // Identify the "Soft 404" indicators seen in your screenshot
                let isErrorPage = lowerText.contains("404") ||
                                 lowerText.contains("not found") ||
                                 lowerText.contains("no video") ||
                                 text.count < 100 // Real players have long HTML/JS
                
                self?.finish(!isErrorPage)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(false)
    }

    private func finish(_ result: Bool) {
        completion(result)
        strongSelf = nil // Release the reference to prevent memory leaks
    }
}

@MainActor
class HomeBroadcasterVM: ObservableObject {
    @Published var isloading: Bool = false
    
    @Published var popularlist: [PopularResult] = []
    @Published var activeURL: String? = nil
    @Published var statusMessage: String = ""
    
    func fetchpopular(){
        
//        URLSession.shared.dataTask(with: URL(string: BroadcastEndpoint.erv)!) { data, res, err in
//            print("DATA:", data != nil)
//            print("ERROR:", err)
//        }.resume()
       
        Task{
            isloading = true
            
            defer {
                isloading = false
            }
            
            do {
                let response : Popular = try await NetworkManager.shared.get(url: BroadcastEndpoint.popularmoview())
                
                self.popularlist = response.results ?? []
                
                print(response.totalPages, "jhbjhvj")
            }catch{
                print("Error==>", error.localizedDescription)
            }
            
        }
    }
    
    func checkProviderAvailability(id: String, provider: VideoProvider) async -> Bool {
        guard let url = URL(string: provider.urlFactory(id)) else { return false }
        
        var request = URLRequest(url: url)
        // 1. Use GET instead of HEAD. Some servers block HEAD.
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        // 2. IMPORTANT: Add a browser-like User-Agent
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        // 3. Optional: Add a Referer if some providers require it
        request.setValue("https://google.com", forHTTPHeaderField: "Referer")

        do {
            // Use a standard data task.
            // We don't need the body, just the response headers.
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("\(provider.name) returned status: \(httpResponse.statusCode)")
                
                // Some providers return 403 or 503 if they detect a bot,
                // but 200-399 generally means the page exists.
                return (200...399).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            print("Error checking \(provider.name): \(error.localizedDescription)")
            return false
        }
    }
    func validateContent(url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let webView = WKWebView()
                let request = URLRequest(url: url)
                
                // Set a browser User-Agent to avoid being blocked
                webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
                
                let delegate = WebViewTestDelegate { success in
                    continuation.resume(returning: success)
                    _ = webView // Keep reference alive
                }
                webView.navigationDelegate = delegate
                webView.load(request)
            }
        }
    }
    
    @MainActor
    func findAndPlay(tmdbID: String) async {
        
        print(tmdbID, "jehrbierv")
        for provider in VideoProvider.all {
            print("Checking \(provider.name)...")
//            let isAvailable = await checkProviderAvailability(id: tmdbID, provider: provider)
            
            // Use the content validator instead of the status code checker
            let urlString = provider.urlFactory(tmdbID)
                    guard let url = URL(string: urlString) else { continue }
                    
                    print("Checking \(provider.name)...")
            
                    let isAvailable = await validateContent(url: url)
                    
                    if isAvailable {
                        self.activeURL = urlString
                        self.statusMessage = "Playing from \(provider.name)"
                        return // Found a winner!
                    } else {
                        print("\(provider.name) failed content validation (Soft 404).")
                    }
            
//            if isAvailable {
//                self.activeURL = provider.urlFactory(tmdbID)
//                self.statusMessage = "Playing from \(provider.name)"
//                return // Stop searching once we find a winner
//            }
        }
        self.statusMessage = "No working servers found."
    }
    
}

struct VideoProvider {
    let name: String
    let urlFactory: (String) -> String
    
    static let all = [
        VideoProvider(name: "VidSrc.to", urlFactory: { "https://vidsrc.to/embed/movie/\($0)" }),
        VideoProvider(name: "VidSrc.me", urlFactory: { "https://vidsrc.me/embed/movie?tmdb=\($0)" }),
        VideoProvider(name: "2embed", urlFactory: { "https://www.2embed.cc/embed/\($0)" }),
        VideoProvider(name: "SuperEmbed", urlFactory: { "https://multiembed.mov/?video_id=\($0)&tmdb=1" })
    ]
}

// MARK: - Popular
struct Popular: Codable {
    let page: Int?
    let results: [PopularResult]?
    let totalPages, totalResults: Int?

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Result
struct PopularResult: Codable {
    let adult: Bool?
    let backdropPath: String?
    let genreIDS: [Int]?
    let id: Int?
    let originalLanguage, originalTitle, overview: String?
    let popularity: Double?
    let posterPath, releaseDate, title: String?
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIDS = "genre_ids"
        case id
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview, popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title, video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
