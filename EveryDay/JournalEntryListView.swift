//
//  JournalEntryListView.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/22/24.
//

import SwiftUI
import Foundation

struct JournalEntryListView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showSettings = false
    @State private var selectedTag: String?
    @State private var searchText = ""
    @ObservedObject var viewModel: JournalViewModel
    @Binding var appMode: AppMode // Add this binding
    
    var filteredEntries: [JournalEntry] {
        if let selectedTag = selectedTag {
            return viewModel.entries.filter { $0.tags.contains(selectedTag) }
        } else {
            return viewModel.entries.filter { entry in
                searchText.isEmpty ||
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(groupedEntries.sorted(by: { $0.key > $1.key }), id: \.key) { dateInterval, entries in
                        Section(header:
                                    HStack {
                            Text(dateInterval)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                            .padding(.horizontal, 4)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                        ) {
                            ForEach(entries.sorted(by: { $0.date > $1.date })) { entry in
                                EntryRowView(entry: entry, viewModel: viewModel)
                                    .onTapGesture {
                                        buttonPressed()
                                        viewModel.setCurrentEntry(entry)
                                        presentationMode.wrappedValue.dismiss()
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            
        }
        .navigationTitle("Entries")
        .navigationBarTitleDisplayMode(.inline) // Ensures title is in the smaller, inline format
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("\(viewModel.entries.count) entries")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.leading, 4)
                    Spacer() // Ensures the title is left-aligned
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    buttonPressed()
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                }.foregroundColor(.primary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            print("JournalEntryListView appeared")
            viewModel.updateEntryTitle()
            viewModel.loadEntries()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .overlay(
            HStack {
                Button(action: {
                    buttonPressed()
                    viewModel.currentEntry = JournalEntry(content: "")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(width: 56, height: 56)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                
                Button(action: {
                    buttonPressed()
                    appMode = .chat // Set the app mode to chat
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(width: 56, height: 56)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.leading, 8) // Add spacing between the buttons
            }
                .padding(.bottom, 20),
            alignment: .bottom
        )
    }
    
    
    
    
    struct EntryRowView: View {
        let entry: JournalEntry
        @ObservedObject var viewModel: JournalViewModel
        
        var body: some View {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.entryLoadingStates[entry.id] == true {
                        ProgressView()
                    } else {
                        Text(entry.title)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Text(entry.date, style: .date)
                        .font(.subheadline)
                }
                
                
                ZStack(alignment: .trailing) {
                    
                    HStack(spacing: 8) {
                        let mediaCount = entry.photoFileNames.count + entry.videoFileNames.count
                        ForEach(0..<min(3, mediaCount), id: \.self) { index in
                            if index < entry.photoFileNames.count {
                                if let uiImage = CustomFileManager.shared.loadPhoto(withFileName: entry.photoFileNames[index]) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)
                                }
                            } else {
                                let videoIndex = index - entry.photoFileNames.count
                                if let videoURL = CustomFileManager.shared.loadVideo(withFileName: entry.videoFileNames[videoIndex]) {
                                    EntryThumbnailView(videoURL: videoURL, size: 50)
                                }
                            }
                        }
                        
                        .offset(x: mediaCount > 3 ? 58 : 0)
                        
                        if mediaCount > 3 {
                            ZStack {
                                Color.black.opacity(0.4)
                                
                                Text("+\(mediaCount - 3)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
            )
            .foregroundColor(.primary)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    viewModel.deleteEntry(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    func buttonPressed() {
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let reversedIndex = viewModel.entries.count - 1 - index
        viewModel.entries.remove(at: reversedIndex)
        CustomFileManager.shared.saveEntries(viewModel.entries)
    }
    
    private func filterByTag(_ tag: String) {
        selectedTag = selectedTag == tag ? nil : tag
    }
    var groupedEntries: [String: [JournalEntry]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let pastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        
        var groupedEntries: [String: [JournalEntry]] = [:]
        
        for entry in filteredEntries {
            if calendar.isDateInToday(entry.date) {
                groupedEntries["Today", default: []].append(entry)
            } else if entry.date >= pastWeek {
                groupedEntries["This Week", default: []].append(entry)
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM yyyy"
                let monthYear = dateFormatter.string(from: entry.date)
                groupedEntries[monthYear, default: []].append(entry)
            }
        }
        
        return groupedEntries
    }
}

struct EntryThumbnailView: View {
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
            } else {
                Color.gray
                    .frame(width: size, height: size)
                    .cornerRadius(8)
            }
        }
    }
}
