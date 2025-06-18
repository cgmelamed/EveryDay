//
//  FileManager.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/27/24.
//

// FileManager.swift

import UIKit
import Foundation

class CustomFileManager {
    static let shared = CustomFileManager()
    
    private let iCloudURL: URL? = {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }()
    
    let entriesDirectory: URL
    private let photosDirectory: URL
    private let videosDirectory: URL
    
    
    private init() {
        guard let iCloudURL = iCloudURL else {
            // Fallback to local documents directory if iCloud is not available
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            entriesDirectory = documentsDirectory.appendingPathComponent("Entries")
            photosDirectory = documentsDirectory.appendingPathComponent("Photos")
            videosDirectory = documentsDirectory.appendingPathComponent("Videos")
            createDirectories()
            return
        }
        
        entriesDirectory = iCloudURL.appendingPathComponent("Entries")
        photosDirectory = iCloudURL.appendingPathComponent("Photos")
        videosDirectory = iCloudURL.appendingPathComponent("Videos")
        createDirectories()
    }
    
    private func createDirectories() {
        let directories = [entriesDirectory, photosDirectory, videosDirectory]
        for directory in directories {
            if !Foundation.FileManager.default.fileExists(atPath: directory.path) {
                do {
                    try Foundation.FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Error creating directory \(directory): \(error)")
                }
            }
        }
    }
    
    func saveEntry(_ entry: JournalEntry) {
        let fileURL = entriesDirectory.appendingPathComponent(entry.id.uuidString + ".json")
        if let data = try? JSONEncoder().encode(entry) {
            try? data.write(to: fileURL)
        }
    }
    
    func loadEntries() -> [JournalEntry] {
        let fileURLs = try? Foundation.FileManager.default.contentsOfDirectory(at: entriesDirectory, includingPropertiesForKeys: nil, options: [])
        return fileURLs?.compactMap { fileURL in
            if let data = try? Data(contentsOf: fileURL),
               let entry = try? JSONDecoder().decode(JournalEntry.self, from: data) {
                return entry
            }
            return nil
        } ?? []
    }
    
    func savePhoto(_ photoData: Data, withFileName fileName: String) -> Bool {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        do {
            try photoData.write(to: fileURL)
            return true
        } catch {
            print("Failed to save photo: \(error)")
            return false
        }
    }
    
    func loadPhoto(withFileName fileName: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        if let data = try? Data(contentsOf: fileURL),
           let uiImage = UIImage(data: data) {
            return uiImage
        }
        
        return nil
    }
    
    func saveVideo(from url: URL, withFileName fileName: String) -> Bool {
        let fileURL = videosDirectory.appendingPathComponent(fileName)
        
        do {
            try Foundation.FileManager.default.copyItem(at: url, to: fileURL)
            print("Video saved successfully: \(fileName)")
            return true
        } catch {
            print("Failed to save video: \(error)")
            return false
        }
    }
    
    func loadVideo(withFileName fileName: String) -> URL? {
        let fileURL = videosDirectory.appendingPathComponent(fileName)
        let fileExists = Foundation.FileManager.default.fileExists(atPath: fileURL.path)
        return fileExists ? fileURL : nil
    }
    
    func saveEntries(_ entries: [JournalEntry]) {
        for entry in entries {
            let fileURL = entriesDirectory.appendingPathComponent(entry.id.uuidString + ".json")
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: fileURL)
            }
        }
    }
    
    func deletePhoto(withFileName fileName: String) {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        do {
            try Foundation.FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Error deleting photo: \(error.localizedDescription)")
        }
    }
    
    func deleteVideo(withFileName fileName: String) {
        let fileURL = videosDirectory.appendingPathComponent(fileName)
        
        do {
            try Foundation.FileManager.default.removeItem(at: fileURL)
            print("Video deleted successfully: \(fileName)")
        } catch {
            print("Error deleting video: \(error.localizedDescription)")
        }
    }
    
    func deletePhotos(for entry: JournalEntry) {
        for fileName in entry.photoFileNames {
            deletePhoto(withFileName: fileName)
        }
    }

    func deleteVideos(for entry: JournalEntry) {
        for fileName in entry.videoFileNames {
            deleteVideo(withFileName: fileName)
        }
    }
    
}

