//
//  CustomTabbarItem.swift
//  reelsView
//
//  Created by Ishpreet Singh on 28/11/25.
//

import Foundation
import SwiftUI
enum TabbedItems: Int, CaseIterable{
    case home = 0
    case favorite
//    case chat
//    case profile
    
    var title: String{
        switch self {
        case .home:
            return "Home"
        case .favorite:
            return "Favorite"
//        case .chat:
//            return "Chat"
//        case .profile:
//            return "Profile"
        }
    }
    
    var iconName: Image{
        switch self {
        case .home:
            return Image(.house)
        case .favorite:
            return Image(.folder)
//        case .chat:
//            return "chat-icon"
//        case .profile:
//            return "profile-icon"
        }
    }
}
