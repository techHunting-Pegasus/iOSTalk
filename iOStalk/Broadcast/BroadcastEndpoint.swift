//
//  BroadcastEndpoint.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 25/03/26.
//

import Foundation
struct BroadcastEndpoint {
    static let baseurl = "https://api.themoviedb.org/3"
    
    static let api = "66d7806982db371a55e73c4a1367bcd0"
    static private let language = "en-US"
    static func  getimage(id:String) -> String {
        return "https://image.tmdb.org/t/p/w300\(id)"
    }
    
    
    static func popularmoview(page:Int = 1) -> String {
        return "\(baseurl)/discover/movie?api_key=\(api)&language=\(language)&page=\(page)"
        
    }
    
    static let erv = "https://api.themoviedb.org/3/discover/movie?api_key=66d7806982db371a55e73c4a1367bcd0&language=en-US&page=1"
    
}
