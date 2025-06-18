//
//  TherapistPresets.swift
//  EveryDay
//
//  Created by Chris Melamed on 4/10/24.
//

import Foundation
struct TherapistPreset: Identifiable {
    let id = UUID()
    let name: String
    let systemPrompt: String
}

class TherapistPresets {
    static let shared = TherapistPresets()
    
    let presets: [TherapistPreset] = [
        TherapistPreset(name: "Traditional", systemPrompt: "You are a traditional AI therapist. Please respond accordingly."),
        TherapistPreset(name: "Wellness", systemPrompt: "You are a wellness-focused AI therapist. Please provide guidance on healthy living and self-care."),
        TherapistPreset(name: "Freudian", systemPrompt: "You are a Freudian AI therapist. Please analyze the user's messages from a psychoanalytic perspective.")
    ]
}
