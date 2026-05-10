//
//  Helper.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 04/04/25.
//

import Foundation
import UIKit

import SwiftUI

struct Helper {
    static  var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
    static func extractHashtags(from text: String) -> [String] {
        let pattern = "#[A-Za-z0-9_]+"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)

        let matches = regex?.matches(in: text, range: range) ?? []

        return matches.compactMap {
            Range($0.range, in: text).map {
                String(text[$0]).lowercased()
            }
        }
    }
    
    
    
    struct CategoryManager {
        
        static let categoryMap: [String: [String]] = [
            
            "travel": [
                "#travel", "#travelling", "#trip", "#vacation", "#wanderlust",
                "#travelgram", "#explore", "#beach", "#mountains"
            ],
            
            "food": [
                "#food", "#foodie", "#cooking", "#chef", "#tasty", "#kitchen"
            ],
            
            "fitness": [
                "#fitness", "#gym", "#workout", "#healthy"
            ],
            
            "fashion": [
                "#fashion", "#ootd", "#style", "#makeup", "#model"
            ],
            
            "technology": [
                "#tech", "#technology", "#coding", "#developer",
                "#programmer", "#swift", "#iosdeveloper"
            ],
            
            "sports": [
                "#cricket", "#football", "#sports", "#game", "#teams"
            ],
            
            "spiritual": [
                "#god", "#prayers", "#church", "#blessed", "#spiritual"
            ],
            
            "entertainment": [
                "#reels", "#reelsvideo", "#viral", "#meme", "#funny",
                "#lol", "#music", "#dance"
            ],
            
            "nature": [
                "#nature", "#naturelover", "#forest", "#flowers",
                "#sunrise", "#sunset", "#sky"
            ]
        ]
    }
   
    
    static func detectCategory(from hashtags: [String]) -> String {
        
        guard !hashtags.isEmpty else {
            return "general"
        }

        let lowercasedTags = hashtags.map { $0.lowercased() }

        for (category, keywords) in Helper.CategoryManager.categoryMap {
            if keywords.contains(where: { lowercasedTags.contains($0) }) {
                return category
            }
        }

        return "general"
    }
    
    
    
}
struct AppImages {
    static let backbuttonImage: Image = Image(systemName: "chevron.left")
}
struct Appstrins {
    
    static  let hashtagList: [String] = [
        "#love", "#instagood", "#photooftheday", "#fashion", "#beautiful", "#happy", "#cute",
        "#tbt", "#like4like", "#followme", "#picoftheday", "#follow", "#me", "#selfie", "#summer",
        "#art", "#instadaily", "#friends", "#repost", "#nature", "#girl", "#fun", "#style", "#smile",
        "#food", "#instalike", "#likeforlike", "#family", "#travel", "#fitness", "#beauty", "#photo",
        "#life", "#music", "#amazing", "#followforfollow", "#instagram", "#photography", "#sun",
        "#beach", "#dog", "#l4l", "#cat", "#makeup", "#motivation", "#model", "#ootd", "#design",
        "#inspiration", "#lifestyle", "#gym", "#healthy", "#workout", "#holiday", "#cute", "#sunset",
        "#loves", "#friendsforever", "#dance", "#party", "#cool", "#blackandwhite", "#familytime",
        "#weekend", "#foodie", "#tasty", "#bestoftheday", "#throwback", "#goodvibes", "#positive",
        "#quotes", "#quoteoftheday", "#captions", "#swag", "#lovers", "#travelling", "#bike",
        "#cars", "#streetphotography", "#travelgram", "#wanderlust", "#explore", "#instatravel",
        "#trip", "#vacation", "#photoart", "#shots", "#colorful", "#cuteanimals", "#pets",
        "#baby", "#wedding", "#weddingday", "#bride", "#groom", "#landscape", "#mountains",
        "#sky", "#architecture", "#photographer", "#sunrise", "#morning", "#night", "#goodmorning",
        "#goodnight", "#followback", "#instamood", "#igers", "#l4follow", "#instago", "#shopping",
        "#handmade", "#funny", "#lol", "#meme", "#relatable", "#wisdom", "#entrepreneur",
        "#business", "#success", "#startup", "#coding", "#developer", "#programmer", "#swift",
        "#iosdeveloper", "#tech", "#technology", "#gaming", "#gamer", "#gameplay", "#pubg",
        "#bgmi", "#cricket", "#football", "#sports", "#teams", "#win", "#goals", "#motivationdaily",
        "#power", "#focus", "#hardwork", "#dedication", "#god", "#prayers", "#church", "#spiritual",
        "#blessed", "#hope", "#familylove", "#relationship", "#couple", "#valentines", "#lovequotes",
        "#romantic", "#kitchen", "#cooking", "#chef", "#home", "#interior", "#living", "#happiness",
        "#smilemore", "#friendslove", "#chill", "#relax", "#coffee", "#tea", "#morningvibes",
        "#nightvibes", "#mood", "#attitude", "#savage", "#lifequotes", "#instareels", "#reelsvideo",
        "#viral", "#explorepage", "#trend", "#newpost", "#bts", "#funmoments", "#india", "#usa",
        "#punjabi", "#desi", "#indianstyle", "#musiclover", "#singer", "#bollywood", "#hollywood",
        "#naturelover", "#waterfall", "#forest", "#green", "#earth", "#flowers", "#skyporn",
        "#clouds", "#sunshine", "#animal", "#cutevideos", "#dogs", "#cats", "#petsofinstagram"
    ]
    
    
    static let account = "Account"
    static let profile = "Profile"
    static let privateaccount = "Private Account"
    static let deleteaccount = "Delete Account"
    static let Notifications = "Notifications"
    static let notificationsetting = "Notification Settings"
    static let about = "About"
    static let privacypolicy = "Privacy Policy"
    static let termcondion = "Terms & Conditions"
    static let logout = "Logout"
    static let settings = "Settings"
    static let followsuggestion = "Follow Suggestion"
    
}




extension String {
    var lastHashtagQuery: String? {
        let words = self.split(separator: " ")
        guard let last = words.last else { return nil }
        if last.hasPrefix("#") {
            return String(last)
        }
        return nil
    }
}
class ToastManager: ObservableObject {
    static let shared = ToastManager() // global singleton
    
    @Published var message: String = ""
    @Published var isVisible: Bool = false
    
    private init() {}
    
    func show(_ message: String, duration: Double = 2.0) {
        self.message = message
        withAnimation {
            self.isVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.isVisible = false
            }
        }
    }
}
struct ToastView: View {
    @ObservedObject var toast = ToastManager.shared
    
    var body: some View {
        if toast.isVisible {
            VStack {
                Spacer()
                Text(toast.message)
                    .font(.body)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.easeInOut(duration: 0.3), value: toast.isVisible)
        }
    }
}
