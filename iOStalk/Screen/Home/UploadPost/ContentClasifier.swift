//
//  ContentClasifier.swift
//  reelsView
//
//  Created by Ishpreet Singh on 27/11/25.
//

import Foundation
import CoreML
import Vision
import UIKit
import AVFoundation
import VisionKit
import SensitiveContentAnalysis

class ContentClassifier {
    
    static let shared = ContentClassifier()
    
    private init() {}
    
    // MARK: Image Classification
    func classifyImage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion(nil)
            return
        }
        let model = MobileNetV2()
        
        // Load MLModel
        guard let model = try? VNCoreMLModel(for: model.model) else {
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                completion(nil)
                return
            }
            
            completion(topResult.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    // MARK: Video Classification (Frame-based)
    func classifyVideo(url: URL, completion: @escaping (String?) -> Void) {
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        // Take 1 frame every 2 seconds (or adjust)
        var predictions: [String] = []
        let frameInterval: Float64 = 5
        let times: [NSValue] = stride(from: 0, to: duration, by: frameInterval).map {
            NSValue(time: CMTimeMakeWithSeconds($0, preferredTimescale: 600))
        }
        
        let group = DispatchGroup()
        
        for time in times {
            group.enter()
            DispatchQueue.global().async {
                do {
                    let cgImage = try generator.copyCGImage(at: time.timeValue, actualTime: nil)
                    let uiImage = UIImage(cgImage: cgImage)
                    self.classifyImage(image: uiImage) { label in
                        if let label = label {
                            predictions.append(label)
                        }
                        group.leave()
                    }
                } catch {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // Return most frequent label
            let finalLabel = predictions.mostFrequent()
            completion(finalLabel)
        }
    }
    
  
}

// Extension to get most frequent label
extension Array where Element: Hashable {
    func mostFrequent() -> Element? {
        let counts = self.reduce(into: [:]) { counts, item in
            counts[item, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
}


 class VisionObjectDetector {

    static let shared = VisionObjectDetector()

    private init() {}
     
     
     
     
      let model = Nudity()
     
     let size = CGSize(width: 224, height: 224)
     
      typealias CompletionHandler = (_ error:Error?,_ confidence:Double?) -> Void
     
     func checkImageNudity(image: UIImage) async throws -> Double {

         guard let buffer = image.resize(to: size)?.pixelBuffer() else {
             throw NSError(domain: "Image processing failed", code: 101)
         }

         let result = try model.prediction(data: buffer)
         let nsfwScore = result.prob["NSFW"] ?? 0

         return nsfwScore * 100
     }
     func checkVideoNudity(
            videoURL: URL,
            frameInterval: Double = 1.0
        ) async throws -> Bool {

            let asset = AVAsset(url: videoURL)
            let duration = try await asset.load(.duration)
            let totalSeconds = Int(CMTimeGetSeconds(duration))

            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero

            for second in stride(from: 0, to: totalSeconds, by: Int(frameInterval)) {

                let time = CMTime(seconds: Double(second), preferredTimescale: 600)

                do {
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    let frameImage = UIImage(cgImage: cgImage)
                    
                    let confidence = try await checkImageNudity(image: frameImage)
                    print(confidence, "confidence")
                    if confidence >= 70 {
                        return true   // 🚫 NSFW VIDEO
                    }
                    
                } catch {
                    continue
                }
            }

            return false // ✅ SFW VIDEO
        }
}



