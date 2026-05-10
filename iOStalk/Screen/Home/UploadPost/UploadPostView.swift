//
//  UploadPostView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 30/11/25.
//

import SwiftUI
import Kingfisher
import PhotosUI
import AVKit


struct UploadPostView: View {
    @State var user: UserModal = AppDefaults.userData
    
    
    @State private var images: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showPicker: Bool = false
    
    let maxLimit = 10
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    @State var selectedImage: UIImage?
    
    @State var selectiontyi : SelectionType =  .images
    @State var videoUrl: URL?
    @State var videoData: Data?
    @State var showVideoPicker: Bool = false
    @State var showVideoPreivew:Bool = false
    @State var player:AVPlayer?
    @StateObject private var vm : UploadPostVM = UploadPostVM()
    @State var caption :String = ""
    @State private var filteredTags: [String] = []
    @State private var showTagSuggestions = false
    @State private var isPrivate: Bool = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        
        AppBackgroundView {
            
            
            VStack(alignment:.center){
                HStack{
            AppImages.backbuttonImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30,height: 30)
                        .foregroundStyle(.white)
                        .padding(.trailing,20)
                        .padding(.leading,10)
                        .onTapGesture {
                            dismiss()
                        }
                    CachedImageView(url: user.imgurl ?? "")
                                        .frame(width:60, height: 60)
                                        .clipShape(Circle())
                    Spacer()
                    
                }.padding(.bottom, 30)
                    .padding(.leading,20)
                
               
                VStack{
                    HStack(spacing: 20) {
                        
                        
                        SelectionButton(title: "Images", isSelected: selectiontyi == .images) {
                               selectiontyi = .images
                               videoUrl?.stopAccessingSecurityScopedResource()
                               videoUrl = nil
                               player = nil
                           }
                           
                           // VIDEOS BUTTON
                           SelectionButton(title: "Videos", isSelected: selectiontyi == .videos) {
                               selectiontyi = .videos
                               images.removeAll()
                           }
                        Spacer()
                    }
                    .padding(.leading, 20)
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
                    .background(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.blue.opacity(0.10),
                                Color.white.opacity(0.10),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blur(radius: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
                    .padding()
                    
                }
                
                CustomInputField(
                    icon: "envelope",
                    placeholder: "Capton",
                    text: $caption,
                    isSecure: false
                ).padding(.horizontal,20)
                    .onChange(of: caption) { oldvalue, newValue in
                                if let query = newValue.lastHashtagQuery {
                                    
                                    let text = query.lowercased()
                                    
                                    filteredTags = Appstrins.hashtagList.filter {
                                        $0.lowercased().contains(text)
                                    }
                                    
                                    showTagSuggestions = !filteredTags.isEmpty
                                } else {
                                    showTagSuggestions = false
                                }
                            }
                if showTagSuggestions {
                    VStack{
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(filteredTags, id: \.self) { tag in
                                    Button {
                                        insertHashtag(tag)
                                    } label: {
                                        Text(tag)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundStyle(.white)
                                    }
                                                                    }
                            }
                        }
                        
                    }.frame(width: UIScreen.main.bounds.width - 20,
                            height:  UIScreen.main.bounds.height * 0.2)
                     .background(
                         LinearGradient(
                             colors: [
                                 Color.white.opacity(0.10),
                                 Color.blue.opacity(0.10),
                                 Color.white.opacity(0.10),
                             ],
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing
                         )
                         .blur(radius: 1)
                     )
                     .overlay(
                         RoundedRectangle(cornerRadius: 16)
                             .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                     )
                     .clipShape(RoundedRectangle(cornerRadius: 16))
                     .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
                     .padding()
                     
                   
                    
                }
                HStack {
                    Text("Post Visibility")
                        .foregroundColor(.white)
                        .font(.headline)

                    Spacer()

                    Toggle("", isOn: $isPrivate)
                        .labelsHidden()
                        .tint(.purple)
                }
                .padding(.vertical)
                .padding(.horizontal,20)

                HStack {
                    Image(systemName: isPrivate ? "lock.fill" : "globe")
                        .foregroundColor(.white)
                    Text(isPrivate
                                 ? "Only your friends can view this private post."
                                 : "Your followers and friends can view this public post.")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .font(.subheadline)
                .padding(.horizontal)
                
                ThreeDButton(title: "Submit", isLoading: vm.isLoading) {
                    
                    Task{
                        await vm.uploadPost(images:images,videoURL: videoUrl,VideoData: videoData,caption: caption, isPublic: isPrivate)
                    }
                }
                .padding(.horizontal)
            
               Spacer()
            }
            
            
            
        }.navigationBarBackButtonHidden(true)
            .onChange(of: vm.imageNude, { old, new in
                if new{
                    images = []
                }
            })
            .onChange(of: vm.videoNude, { old, new in
                if new{
                    videoUrl = nil
                    videoData = nil
                }
            })
            .onChange(of: vm.uploadSuccess, { oldValue, newValue in
                if newValue == true {
                    dismiss()
                }
            })
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
//        .onAppear {
//            if let sample = UIImage(named: "foosd") {
//                images.append(sample)
//                images.append(sample) // Add it twice for a better grid test
//            }
//            if let samplee = UIImage(named: "Hamburger") {
//                images.append(samplee)
//                
//            }
//            
//        }
//        .onAppear(perform: {
//            if let  url = Bundle.main.url(forResource: "gyn", withExtension: "mp4"){
//                videoUrl = url
//            }
//        })
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
                            if vm.isvideo(fileExtension){
                                let videoName = UUID().uuidString + ".\(fileExtension)"
                                
                                if let fileURL = vm.saveDataToDocumentsDir(data, with: videoName) {
                                    // Success!
                                    videoUrl = fileURL
                                    videoData = data
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
        .onChange(of: vm.isLoading) { oldv, newv in
            if newv == false {
                DispatchQueue.main.async{
                    self.images = []
                    self.videoUrl = nil
                    self.videoData = nil
                    self.caption = ""
                    
                }
            }
        }
         
    }
        func insertHashtag(_ tag: String) {
            var words = caption.split(separator: " ").map { String($0) }

            if let last = words.last, last.hasPrefix("#") {
                words.removeLast()
            }

            words.append(tag)
            caption = words.joined(separator: " ") + " "
            showTagSuggestions = false
        }
}




#Preview {
    UploadPostView()
}



struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [.cyan.opacity(0.9), .blue.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .shadow(color: .blue.opacity(0.6), radius: 10, x: 0, y: 4)
                        } else {
                            Color.white.opacity(0.15)
                                .blur(radius: 0.5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        }
                    }
                )
                .clipShape(Capsule())
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}


struct CachedImageView: View {
    let url: String

    var body: some View {
        KFImage(URL(string: url))
                    .placeholder { placeholderView }
                    .onSuccess { result in
                        // helpful debug: prints real image size when loaded
                        print("KFImage loaded width:", result.image.size.width)
                        print("KFImage loaded height:", result.image.size.height)
                    }
                    .onFailure { error in
                        print("Imageerr", error)
                    }
                    .resizable()
                    .scaledToFill()
                    
        
    }
    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.gray.opacity(0.6))
                .padding(12)
        }
    }
}



