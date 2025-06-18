//
//  TranscriptionSheet.swift
//  EveryDay
//
//  Created by Chris Melamed on 4/2/24.
//

import Foundation
import SwiftUI

struct TranscriptionSheet: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcribe video?")
                .font(.headline)
                .padding(.top, 32)
                .padding(.leading, 16)
            
            Text("The transcription will be added to your journal entry.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Skip")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                }
                
                Button(action: {
                    guard let videoFileName = viewModel.currentEntry.videoFileNames.last,
                          let videoURL = CustomFileManager.shared.loadVideo(withFileName: videoFileName) else {
                        // No video file names available or video URL not found
                        presentationMode.wrappedValue.dismiss()
                        return
                    }
                    viewModel.transcribeMedia(from: videoURL)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Transcribe")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding([.top, .bottom], 12)
                        .background(Color.primary)
                        .cornerRadius(4)
                }
            }            .padding()
        }
        .padding()
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.2)])
        .presentationDragIndicator(.hidden)
        
    }
}
