//
//  SettingsView.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/22/24.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Security")) {
                    Toggle("Use Face ID", isOn: $viewModel.useFaceID)
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $viewModel.appearanceOption) {
                        Text("Light").tag(JournalViewModel.AppearanceOption.light)
                        Text("Dark").tag(JournalViewModel.AppearanceOption.dark)
                        Text("System").tag(JournalViewModel.AppearanceOption.system)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Font Size", selection: $viewModel.fontSizeOption) {
                        Text("Small").tag(JournalViewModel.FontSizeOption.small)
                        Text("Medium").tag(JournalViewModel.FontSizeOption.medium)
                        Text("Large").tag(JournalViewModel.FontSizeOption.large)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    
                    if viewModel.notificationsEnabled {
                        DatePicker("Notification Time", selection: $viewModel.notificationTime, displayedComponents: .hourAndMinute)
                        
                        Picker("Frequency", selection: $viewModel.notificationInterval) {
                            Text("Daily").tag("daily")
                            Text("Weekly").tag("weekly")
                            Text("Monthly").tag("monthly")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}