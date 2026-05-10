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
struct ImageUploader: View {
    @State private var images: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showPicker: Bool = false
    
    let maxLimit = 10
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    @State var selectedImage: UIImage?
    
    @State var selectiontyi : SelectionType =  .images
    @State var videoUrl: URL?
    @State var showVideoPicker: Bool = false
    @State var showVideoPreivew:Bool = false
    @State var player:AVPlayer?
    
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            VStack{
                HStack(spacing: 20) {
                    
                    // --- Images Button ---
                    Button {
                        selectiontyi = .images
                        // ⭐️ Clear video when switching to images
                        videoUrl?.stopAccessingSecurityScopedResource()
                        videoUrl = nil
                        player = nil
                    } label: {
                        Text(SelectionType.images.stringValue)
                            .foregroundStyle(selectiontyi == .images ? .white : .gray)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(selectiontyi == .images ? Color.blue : Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    // --- Videos Button ---
                    Button {
                        selectiontyi = .videos
                        // ⭐️ Clear images when switching to video
                        images.removeAll()
                    } label: {
                        Text(SelectionType.videos.stringValue)
                            .foregroundStyle(selectiontyi == .videos ? .white : .gray)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(selectiontyi == .videos ? Color.blue : Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top)
                VStack {
                    
                    if (selectiontyi == .images){
                        ImageViewer(images: $images, selectedImage: $selectedImage, showPicker: $showPicker)
                    }else{
                        VideoViewer(
                            videoURL: videoUrl, 
                            selectedur: $videoUrl,
                            showVideoPicker: $showVideoPicker,
                            parsePlayer: $player
                        )
                        
                    }
                    
                    
                }
                .frame(width: UIScreen.main.bounds.width - 20,
                       height:  UIScreen.main.bounds.height * 0.3)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
            
            
            
            
        }
        
        
        .sheet(item: $player, content: { player in
            ZStack(alignment:.center) {
                Color.black.ignoresSafeArea()
                
                VideoPlayerContainer(player: player, ismute: false,videoGravity: .resizeAspect,controls: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                        // IMPORTANT: Stop accessing the resource when done.
                        
                    }
                
            }
        })
        .sheet(item: $selectedImage) { img in
            ZStack(alignment:.center) {
                Color.black.ignoresSafeArea()
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            }
        }
        
        .onAppear {
            if let sample = UIImage(named: "foosd") {
                images.append(sample)
                images.append(sample) // Add it twice for a better grid test
            }
            if let samplee = UIImage(named: "Hamburger") {
                images.append(samplee)
                
            }
            
        }
        .onAppear(perform: {
            if let  url = Bundle.main.url(forResource: "gyn", withExtension: "mp4"){
                videoUrl = url
            }
        })
        .photosPicker(isPresented: $showVideoPicker,
                      selection: $pickerItems,
                      matching: .videos)
        .photosPicker(isPresented: $showPicker,
                      selection: $pickerItems,
                      maxSelectionCount: maxLimit - images.count,
                      matching: .images)
        .onChange(of: pickerItems) { olditem,newItems in
            Task {
                for item in newItems {
                    
                    if let data = try? await item.loadTransferable(type: Data.self){
                        if let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension {
                            if isvideo(fileExtension){
                                let videoName = UUID().uuidString + ".\(fileExtension)"
                                
                                if let fileURL = saveDataToDocumentsDir(data, with: videoName) {
                                    // Success!
                                    videoUrl = fileURL
                                    print(videoName, "sdfgdfg", fileURL)
                                } else {
                                    print("Failed to save data item to directory.")
                                }
                            }else{
                                if let img = UIImage(data: data) {
                                    
                                    // Append with limit check
                                    if images.count < maxLimit {
                                        images.append(img)
                                    }
                                }
                            }
                            
                        }
                        
                    }
                }
                pickerItems.removeAll()
            }
        }
    }
    
    func isvideo(_ pathExtension: String) -> Bool {
        
        return ["mp4", "mov", "avi"].contains(pathExtension)
    }
    private func saveDataToDocumentsDir(_ data: Data, with fileName: String) -> URL? {
        // We get the URL for the document directory
        let documentsURL = URL.documentsDirectory
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        // Now try saving our data to the fileURL
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file \(error)")
            return nil
        }
    }
}


#Preview {
    ImageUploader()
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
                                .onDrag {
                                    selectedImage = img
                                    return NSItemProvider(object: img)

                                }
                                .onDrop(of: [.image], delegate: ImageDropDelegate(destinationItem: img, images: $images, draggingItem: $selectedImage))

                            
                            
                            
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
struct ImageDropDelegate: DropDelegate {
    let destinationItem: UIImage
    @Binding var images: [UIImage]
    @Binding var draggingItem: UIImage?

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil // Reset dragging item on drop
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem else { return }
        if draggingItem != destinationItem {
            if let fromIndex = images.firstIndex(of: draggingItem),
               let toIndex = images.firstIndex(of: destinationItem) {
                if fromIndex != toIndex {
                    images.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                }
            }
        }
    }
}

//extension DraggableImage: Equatable {
//    static func == (lhs: UIImage, rhs: UIImage) -> Bool {
//        lhs.id == rhs.id
//    }
//}

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

