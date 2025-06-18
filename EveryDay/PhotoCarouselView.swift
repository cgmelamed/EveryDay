//
//  PhotoCarouselView.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/28/24.
//

import Foundation
import SwiftUI
import AVKit

struct PhotoCarouselView: View {
    @Binding var photoFileNames: [String]
    @Binding var videoFileNames: [String]
    @Binding var currentIndex: Int
    @EnvironmentObject var viewModel: JournalViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var savingState: SavingState = .none
    
    enum SavingState {
        case none
        case saving
        case saved
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(photoFileNames.indices, id: \.self) { index in
                    if let uiImage = CustomFileManager.shared.loadPhoto(withFileName: photoFileNames[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .edgesIgnoringSafeArea(.all)
                            .tag(index)
                    }
                }
                ForEach(videoFileNames.indices, id: \.self) { index in
                    if let videoURL = CustomFileManager.shared.loadVideo(withFileName: videoFileNames[index]) {
                        CustomVideoPlayer(videoURL: videoURL)
                            .edgesIgnoringSafeArea(.all)
                            .tag(photoFileNames.count + index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        saveMediaToCameraRoll()
                    }) {
                        switch savingState {
                        case .none:
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.gray)
                                .clipShape(Circle())
                        case .saving:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(12)
                                .background(Color.blue)
                                .clipShape(Circle())
                        case .saved:
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.gray)
                                .clipShape(Circle())
                        }
                    }
                    
                    Button(action: {
                        deleteMedia(at: currentIndex)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func saveMediaToCameraRoll() {
        savingState = .saving
        
        if currentIndex < photoFileNames.count {
            let photoFileName = photoFileNames[currentIndex]
            if let uiImage = CustomFileManager.shared.loadPhoto(withFileName: photoFileName) {
                let imageSaver = ImageSaver()
                imageSaver.writeToPhotoAlbum(image: uiImage) { result in
                    handleSaveResult(result)
                }
            }
        } else {
            let adjustedIndex = currentIndex - photoFileNames.count
            let videoFileName = videoFileNames[adjustedIndex]
            if let videoURL = CustomFileManager.shared.loadVideo(withFileName: videoFileName) {
                let videoSaver = VideoSaver()
                videoSaver.writeToPhotoAlbum(videoURL: videoURL) { result in
                    handleSaveResult(result)
                }
            }
        }
    }
    
    private func handleSaveResult(_ result: Result<Bool, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success:
                savingState = .saved
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    savingState = .none
                }
            case .failure:
                savingState = .none
                // Handle the error if needed
            }
        }
    }
    
    private func deleteMedia(at index: Int) {
        if index < photoFileNames.count {
            let fileName = photoFileNames.remove(at: index)
            CustomFileManager.shared.deletePhoto(withFileName: fileName)
        } else {
            let adjustedIndex = index - photoFileNames.count
            let fileName = videoFileNames.remove(at: adjustedIndex)
            CustomFileManager.shared.deleteVideo(withFileName: fileName)
        }
        
        // Save the entry after deleting a photo or video
        viewModel.saveEntry()
        
        if currentIndex >= photoFileNames.count + videoFileNames.count {
            currentIndex = max(0, photoFileNames.count + videoFileNames.count - 1)
        }
        
        if photoFileNames.isEmpty && videoFileNames.isEmpty {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ThumbnailView: View {
    let videoURL: URL
    let size: CGFloat
    
    var body: some View {
        ZStack {
            if let thumbnail = VideoThumbnailGenerator.generateThumbnail(for: videoURL) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .cornerRadius(8)
                
                Text(videoDuration(from: videoURL))
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            } else {
                Color.gray
                    .frame(width: size, height: size)
                    .cornerRadius(8)
            }
        }
    }
    
    private func videoDuration(from url: URL) -> String {
        let asset = AVAsset(url: url)
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)
        
        let minutes = Int(durationSeconds / 60)
        let seconds = Int(durationSeconds.truncatingRemainder(dividingBy: 60))
        
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage, completion: @escaping (Result<Bool, Error>) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
        
        objc_setAssociatedObject(self, &ImageSaverCompletionKey, completion, .OBJC_ASSOCIATION_COPY)
    }
    
    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let completion = objc_getAssociatedObject(self, &ImageSaverCompletionKey) as? (Result<Bool, Error>) -> Void {
            completion(error == nil ? .success(true) : .failure(error!))
        }
    }
}

private var ImageSaverCompletionKey: UInt8 = 0

class VideoSaver: NSObject {
    func writeToPhotoAlbum(videoURL: URL, completion: @escaping (Result<Bool, Error>) -> Void) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, self, #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
        
        objc_setAssociatedObject(self, &VideoSaverCompletionKey, completion, .OBJC_ASSOCIATION_COPY)
    }
    
    @objc private func saveCompleted(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let completion = objc_getAssociatedObject(self, &VideoSaverCompletionKey) as? (Result<Bool, Error>) -> Void {
            completion(error == nil ? .success(true) : .failure(error!))
        }
    }
}

private var VideoSaverCompletionKey: UInt8 = 0
