//
//  UserModal.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 28/10/25.
//

import Foundation


struct UserModal : Codable,Identifiable{
    var id:String?
    var name:String?
    var email: String?
    var imgurl:String?
    var pass:String?
    var created_at : String?
}

struct Post: Codable {
    var id: Int?
    var user_id: String
    var caption: String?
    var created_at: String?
    var isPublic: Bool
    var category:String?
    var hastags:[String]?
    var isVideo: Bool?
    var thumbnail:String?
    var imgurl:String?
    var likes: Int?
    var comments:Int?
}

struct Postimage : Codable {
    var id: Int?
    var urls: [String]?
    var user_id: String
    var post_id:Int
    var created_at: String?

}
struct Postvideo : Codable {
    var id: Int?
    var url: String?
    var post_id:Int?
    var user_id: String?
    var created_at: String?
    var thumbnail:String?
}

struct Like: Codable {
    var id: Int
    var post_id: Int
    var user_id: String
    var created_at: String
}
struct Comment: Codable {
    var id: String
    var post_id: Int
    var user_id: String
    var text: String
    var created_at: String
}
