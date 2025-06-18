//
//  ChatHistory.swift
//  EveryDay
//
//  Created by Chris Melamed on 4/10/24.
//

import Foundation

struct ChatHistory: Codable {
    var messages: [Message]
    
    struct Message: Codable, Identifiable {
        let id = UUID()
        let text: String
        let isUserMessage: Bool
    }
}

extension CustomFileManager {
    var chatHistoryDirectory: URL {
        let directory = entriesDirectory.appendingPathComponent("ChatHistory")
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating chat history directory: \(error)")
            }
        }
        return directory
    }
    
    private var chatHistoryFileURL: URL {
        return chatHistoryDirectory.appendingPathComponent("chatHistory.json")
    }
    
    func saveChatHistory(_ chatHistory: ChatHistory) {
        do {
            let data = try JSONEncoder().encode(chatHistory)
            try data.write(to: chatHistoryFileURL)
        } catch {
            print("Error saving chat history: \(error)")
        }
    }
    
    func loadChatHistory() -> ChatHistory {
        do {
            let data = try Data(contentsOf: chatHistoryFileURL)
            let chatHistory = try JSONDecoder().decode(ChatHistory.self, from: data)
            return chatHistory
        } catch {
            print("Error loading chat history: \(error)")
            return ChatHistory(messages: [])
        }
    }
}
