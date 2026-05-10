import SwiftUI
import PhotosUI
extension UIImage: @retroactive Identifiable {
    public var id: Int {
        return ObjectIdentifier(self).hashValue
    }
}
extension AVPlayer : @retroactive Identifiable {
    public var id: Int {
        return ObjectIdentifier(self).hashValue
    }
}
enum SelectionType {
    case images
    case videos
    
    var stringValue: String {
        switch self {
        case .images:
            return "Images"
        case .videos:
            return "Videos"
        }
    }
}


struct ImageViewer : View {
    @Binding  var images: [UIImage]
    @Binding  var selectedImage: UIImage?
    @Binding var showPicker: Bool
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    let maxLimit = 10
    
    var body: some View {
        if images.isEmpty {
            // Show upload icon first time
            VStack {
                Image(systemName: "square.and.arrow.up.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.white)
            }
            .onTapGesture {
                showPicker = true
            }
            
        } else {
            // Show grid of selected images
            ScrollView{
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, img in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90,  height: 90)    // static height
                                .clipped()
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedImage = img

                                }
                            // Cross button
                            Button {
                                images.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .offset(x: -5, y: 5)
                        }
                    }
                    
                    // Add new image cell
                    if images.count < maxLimit {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Upload")
                        }
                        .frame(width: 90,  height: 90)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .onTapGesture {
                            showPicker = true
                        }
                    }
                }
                .padding()
            }
            
        }
    }
}



struct VideoViewer: View {
    // Input properties
    var videoURL: URL? // The URL passed from the parent
    @Binding var selectedur: URL?
    @Binding var showVideoPicker: Bool
    
    @Binding var parsePlayer:AVPlayer?
    
    // Use a computed property for the player, or better, a @State property
    // that updates when videoURL changes. Let's use a simple State for the AVPlayer.
    @State private var player: AVPlayer?
    
    var body: some View {
        // Use the optional binding to drive the UI
        if selectedur == nil {
            // Show upload icon first time (when videoURL is nil)
            VStack {
                // ... (upload icon code)
                Image(systemName: "square.and.arrow.up.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.white)
            }
            .onTapGesture {
                showVideoPicker = true
            }
            
        } else {
            // Show the Video Player (when selectedur is NOT nil)
            ZStack(alignment: .topTrailing) {
                
                // 2. Video Player: Ensure player exists
                if let player = player {
                    VideoPlayerContainer(player: player, ismute: true) // ismute: false for music
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                            // IMPORTANT: Stop accessing the resource when done.
                            selectedur?.stopAccessingSecurityScopedResource()
                        }
                        .onTapGesture {
                            parsePlayer = player
                        }
                }
                
                // 3. Cross button to remove the video
                Button {
                    player?.pause()
                    player = nil
                    selectedur?.stopAccessingSecurityScopedResource() // Stop access before removing
                    selectedur = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30,height: 30)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .padding(5)
                    
                }
                .offset(x: -10, y: 15)
            }
            // ⭐️ FIX: Create/Update the player whenever the external URL changes
            .onChange(of: selectedur) { oldValue, newURL in
                if let url = newURL {
                    player = AVPlayer(url: url)
                    // The .onAppear will call player.play()
                } else {
                    player = nil
                }
            }
            .onAppear {
                if player == nil, let url = selectedur {
                    player = AVPlayer(url: url)
                }
            }
        }
    }
}

