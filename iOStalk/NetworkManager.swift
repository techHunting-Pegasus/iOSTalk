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
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}





final class RetryInterceptor: RequestInterceptor {
    
    private let retryLimit = 4
    
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard request.retryCount < retryLimit else {
            completion(.doNotRetry)
            return
        }
        
        let nsError = error as NSError
        print(nsError.localizedDescription, "kejhbviebv")
        // Retry only network / TLS errors
        if nsError.domain == NSURLErrorDomain {
            let delay = pow(2.0, Double(request.retryCount)) // 1s, 2s, 4s, 8s
            
            print("🔁 Retry \(request.retryCount + 1) after \(delay)s")
            completion(.retryWithDelay(delay))
        } else {
            completion(.retry)
        }
    }
}




final class NetworkManager {
    
    static let shared = NetworkManager()
    private init() {}
    
    private let session: Session = {
        
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true

        
        
        return Session(
            configuration: configuration,
            interceptor: RetryInterceptor() // ✅ only this
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
            
            print("🚀 REQUEST STARTED:", url.absoluteString)
            
            session.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers
            )
            .responseData { response in
                
                print("RESPONSE RECEIVED")
                
                switch response.result {
                    
                case .success(let data):
                    
                    print("RAW RESPONSE:",
                          String(data: data, encoding: .utf8) ?? "nil")
                    
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: decoded)
                    }
                    catch {
                        print("DECODING ERROR:", error)
                        continuation.resume(
                            throwing: NetworkError.decodingError(error)
                        )
                    }
                    
                case .failure(let error):
                    print("REQUEST FAILED:", error.localizedDescription)
                    
                    continuation.resume(
                        throwing: NetworkError.unknown(error)
                    )
                }
            }
        }
    }
//    func request<T: Decodable>(
//        url: URL,
//        method: HTTPMethod,
//        parameters: Parameters?,
//        encoding: ParameterEncoding,
//        headers: HTTPHeaders?
//    ) async throws -> T {
//        
//        return try await withCheckedThrowingContinuation { continuation in
//            
//            session.request(
//                url,
//                method: method,
//                parameters: parameters,
//                encoding: encoding,
//                headers: headers
//            )
//            .validate()
//            .responseData { response in
//                
//                switch response.result {
//                    
//                case .success(let data):
//                    do {
//                        if let data = response.data {
//                            print("RAW RESPONSE",
//                                  String(data: data, encoding: .utf8) ?? "nil")
//                        }
//                        
//                        let decoded = try JSONDecoder().decode(T.self, from: data)
//                        continuation.resume(returning: decoded)
//                    }
//                    catch let error as DecodingError {
//                        
//                        print("🔥 DECODING ERROR")
//                        print(error.detailedDescription)
//                        
//                    }catch {
//                        print("Error:\(error.localizedDescription)")
//                        continuation.resume(
//                            throwing: NetworkError.decodingError(error)
//                        )
//                    }
//                    
//                case .failure(let error):
//                    self.handleError(response: response, error: error, continuation: continuation)
//                }
//            }
//        }
//    }
//    
    
    func handleError<T>(
        response: AFDataResponse<Data>,
        error: AFError,
        continuation: CheckedContinuation<T, Error>
    ) {
        
        let statusCode = response.response?.statusCode
        
        if statusCode == 401 {
            
            continuation.resume(throwing: NetworkError.serverError(401))
            return
        }
        
        if let data = response.data,
           let body = String(data: data, encoding: .utf8),
           !body.isEmpty {
            print("RAW ERROR RESPONSE:", body)
        }
        
//        // Try decode API error
//        if let data = response.data,
//           let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
//            continuation.resume(throwing: NetworkError.apiError(apiError))
//            return
//        }
        
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
