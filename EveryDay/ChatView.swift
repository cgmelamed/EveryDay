//
//  ChatView.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/30/24.
//

import Foundation
import SwiftUI

struct ChatView: View {
    @Binding var appMode: AppMode
    @State private var messages: [ChatHistory.Message] = []
    @State private var inputText: String = ""
    @State private var selectedPresetIndex = 0
    
    var therapistPresets: [TherapistPreset] {
        TherapistPresets.shared.presets
    }
    
    var selectedPreset: TherapistPreset {
        therapistPresets[selectedPresetIndex]
    }

    
    var body: some View {
        VStack {
            
            Picker("Therapist Preset", selection: $selectedPresetIndex) {
                ForEach(therapistPresets.indices, id: \.self) { index in
                    Text(therapistPresets[index].name)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            ScrollViewReader { proxy in
                            ScrollView {
                                ForEach(messages) { message in
                                    MessageView(message: message)
                                }
                            }
                            .onChange(of: messages.count) { _ in
                                scrollToBottom(proxy: proxy)
                            }
                        }
            
            HStack {
                TextField("What's on your mind?", text: $inputText)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 8)
                    .textFieldStyle(PlainTextFieldStyle())
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.primary)
                    .accentColor(.primary)
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24)) // Adjust the size as needed
                }
            }
            .padding()
            .foregroundColor(.primary)
        }
        
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .onAppear {
                    loadChatHistory()
                }
                .onDisappear {
                    saveChatHistory()
                }
    }
    
    private var backButton: some View {
        Button(action: {
            appMode = .journal
        }) {
            HStack {
                Image(systemName: "chevron.left")
            }
            .foregroundColor(.primary)
        }
    }
    
    private func sendMessage() {
        let userMessage = ChatHistory.Message(text: inputText, isUserMessage: true)
        messages.append(userMessage)
        saveChatHistory()
        inputText = ""
        
        let systemPrompt = selectedPreset.systemPrompt
        var prompt = "\n\nSystem: \(systemPrompt)\n\n"
        
        // Append the chat history to the prompt
        for message in messages {
            prompt += message.isUserMessage ? "Human: \(message.text)\n" : "Assistant: \(message.text)\n"
        }
        
        prompt += "Human: \(userMessage.text)\n\nAssistant:"
        
        APIClient.sendMessageToAssistant(message: prompt, systemPrompt: systemPrompt) { result in
            switch result {
            case .success(let responseText):
                let assistantMessage = ChatHistory.Message(text: responseText, isUserMessage: false)
                DispatchQueue.main.async {
                    messages.append(assistantMessage)
                    saveChatHistory()
                }
            case .failure(let error):
                print("Error sending message to assistant: \(error.localizedDescription)")
            }
        }
    }
        
        private func loadChatHistory() {
            let chatHistory = CustomFileManager.shared.loadChatHistory()
            messages = chatHistory.messages
        }
        
        private func saveChatHistory() {
            let chatHistory = ChatHistory(messages: messages)
            CustomFileManager.shared.saveChatHistory(chatHistory)
        }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = messages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    }

struct MessageView: View {
    let message: ChatHistory.Message
    
    var body: some View {
        HStack {
            if message.isUserMessage {
                Spacer()
                Text(message.text)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 8)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(message.text)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}
