//
//  JournalEntry.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/22/24.
//

import Foundation

struct JournalEntry: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let date: Date
    var content: String
    var title: String
    var tags: [String]
    var photoFileNames: [String]
    var videoFileNames: [String] = []
    var location: String?
    var transcription: String?
    
    
    
    init(content: String, title: String = "", tags: [String] = [], photoFileNames: [String] = []) {
        id = UUID()
        date = Date()
        self.content = content
        self.title = title
        self.tags = tags
        self.photoFileNames = photoFileNames
    }
    
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        return lhs.id == rhs.id &&
            lhs.date == rhs.date &&
            lhs.content == rhs.content &&
            lhs.title == rhs.title &&
            lhs.tags == rhs.tags &&
            lhs.photoFileNames == rhs.photoFileNames
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(content)
        hasher.combine(title)
        hasher.combine(tags)
        hasher.combine(photoFileNames)
    }
}
