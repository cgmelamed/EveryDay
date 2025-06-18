////
////  Styles.swift
////  EveryDay
////
////  Created by Chris Melamed on 4/1/24.
////
//
//import Foundation
//import SwiftUI
//
//// MARK: - Font Styles
//
//struct CustomHeadlineStyle: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .font(.system(size: 24, weight: .bold, design: .default))
//    }
//}
//
//struct CustomSubheadlineStyle: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .font(.system(size: 18, weight: .semibold, design: .default))
//    }
//}
//
//// MARK: - Corner Radii
//
//struct CornerRadiusStyle: ViewModifier {
//    let radius: CGFloat
//    
//    func body(content: Content) -> some View {
//        content
//            .cornerRadius(radius)
//    }
//}
//
//// MARK: - Spacing
//
//struct SpacingStyle: ViewModifier {
//    let spacing: CGFloat
//    
//    func body(content: Content) -> some View {
//        content
//            .padding(.all, spacing)
//    }
//}
//
//// MARK: - Colors
//
//extension Color {
//    static let primaryColor = Color("PrimaryColor")
//    static let secondaryColor = Color("SecondaryColor")
//    // Add more custom colors as needed
//}
//
//// MARK: - View Extension
//
//extension View {
//    func customHeadline() -> some View {
//        self.modifier(CustomHeadlineStyle())
//    }
//    
//    func customSubheadline() -> some View {
//        self.modifier(CustomSubheadlineStyle())
//    }
//    
//    func cornerRadius(_ radius: CGFloat) -> some View {
//        self.modifier(CornerRadiusStyle(radius: radius))
//    }
//    
//    func customSpacing(_ spacing: CGFloat) -> some View {
//        self.modifier(SpacingStyle(spacing: spacing))
//    }
//}
