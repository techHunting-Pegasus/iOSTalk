//
//  Crypto.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 28/10/25.
//

import Foundation
import Crypto
struct CryptoManager {
    private static let keyString = "12345678901234567890123456789012" // 32 chars = 256 bits
       private static let key = SymmetricKey(data: Data(keyString.utf8))

    static func encrypt(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Encryption failed:", error)
            return nil
        }
    }

    static func decrypt(_ base64: String) -> String? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed:", error)
            return nil
        }
    }
}


struct EncryptionHelper {
    
    /// Converts any model or dictionary into an encrypted string
    static func encryptObject<T>(_ object: T) throws -> String where T: Encodable {
        let jsonData = try JSONEncoder().encode(object)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "Encoding error", code: 0)
        }
        guard let encrypted = CryptoManager.encrypt(jsonString) else {
            throw NSError(domain: "Encryption failed", code: 0)
        }
        return encrypted
    }
    
    /// Converts a dictionary `[String: Any]` to encrypted string
    static func encryptDictionary(_ dict: [String: Any]) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "Encoding error", code: 0)
        }
        guard let encrypted = CryptoManager.encrypt(jsonString) else {
            throw NSError(domain: "Encryption failed", code: 0)
        }
        return encrypted
    }
    
    /// Decrypts back to any Decodable model
    static func decryptToModel<T: Decodable>(_ encrypted: String, as type: T.Type) throws -> T {
        guard let decryptedJSON = CryptoManager.decrypt(encrypted),
              let jsonData = decryptedJSON.data(using: .utf8) else {
            throw NSError(domain: "Decryption failed", code: 0)
        }
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
    
    /// Decrypts back to dictionary
    static func decryptToDictionary(_ encrypted: String) throws -> [String: Any]? {
        guard let decryptedJSON = CryptoManager.decrypt(encrypted),
              let data = decryptedJSON.data(using: .utf8) else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
//struct UserProfile: Codable {
//    let id: String
//    let email: String
//    let name: String?
//    let password: String?
//}

//let user = UserProfile(id: "123", email: "test@gmail.com", name: "Ish", password: "abc123")
//let encryptedUser = try EncryptionHelper.encryptObject(user)
//print(encryptedUser)

//let userData: [String: Any] = [
//    "id": "user_12345",
//    "first_name": "Ishpreet",
//    "last_name": "Singh",
//    "email": "ishpreet@example.com",
//    "phone": "+91-9876543210",
//    "age": 27,
//    "gender": "male",
//    "country": "India",
//    "city": "Chandigarh",
//    "postal_code": "160019",
//    "is_verified": true,
//    "account_type": "premium",
//    "signup_date": "2025-10-28T10:30:00Z",
//    "last_login": "2025-10-28T12:45:00Z",
//    "device_id": "A1B2C3D4E5",
//    "fcm_token": "abcd1234efgh5678ijkl9012mnop3456",
//    "subscription_status": "active",
//    "preferred_language": "en",
//    "theme_mode": "dark",
//    "referral_code": "REF2025ISH"
//]
//let enc = try EncryptionHelper.encryptDictionary(userData)
//print(enc)
//
//let dec = try EncryptionHelper.decryptToDictionary(enc)!
//print(dec)
//let decryptedUser = try EncryptionHelper.decryptToModel(encryptedUser, as: UserProfile.self)
//print(decryptedUser)
