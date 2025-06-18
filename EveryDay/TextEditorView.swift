//
//  TextEditorView.swift
//  EveryDay
//
//  Created by Chris Melamed on 2/21/24.
//

import SwiftUI
#if canImport(JournalingSuggestions)
import JournalingSuggestions
#endif

struct TextEditorView: View {
    var onChatSelect: () -> Void
    @Binding var text: String
    var fontSize: CGFloat
    var placeholderText: String
    var onImagePickerSelect: () -> Void
    var onCameraSelect: () -> Void
    var onSuggestionSelect: (Any) -> Void
    @Binding var suggestionPhotos: [Any]
    var appMode: AppMode
    @Binding var suggestionTitle: String?
    @Binding var showSuggestionsPicker: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $text)
                .font(.system(size: fontSize))
                .padding(.horizontal, 12)
                .padding(.bottom, 40)
                .overlay(
                    Group {
                        if text.isEmpty {
                            Text(placeholderText)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
            
            HStack {
                Button(action: {
                    buttonPressed()
                    onChatSelect()
                }) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    buttonPressed()
                    showSuggestionsPicker = true
                }) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    buttonPressed()
                    onImagePickerSelect()
                }) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    buttonPressed()
                    onCameraSelect()
                }) {
                    Image(systemName: "camera")
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 8)
            .padding(.trailing, 16)
        }
    }
    
    private func buttonPressed() {
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
    }
}