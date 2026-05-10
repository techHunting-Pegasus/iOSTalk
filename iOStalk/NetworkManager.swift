import Foundation
import UIKit
import Alamofire
import Combine




struct APIError: Codable, Error {
    let statusCode: Int?
    let message: String?
}
enum NetworkError: Error, LocalizedError {
    
    case invalidURL
    case noInternet
    case decodingError(Error)
    case serverError(Int)
    case apiError(APIError)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .noInternet:
            return "No Internet Connection."
        case .decodingError(let error):
            return "Decoding Failed: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server Error (HTTP \(code))"
        case .apiError(let apiError):
            return apiError.message ?? "Something went wrong."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}



struct Refreshtokenresponse: Decodable, Sendable {
    let status: Bool?
    let success: Bool?
    let message: String?
    let data: Refreshtokenresponsedata?
}

struct Refreshtokenresponsedata: Decodable, Sendable {
    let accessToken: String?
    let expiresIn: Int?
    let refreshToken: String?
    let refreshExpiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case refreshExpiresIn = "refresh_expires_in"
    }
}

fileprivate enum SessionReset {
    static func clearAndNotifyLogout() {
        AppDefault.clearUserDefaults()
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        URLCache.shared.removeAllCachedResponses()

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("LogoutUser"),
                object: nil
            )
        }
    }
}

fileprivate final class AuthInterceptor: RequestInterceptor {
    
    private var isRefreshing = false
    private var retryRequests: [(RetryResult) -> Void] = []
    
    // MARK: - Add Token To Request
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        
        var request = urlRequest
        
        if let token = AppDefault.accestoken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(request))
    }
    
    
    // MARK: - Handle 401
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }
        
        retryRequests.append(completion)
        
        if !isRefreshing {
            refreshToken()
        }
    }
}
private extension AuthInterceptor {
    func refreshToken() {
        
        guard let refreshToken = AppDefault.refreshtoken else {
            forceLogout()
            return
        }
        isRefreshing = true
        let cleanToken = refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else {
            forceLogout()
            return
        }
        
        
        let fullURL =  APIEndpoints.refreshtoken
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(cleanToken)"
        ]
        print("headers:", headers)
        print("URL:", fullURL)

        
        AF.request(fullURL, method: .post, headers: headers)
            .response { response in
                self.isRefreshing = false
                
                print("STATUS:", response.response?.statusCode ?? 0)
                
                if let data = response.data {
                    print("RAW RESPONSE:", String(data: data, encoding: .utf8) ?? "nil")
                    do {
                        
                        let decoded = try JSONDecoder().decode(Refreshtokenresponse.self, from: data)
                        if decoded.status == false {
                            
                            print(decoded.message, "refresh message")
                            self.forceLogout()
                        }else{
                            AppDefault.accestoken = decoded.data?.accessToken ?? ""
                            AppDefault.refreshtoken = decoded.data?.refreshToken ?? ""
                            AppDefault.isLogin = true
                            
                            self.retryRequests.forEach { $0(.retry) }
                            self.retryRequests.removeAll()
                            
                        }
                        
                        
                    } catch {
                        print(error.localizedDescription, "refresh token error")
                        self.forceLogout()
                    }
                    
                    
                } else {
                    self.forceLogout()
                    print("NO DATA RETURNED")
                }
            }
    }
    
    
    
    
    
    func logout() {
        //
        let token = AppDefault.accestoken ?? ""
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        
        AF.request(
            APIEndpoints.logout,
            method: .post,
            parameters: [:],
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseData(queue: .main) { response in
            
            self.isRefreshing = false
            
            switch response.result {
                
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                    
                    if decoded.status == true {
                        self.cleardata()
                    }
                    
                } catch {
                    self.cleardata()
                    print(error.localizedDescription, "logout error")
                }
                
            case .failure:
                self.cleardata()
            }
        }
        
        
    }
    
    func cleardata(){
        self.retryRequests.forEach { $0(.doNotRetry) }
        self.retryRequests.removeAll()
        SessionReset.clearAndNotifyLogout()
    }

    func forceLogout() {
        isRefreshing = false
        cleardata()
    }
}



final class NetworkManager {
    
    static let shared = NetworkManager()
    private init() {}
    
    private let session: Session = {
        
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        
        // ✅ IMPORTANT FOR AZURE (ARR Affinity)
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let interceptor = AuthInterceptor()
        
        return Session(
            configuration: configuration,
            interceptor: interceptor
        )
    }()
    
    func get<T: Decodable>(
            url: String,
            headers: HTTPHeaders? = nil
        ) async throws -> T {
            print("url: \(url)")
            print("header: \(headers)")
            
            
            guard let url = URL(string: url) else {
                throw NetworkError.invalidURL
            }
            
            return try await request(
                url: url,
                method: .get,
                parameters: nil,
                encoding: URLEncoding.default,
                headers: headers
            )
        }
    
    
    func post<T: Decodable>(
           url: String,
           parameters: Parameters,
           headers: HTTPHeaders? = nil,
           method:HTTPMethod = .post
       ) async throws -> T {
           
           print("parameters: \(parameters)")
           print("url: \(url)")
           print("method: \(method)")
           print("header: \(headers)")
           
           
           
           guard let url = URL(string: url) else {
               throw NetworkError.invalidURL
           }

           logCURLRequest(
               url: url,
               method: method,
               headers: headers,
               parameters: parameters
           )
           
           
           return try await request(
               url: url,
               method: method ,
               parameters: parameters,
               encoding: JSONEncoding.default,
               headers: headers
           )
       }
    
    func upload<T: Decodable>(
            url: String,
            parameters: Parameters,
            image: UIImage,
            imageKey: String,
            fileName: String,
            headers: HTTPHeaders? = nil
        ) async throws -> T {
            
            guard let url = URL(string: url) else {
                throw NetworkError.invalidURL
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                
                session.upload(
                    multipartFormData: { multipart in
                        
                        // Parameters
                        for (key, value) in parameters {
                            multipart.append(
                                "\(value)".data(using: .utf8)!,
                                withName: key
                            )
                        }
                        
                        // Image
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            multipart.append(
                                imageData,
                                withName: imageKey,
                                fileName: fileName,
                                mimeType: "image/jpeg"
                            )
                        }
                    },
                    to: url,
                    headers: headers
                )
                .validate()
                .responseData { response in
                    
                    switch response.result {
                        
                    case .success(let data):
                        do {
                            let decoded = try JSONDecoder().decode(T.self, from: data)
                            continuation.resume(returning: decoded)
                        } catch {
                            print("Error:\(error.localizedDescription)")
                            continuation.resume(
                                throwing: NetworkError.decodingError(error)
                            )
                        }
                        
                    case .failure(let error):
                        self.handleError(response: response, error: error, continuation: continuation)
                    }
                }
            }
        }

    func validateCurrentSession() async {
        guard AppDefault.hasAuthenticatedSession else { return }
        guard let url = URL(string: APIEndpoints.userProfile) else { return }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(AppDefault.accestoken ?? "")"
        ]

        do {
            _ = try await request(
                url: url,
                method: .get,
                parameters: nil,
                encoding: URLEncoding.default,
                headers: headers
            ) as UserProfileResponse
        } catch {
            print("Session validation failed: \(error.localizedDescription)")
        }
    }
}
private extension NetworkManager {
    func logCURLRequest(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        parameters: Parameters?
    ) {
        var components = ["curl -X \(method.rawValue)"]
        components.append("\"\(url.absoluteString)\"")

        headers?.forEach { header in
            let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(header.name): \(escapedValue)\"")
        }

        if let parameters,
           JSONSerialization.isValidJSONObject(parameters),
           let data = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]),
           let body = String(data: data, encoding: .utf8) {
            let escapedBody = body.replacingOccurrences(of: "'", with: "'\\''")
            components.append("-d '\(escapedBody)'")
        }

        print("CURL REQUEST:\n\(components.joined(separator: " \\\n"))")
    }
    
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        parameters: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?
    ) async throws -> T {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            session.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers
            )
            .validate()
            .responseData { response in
                
                switch response.result {
                    
                case .success(let data):
                    do {
                        if let data = response.data {
                            print("RAW RESPONSE",
                                  String(data: data, encoding: .utf8) ?? "nil")
                        }
                        
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: decoded)
                    }
                    catch let error as DecodingError {
                        
                        print("🔥 DECODING ERROR")
                        print(error.detailedDescription)
                        
                    }catch {
                        print("Error:\(error.localizedDescription)")
                        continuation.resume(
                            throwing: NetworkError.decodingError(error)
                        )
                    }
                    
                case .failure(let error):
                    self.handleError(response: response, error: error, continuation: continuation)
                }
            }
        }
    }
    
    
    func handleError<T>(
        response: AFDataResponse<Data>,
        error: AFError,
        continuation: CheckedContinuation<T, Error>
    ) {
        
        let statusCode = response.response?.statusCode
        
        if statusCode == 401 {
            SessionReset.clearAndNotifyLogout()
            continuation.resume(throwing: NetworkError.serverError(401))
            return
        }
        
        if let data = response.data,
           let body = String(data: data, encoding: .utf8),
           !body.isEmpty {
            print("RAW ERROR RESPONSE:", body)
        }
        
        // Try decode API error
        if let data = response.data,
           let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
            continuation.resume(throwing: NetworkError.apiError(apiError))
            return
        }
        
        if let code = statusCode {
            continuation.resume(throwing: NetworkError.serverError(code))
        } else if (error as NSError).code == NSURLErrorNotConnectedToInternet {
            continuation.resume(throwing: NetworkError.noInternet)
        } else {
            continuation.resume(throwing: NetworkError.unknown(error))
        }
    }
    
}


extension Error {
    var readableMessage: String {
        if let networkError = self as? NetworkError {
            return networkError.errorDescription ?? "Something went wrong"
        }
        return localizedDescription
    }
}
extension DecodingError {
    
    var detailedDescription: String {
        switch self {
            
        case .typeMismatch(let type, let context):
            return """
            ❌ Type Mismatch
            Expected Type: \(type)
            CodingPath: \(context.codingPath.map{$0.stringValue}.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            """
            
        case .valueNotFound(let type, let context):
            return """
            ❌ Value Not Found
            Missing Type: \(type)
            CodingPath: \(context.codingPath.map{$0.stringValue}.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            """
            
        case .keyNotFound(let key, let context):
            return """
            ❌ Key Not Found
            Missing Key: \(key.stringValue)
            CodingPath: \(context.codingPath.map{$0.stringValue}.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            """
            
        case .dataCorrupted(let context):
            return """
            ❌ Data Corrupted
            CodingPath: \(context.codingPath.map{$0.stringValue}.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            """
            
        @unknown default:
            return "Unknown Decoding Error"
        }
    }
}
