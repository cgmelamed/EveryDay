//
//  LoadingView.swift
//  EveryDay
//
//  Created by Chris Melamed on 4/6/24.
//

import Foundation
import SwiftUI

import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? .black : .white)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("LoadingImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                
//                Text("My App")
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
            }
        }
    }
}
