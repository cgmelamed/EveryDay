//
//  NotificationManager.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/22/24.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func scheduleNotification(at time: Date, interval: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.createNotification(at: time, interval: interval)
            }
        }
    }
    
    private func createNotification(at time: Date, interval: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Journal"
        content.body = "Take a moment to reflect on your day"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger: UNNotificationTrigger
        
        switch interval {
        case "daily":
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case "weekly":
            var weeklyComponents = components
            weeklyComponents.weekday = calendar.component(.weekday, from: time)
            trigger = UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)
        case "monthly":
            var monthlyComponents = components
            monthlyComponents.day = calendar.component(.day, from: time)
            trigger = UNCalendarNotificationTrigger(dateMatching: monthlyComponents, repeats: true)
        default:
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        
        let request = UNNotificationRequest(identifier: "journalReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}