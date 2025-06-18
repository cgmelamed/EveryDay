//
//  CustomVideoPlayer.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/29/24.
//

import Foundation
import AVKit
import SwiftUI
import Combine

struct CustomVideoPlayer: View {
    let videoURL: URL
    @State private var isPlaying = false
    @State private var showControls = false
    @State private var currentTime: CMTime = .zero
    @State private var duration: CMTime = .zero
    @State private var player = AVPlayer()
    @State private var scrubberValue: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onTapGesture {
                        withAnimation {
                            self.showControls.toggle()
                        }
                    }
                    .onAppear {
                        self.player = AVPlayer(url: videoURL)
                        self.player.play()
                        self.isPlaying = true
                        
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            self.isPlaying = false
                            self.player.seek(to: .zero)
                        }
                        
                        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: DispatchQueue.main) { time in
                            self.currentTime = time
                            self.duration = self.player.currentItem?.duration ?? .zero
                            self.scrubberValue = self.currentTime.seconds / self.duration.seconds
                        }
                    }
                
                if showControls {
                    HStack {
                        Text(formatDuration(currentTime))
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.leading)
                        
                        Slider(value: $scrubberValue, in: 0...1, onEditingChanged: { isEditing in
                            if isEditing {
                                self.player.pause()
                            } else {
                                let targetTime = CMTime(seconds: self.scrubberValue * self.duration.seconds, preferredTimescale: 600)
                                self.player.seek(to: targetTime)
                                if self.isPlaying {
                                    self.player.play()
                                }
                            }
                        })
                        .accentColor(.white)
                        .padding(.horizontal)
                        
                        Text(formatDuration(duration))
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.trailing)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            if self.isPlaying {
                                self.player.pause()
                                self.isPlaying = false
                            } else {
                                if self.player.currentTime() >= self.player.currentItem?.duration ?? .zero {
                                    self.player.seek(to: .zero)
                                }
                                self.player.play()
                                self.isPlaying = true
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom)
                }
            }
        }
        .onDisappear {
            self.player.pause()
        }
    }
    
    private func formatDuration(_ time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
