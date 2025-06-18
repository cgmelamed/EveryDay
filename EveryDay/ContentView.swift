//
//  ContentView.swift
//  EveryDay
//
//  Created by Chris Melamed on 2/21/24.
//

import SwiftUI
#if canImport(JournalingSuggestions)
import JournalingSuggestions
#endif
import MapKit

enum AppMode {
    case journal
    case chat
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: JournalViewModel
    @State private var isShowingList = false
    @State private var showPhotoPreview = false
    @State private var previewedPhoto: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var currentLocation: CLLocation?
    @StateObject private var locationManager = LocationManager()
    @State private var locationDescription: String?
    @State private var showPhotoCarousel = false
    @State private var currentPhotoIndex = 0
    @State private var showMediaCarousel = false
    @State private var currentMediaIndex = 0
    @State private var showSuggestionsPicker = false
    @State private var suggestionPhotos: [Any] = []
    @State private var suggestionTitle: String? = nil
    @State private var appMode: AppMode = .journal
    @State private var showTranscriptionSheet = false
    
    
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                
                if appMode == .journal {
                    if let description = viewModel.currentEntry.location {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                            .padding(.bottom, 8)
                    } else {
                        Button(action: {
                            buttonPressed()
                            requestLocation()
                        }) {
                            Text("Add location")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                                .padding(.bottom, 8)
                        }
                    }
                }
                
                if appMode == .journal {
                    
                    if !viewModel.currentEntry.photoFileNames.isEmpty || !viewModel.currentEntry.videoFileNames.isEmpty {
                        mediaGrid
                            .sheet(isPresented: $showMediaCarousel) {
                                PhotoCarouselView(photoFileNames: $viewModel.currentEntry.photoFileNames, videoFileNames: $viewModel.currentEntry.videoFileNames, currentIndex: $currentMediaIndex)
                                    .environmentObject(viewModel)
                            }
                    }
                    
                    // Render the journal UI
                    TextEditorView(
                        onChatSelect: {
                            appMode = .chat
                        },
                        text: $viewModel.currentEntry.content,
                        fontSize: viewModel.fontSize,
                        placeholderText: "What's on your mind?",
                        onImagePickerSelect: {
                            showImagePicker = true
                        },
                        onCameraSelect: {
                            showCamera = true
                        },
                        onSuggestionSelect: { suggestion in
                            if #available(iOS 17.2, *) {
                                #if canImport(JournalingSuggestions)
                                if let journalSuggestion = suggestion as? JournalingSuggestion {
                                    suggestionTitle = journalSuggestion.title
                                    Task {
                                        suggestionPhotos = await journalSuggestion.content(forType: JournalingSuggestion.Photo.self)
                                    }
                                }
                                #endif
                            }
                        },
                        suggestionPhotos: $suggestionPhotos,
                        appMode: appMode,
                        suggestionTitle: $suggestionTitle,
                        showSuggestionsPicker: $showSuggestionsPicker
                        
                    )
                    .padding(.leading, 12)
                    .onChange(of: viewModel.currentEntry.content) { _ in
                        viewModel.saveEntry()
                    }
                    
                    
                } else {
                    // Render the chat UI
                    ChatView(appMode: $appMode)
                    
                }
                
                NavigationLink(value: viewModel) {
                    EmptyView()
                }
                .navigationDestination(isPresented: $isShowingList) {
                    JournalEntryListView(viewModel: viewModel, appMode: $appMode)
                }
            }
            .navigationTitle(appMode == .journal ? viewModel.currentEntry.date.formatted(date: .long, time: .omitted) : "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text(appMode == .journal ? viewModel.currentEntry.date.formatted(date: .long, time: .omitted) : "Chat")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        buttonPressed()
                        isShowingList = true
                    }) {
                        Text("Entries")
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            showImagePicker = false
        }) {
            ImagePicker(sourceType: .photoLibrary, onImageSelected: { image in
                addSelectedPhoto(image)
            }, onVideoSelected: { videoURL in
                addSelectedVideo(videoURL)
            })
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            showCamera = false
        }) {
            ImagePicker(sourceType: .camera, onImageSelected: { image in
                addSelectedPhoto(image)
            }, onVideoSelected: { videoURL in
                addSelectedVideo(videoURL)
            })
        }
        .sheet(isPresented: $showSuggestionsPicker) {
            if #available(iOS 17.2, *) {
                #if canImport(JournalingSuggestions)
                JournalingSuggestionsPicker {
                    Text("Show my personal events")
                } onCompletion: { suggestion in
                    suggestionTitle = suggestion.title
                    Task {
                        suggestionPhotos = await suggestion.content(forType: JournalingSuggestion.Photo.self)
                    }
                }
                #else
                Text("Journaling Suggestions not available")
                    .padding()
                #endif
            } else {
                Text("Journaling Suggestions requires iOS 17.2+")
                    .padding()
            }
        }
        
        .sheet(isPresented: $showTranscriptionSheet) {
            TranscriptionSheet(viewModel: viewModel)
                .cornerRadius(40)
        }
        
        
    }
    
    
    
    
    var mediaGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
            ForEach(viewModel.currentEntry.photoFileNames.indices, id: \.self) { index in
                if let uiImage = CustomFileManager.shared.loadPhoto(withFileName: viewModel.currentEntry.photoFileNames[index]) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .onTapGesture {
                            currentMediaIndex = index
                            showMediaCarousel = true
                        }
                }
            }
            ForEach(viewModel.currentEntry.videoFileNames.indices, id: \.self) { index in
                let videoFileName = viewModel.currentEntry.videoFileNames[index]
                
                if let videoURL = CustomFileManager.shared.loadVideo(withFileName: videoFileName) {
                    ThumbnailView(videoURL: videoURL, size: 80)
                        .onTapGesture {
                            currentMediaIndex = viewModel.currentEntry.photoFileNames.count + index
                            showMediaCarousel = true
                        }
                } else {
                    Color.gray
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
    
    func buttonPressed() {
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
    }
    
    func requestLocation() {
        print("Requesting location...")
        locationManager.requestLocation { description in
            if let description = description {
                print("Location description received: \(description)")
                DispatchQueue.main.async {
                    self.viewModel.currentEntry.location = description
                    self.viewModel.saveEntry()
                }
            } else {
                print("No location description received")
            }
        }
    }
    
    func openMapForLocation(_ location: CLLocation) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func getLocationDescription(from location: CLLocation) -> String {
        let geocoder = CLGeocoder()
        var locationDescription = "Unknown"
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                if let city = placemark.locality, let state = placemark.administrativeArea {
                    locationDescription = "\(city), \(state)"
                } else if let country = placemark.country {
                    locationDescription = country
                }
                
                DispatchQueue.main.async {
                    self.viewModel.currentEntry.location = locationDescription
                    self.viewModel.saveEntry()
                    
                }
            }
        }
        
        return locationDescription
    }
    
    
    
    private func addSelectedPhoto(_ photo: UIImage) {
        if viewModel.addPhotoToCurrentEntry(photo) {
            viewModel.saveEntry()
            // Photo added and entry saved successfully
        } else {
            // Handle the case when photo addition fails
            print("Failed to add photo to the entry")
        }
    }
    
    private func addSelectedVideo(_ videoURL: URL) {
        let fileName = UUID().uuidString + ".mov"
        if CustomFileManager.shared.saveVideo(from: videoURL, withFileName: fileName) {
            viewModel.currentEntry.videoFileNames.append(fileName)
            viewModel.saveEntry()
            print("Video added to the entry: \(fileName)")
            
            // Show the transcription sheet
            showTranscriptionSheet = true
        } else {
            print("Failed to add video to the entry")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(JournalViewModel())
}

struct PhotoPreviewView: View {
    let photo: UIImage
    
    var body: some View {
        Image(uiImage: photo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImageSelected: (UIImage) -> Void
    var onVideoSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        imagePicker.mediaTypes = ["public.image", "public.movie"]
        
        
        // Set the camera capture mode to photo or video based on the source type
        if sourceType == .camera {
            imagePicker.cameraCaptureMode = .photo
            imagePicker.allowsEditing = false
            
            // Set the desired photo and video quality
            imagePicker.videoQuality = .typeHigh
        }
        
        // Set the presentation style to fullscreen
        imagePicker.modalPresentationStyle = .fullScreen
        
        return imagePicker
    }
    
    
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, onVideoSelected: onVideoSelected)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImageSelected: (UIImage) -> Void
        var onVideoSelected: (URL) -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void, onVideoSelected: @escaping (URL) -> Void) {
            self.onImageSelected = onImageSelected
            self.onVideoSelected = onVideoSelected
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageSelected(image)
            } else if let videoURL = info[.mediaURL] as? URL {
                onVideoSelected(videoURL)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(JournalViewModel())
    }
}