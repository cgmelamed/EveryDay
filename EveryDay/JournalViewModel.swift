//
//  JournalViewModel.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/22/24.
//
import Foundation
import LocalAuthentication
import UserNotifications
import UIKit
import MapKit
import Speech
import Combine

class JournalViewModel: ObservableObject, Hashable, Equatable {
    @Published var entries: [JournalEntry] = []
    @Published var currentEntry: JournalEntry = JournalEntry(content: "")
    @Published var initialContentLength: Int = 0
    @Published var useFaceID = true {
        didSet {
            UserDefaults.standard.set(useFaceID, forKey: "useFaceID")
        }
    }
    
    @Published var isUnlocked = false
    @Published var locationManager = LocationManager()
    @Published var speechRecognizer = SpeechRecognizer()
    @Published var isTitleGenerating = false
    @Published var entryLoadingStates: [UUID: Bool] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    enum AppearanceOption: String, CaseIterable {
        case light
        case dark
        case system
    }
    
    @Published var appearanceOption: AppearanceOption = .system {
        didSet {
            UserDefaults.standard.set(appearanceOption.rawValue, forKey: "AppearanceOption")
        }
    }
    
    enum FontSizeOption: String, CaseIterable {
        case small
        case medium
        case large
    }
    
    @Published var fontSizeOption: FontSizeOption = .small {
        didSet {
            UserDefaults.standard.set(fontSizeOption.rawValue, forKey: "FontSizeOption")
        }
    }
    
    @Published var notificationsEnabled = false {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            
            if notificationsEnabled {
                NotificationManager.shared.scheduleNotification(at: notificationTime, interval: notificationInterval)
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    @Published var notificationTime = Date() {
        didSet {
            UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
            
            if notificationsEnabled {
                NotificationManager.shared.scheduleNotification(at: notificationTime, interval: notificationInterval)
            }
        }
    }
    
    @Published var notificationInterval = "daily" {
        didSet {
            UserDefaults.standard.set(notificationInterval, forKey: "notificationInterval")
            
            if notificationsEnabled {
                NotificationManager.shared.scheduleNotification(at: notificationTime, interval: notificationInterval)
            }
        }
    }
    
    var fontSize: CGFloat {
        switch fontSizeOption {
        case .small:
            return 16
        case .medium:
            return 20
        case .large:
            return 24
        }
    }
    
    init() {
        loadEntries()
        checkCurrentDayEntry()
        initialContentLength = currentEntry.content.count
        print("Initial content length of the default entry: \(initialContentLength)")
        useFaceID = UserDefaults.standard.bool(forKey: "useFaceID")
        
        if let savedAppearanceOption = UserDefaults.standard.string(forKey: "AppearanceOption"),
           let appearanceOption = AppearanceOption(rawValue: savedAppearanceOption) {
            self.appearanceOption = appearanceOption
        }
        
        if let savedFontSizeOption = UserDefaults.standard.string(forKey: "FontSizeOption"),
           let fontSizeOption = FontSizeOption(rawValue: savedFontSizeOption) {
            self.fontSizeOption = fontSizeOption
        }
        
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        if let savedNotificationTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            notificationTime = savedNotificationTime
        }
        
        if let savedNotificationInterval = UserDefaults.standard.string(forKey: "notificationInterval") {
            notificationInterval = savedNotificationInterval
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(entries)
        hasher.combine(currentEntry)
        hasher.combine(initialContentLength)
        hasher.combine(useFaceID)
        hasher.combine(isUnlocked)
        hasher.combine(appearanceOption)
        hasher.combine(fontSizeOption)
        hasher.combine(notificationsEnabled)
        hasher.combine(notificationTime)
        hasher.combine(notificationInterval)
    }
    
    static func == (lhs: JournalViewModel, rhs: JournalViewModel) -> Bool {
        return lhs.entries == rhs.entries &&
        lhs.currentEntry == rhs.currentEntry &&
        lhs.initialContentLength == rhs.initialContentLength &&
        lhs.useFaceID == rhs.useFaceID &&
        lhs.isUnlocked == rhs.isUnlocked &&
        lhs.appearanceOption == rhs.appearanceOption &&
        lhs.fontSizeOption == rhs.fontSizeOption &&
        lhs.notificationsEnabled == rhs.notificationsEnabled &&
        lhs.notificationTime == rhs.notificationTime &&
        lhs.notificationInterval == rhs.notificationInterval
    }
    
    func checkCurrentDayEntry() {
        let currentDate = Date()
        if let existingEntry = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }) {
            setCurrentEntry(existingEntry)
        } else {
            let newEntry = JournalEntry(content: "")
            setCurrentEntry(newEntry)
        }
    }
    
    func saveEntry() {
        // Check if the entry has any content, photos, or videos
        if currentEntry.content.isEmpty && currentEntry.photoFileNames.isEmpty && currentEntry.videoFileNames.isEmpty {
            // Don't save empty entries
            return
        }
        
        // Save video file names
        for videoFileName in currentEntry.videoFileNames {
            if CustomFileManager.shared.loadVideo(withFileName: videoFileName) == nil {
                currentEntry.videoFileNames.removeAll(where: { $0 == videoFileName })
            }
        }
        
        if let index = entries.firstIndex(where: { $0.id == currentEntry.id }) {
            // Entry already exists, update it
            let previousContent = entries[index].content
            let contentDifference = currentEntry.content.count - previousContent.count
            
            entries[index] = currentEntry
            CustomFileManager.shared.saveEntry(currentEntry)
            
            if currentEntry.content.isEmpty && (!currentEntry.photoFileNames.isEmpty || !currentEntry.videoFileNames.isEmpty) {
                // If the entry has no text and only contains photos/videos, set the title to "Untitled"
                currentEntry.title = "Untitled"
                entries[index] = currentEntry
                CustomFileManager.shared.saveEntry(currentEntry)
            } else if currentEntry.content.count >= 25 && contentDifference >= 25 {
                // Entry is long enough and has been modified significantly, generate title and tags
                generateTitle(for: currentEntry, content: currentEntry.content) { title, tags in
                    DispatchQueue.main.async {
                        self.currentEntry.title = title
                        self.currentEntry.tags = tags
                        self.entries[index] = self.currentEntry
                        CustomFileManager.shared.saveEntry(self.currentEntry)
                        print("Updated existing entry with generated title: \(self.currentEntry.title) and tags: \(self.currentEntry.tags)")
                    }
                }
            } else {
                // Set default title for short entries
                currentEntry.title = getFirstLine(content: currentEntry.content)
                entries[index] = currentEntry
                CustomFileManager.shared.saveEntry(currentEntry)
            }
        } else {
            // New entry
            if currentEntry.content.isEmpty && (!currentEntry.photoFileNames.isEmpty || !currentEntry.videoFileNames.isEmpty) {
                // If the entry has no text and only contains photos/videos, set the title to "Untitled"
                currentEntry.title = "Untitled"
                entries.append(currentEntry)
                CustomFileManager.shared.saveEntry(currentEntry)
            } else if currentEntry.content.count >= 25 {
                // Entry is long enough, generate title and tags
                generateTitle(for: currentEntry, content: currentEntry.content) { title, tags in
                    DispatchQueue.main.async {
                        self.currentEntry.title = title
                        self.currentEntry.tags = tags
                        self.entries.append(self.currentEntry)
                        CustomFileManager.shared.saveEntry(self.currentEntry)
                        print("Saved new entry with generated title: \(self.currentEntry.title) and tags: \(self.currentEntry.tags)")
                    }
                }
            } else {
                // Set default title for short entries
                currentEntry.title = getFirstLine(content: currentEntry.content)
                entries.append(currentEntry)
                CustomFileManager.shared.saveEntry(currentEntry)
            }
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries.remove(at: index)
            CustomFileManager.shared.saveEntry(entry)
            CustomFileManager.shared.deletePhotos(for: entry)
            CustomFileManager.shared.deleteVideos(for: entry)
        }
    }
    func generateTitle(for entry: JournalEntry, content: String, completion: @escaping (String, [String]) -> Void) {
        print("Generating title and tags for content: \(content)")
        
        entryLoadingStates[entry.id] = true // Set the loading state for the specific entry
        
        APIClient.generateTitle(content: content) { result in
            switch result {
            case .success(let title):
                print("Generated title: \(title)")
                
                APIClient.generateTags(content: content) { result in
                    switch result {
                    case .success(let tags):
                        print("Generated tags: \(tags)")
                        DispatchQueue.main.async {
                            self.entryLoadingStates[entry.id] = false // Set the loading state for the specific entry
                            completion(title, tags)
                        }
                    case .failure(let error):
                        print("Error generating tags: \(error)")
                        DispatchQueue.main.async {
                            self.entryLoadingStates[entry.id] = false // Set the loading state for the specific entry
                            completion(title, [])
                        }
                    }
                }
                
            case .failure(let error):
                print("Error generating title: \(error)")
                DispatchQueue.main.async {
                    self.entryLoadingStates[entry.id] = false // Set the loading state for the specific entry
                    completion("", [])
                }
            }
        }
    }
    
    func getFirstLine(content: String) -> String {
        if content.count <= 50 {
            return content
        } else {
            guard let firstLine = content.components(separatedBy: "\n").first else {
                return ""
            }
            return firstLine
        }
    }
    
    func setCurrentEntry(_ entry: JournalEntry) {
        currentEntry = entry
        initialContentLength = entry.content.count
        print("Initial content length: \(initialContentLength)")
    }
    
    func updateEntryTitle() {
        print("Updating entry title...")
        
        if let index = entries.firstIndex(where: { $0.id == currentEntry.id }) {
            print("Found entry at index: \(index)")
            
            let contentDifference = currentEntry.content.count - initialContentLength
            
            print("Initial content length: \(initialContentLength)")
            print("Current content length: \(currentEntry.content.count)")
            print("Content difference: \(contentDifference)")
            
            if contentDifference != 0 {
                if currentEntry.content.count > 50 {
                    print("Entry is longer than 50 characters, generating Claude title...")
                    
                    generateTitle(for: currentEntry, content: currentEntry.content) { title, tags in
                        DispatchQueue.main.async {
                            self.currentEntry.title = title
                            self.currentEntry.tags = tags
                            self.entries[index] = self.currentEntry
                            CustomFileManager.shared.saveEntry(self.currentEntry)
                            print("Updated title: \(self.currentEntry.title) and tags: \(self.currentEntry.tags)")
                        }
                    }
                } else {
                    print("Entry is 50 characters or less, keeping the existing title.")
                }
            } else {
                print("Content has not changed, keeping the existing title.")
            }
        } else {
            print("Entry not found in the entries array.")
        }
    }
    
    func addPhotoToCurrentEntry(_ photo: UIImage) -> Bool {
        if let photoData = photo.jpegData(compressionQuality: 0.8) {
            let fileName = UUID().uuidString + ".jpg"
            if CustomFileManager.shared.savePhoto(photoData, withFileName: fileName) {
                currentEntry.photoFileNames.append(fileName)
                return true
            }
        }
        return false
    }
    
    func loadEntries() {
        entries = CustomFileManager.shared.loadEntries()
    }
    
    
    
    func getLocationDescription(from location: CLLocation?) -> String? {
        guard let location = location else { return nil }
        
        let geocoder = CLGeocoder()
        var locationDescription: String?
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                if let city = placemark.locality, let state = placemark.administrativeArea {
                    locationDescription = "\(city), \(state)"
                } else if let country = placemark.country {
                    locationDescription = country
                }
            }
        }
        
        return locationDescription
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock your journal"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        print("Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Biometric authentication not available")
            
            DispatchQueue.main.async {
                self.isUnlocked = true
            }
        }
    }
    
    
    
    func transcribeMedia(from url: URL) {
        Task {
            do {
                await MainActor.run {
                    speechRecognizer.transcript = "" // Clear the previous transcription
                }
                
                try await speechRecognizer.transcribeAudio(from: url)
                
                // Wait for a short duration to allow the transcription to complete
                try await Task.sleep(nanoseconds: 1_000_000_000) // Adjust the duration as needed
                
                let transcription = await speechRecognizer.transcript
                await MainActor.run {
                    if !self.currentEntry.content.isEmpty {
                        self.currentEntry.content += "\n" // Add some spacing before the transcription
                    }
                    self.currentEntry.content += transcription
                    saveEntry()
                }
            } catch {
                print("Transcription error: \(error.localizedDescription)")
            }
        }
    }
    
}
