//
//  Appdefault.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 27/10/25.
//

import Foundation
struct  AppDefaults{
    
    private static let userdata = "userData"
    
    static func clear() {
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
                UserDefaults.standard.synchronize()
            }
        }
    
    static var isLogin: Bool{
        set{
            UserDefaults.standard.set(newValue, forKey: "isLogin")
        }
        get{
            return UserDefaults.standard.bool(forKey:  "isLogin")
        }
    }
    
//    static var userID: String{
//        set{
//            UserDefaults.standard.set(newValue, forKey: "userID")
//        }
//        get{
//            return UserDefaults.standard.string(forKey:  "userID") ?? ""
//        }
//    }
//    static var appName: String{
//        set{
//            UserDefaults.standard.set(newValue, forKey: "appName")
//        }
//        get{
//            return UserDefaults.standard.string(forKey:  "appName") ?? "No Sweat Desk Yoga"
//        }
//    }
//    
//    static var interval: Int{
//        set{
//            UserDefaults.standard.set(newValue, forKey: "interval")
//        }
//        get{
//            return UserDefaults.standard.integer(forKey: "interval") ?? 30
//        }
//    }
//    static var index: Int{
//        set{
//            UserDefaults.standard.set(newValue, forKey: "index")
//        }
//        get{
//            return UserDefaults.standard.integer(forKey: "index")
//        }
//    }
//    
//    static var sound: Int{
//        set{
//            UserDefaults.standard.set(newValue, forKey: "sound")
//        }
//        get{
//            return UserDefaults.standard.integer(forKey: "sound")
//        }
//    }
//    static var isSubscribe: Int{
//        set{
//            UserDefaults.standard.set(newValue, forKey: "isSubscribe")
//        }
//        get{
//            return UserDefaults.standard.integer(forKey: "isSubscribe")
//        }
//    }
    
    static var userData: UserModal{
        set{
            UserDefaults.standard.set(try? PropertyListEncoder().encode(newValue), forKey:userdata)
        }
        get{
            if let data = UserDefaults.standard.value(forKey:userdata) as? Data {
                let userData = (try? PropertyListDecoder().decode(UserModal.self, from: data)) ?? UserModal()
                return userData
            }
            else{
                return UserModal()
            }
        }
    }
    static func clearUser() {
            UserDefaults.standard.removeObject(forKey: userdata)
        }
    
    
    
    
}
