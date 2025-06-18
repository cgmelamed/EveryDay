//
//  EntryDetailView.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/22/24.
//

import SwiftUI

struct EntryDetailView: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if let location = entry.location {
                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                Text(entry.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                if !entry.photoFileNames.isEmpty || !entry.videoFileNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(entry.photoFileNames, id: \.self) { fileName in
                                if let uiImage = CustomFileManager.shared.loadPhoto(withFileName: fileName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(12)
                                }
                            }
                            
                            ForEach(entry.videoFileNames, id: \.self) { fileName in
                                if let videoURL = CustomFileManager.shared.loadVideo(withFileName: fileName) {
                                    ThumbnailView(videoURL: videoURL, size: 200)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Text(entry.content)
                    .font(.body)
                    .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.setCurrentEntry(entry)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Edit")
                }
            }
        }
    }
}