//
//  VideoThumbnailGenerator.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/28/24.
//

import Foundation
import AVFoundation
import UIKit

class VideoThumbnailGenerator {
    static func generateThumbnail(for videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}