//
//  UserProfile.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 30/11/25.
//

import SwiftUI
import AVKit

struct Reel: Identifiable {
    let id = UUID()
    let url: URL
    let caption: String
    var player: AVPlayer
    var isplaying: Bool = true
}

struct UserData: Identifiable {
    let id = UUID()
    let url: URL?            // video OR nil
    let caption: String
    var player: AVPlayer?    // only for video
    var imageurl: URL?       // only for image
    
    var isVideo: Bool {
        url != nil
    }
    var img: UIImage?
}





struct VideoPlayerContainer: UIViewControllerRepresentable {
    var player : AVPlayer
    var ismute: Bool = false
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    var controls: Bool = false
    func makeUIViewController(context: Context) -> AVPlayerViewController
    {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = controls
        controller.videoGravity = videoGravity
        controller.player?.isMuted = ismute
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) { } }



struct ReelPlayerView: View {
    @Binding var reel: Reel
    var isActive: Bool
    
    var body: some View {
        ZStack {
            VideoPlayerContainer(player: reel.player)
                .onAppear {
                    if isActive { reel.player.play() }
                }
                .onChange(of: isActive) { _, active in
                    active ? reel.player.play() : reel.player.pause()
                }
                .onDisappear {
                    reel.player.pause()
                }
                .ignoresSafeArea()
            
            Image(systemName: reel.isplaying ? "pause.fill" : "play.fill")
                           .resizable()
                           .frame(width: 40, height: 40)
                           .foregroundColor(.white)
                           .onTapGesture {
                               if reel.isplaying  {
                                   reel.player.pause()
                               } else {
                                   reel.player.play()
                               }
                               reel.isplaying .toggle()
                           }
            
            // Play/Pause Icon
            VStack {
                Spacer()
                Text(reel.caption)
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
            }
        }
    }
}

struct UserProfileView: View {
    @Binding var isMenuOpen: Bool
    @State private var currentIndex = 0
    @State private var showDetail = false
    @State private var dragOffset: CGFloat = 0
       
    @State private var reels: [Reel] = {
        let list: [[String: String]] = [
            
                [
                    "url": "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                    "caption": "Sample Reel One"
                ],
                [
                    "url": "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                    "caption": "Sample Reel Two"
                ],
                [
                    "url": "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                    "caption": "Sample Reel Three"
                ]
            ]
        
        return list.compactMap { dict in
                guard let urlString = dict["url"],
                      let caption = dict["caption"],
                      let url = URL(string: urlString)
                else { return nil }
                
                return Reel(
                    url: url,
                    caption: caption,
                    player: AVPlayer(url: url)
                )
            }
         }()
    
    
    var body: some View {
        ZStack{
            TabView(selection: $currentIndex) {
               
                ForEach(reels.indices, id: \.self) { index in
                    ZStack{
                        ReelPlayerView(
                            reel: $reels[index],
                            isActive: currentIndex == index
                        )
                        .tag(index)
                        VStack{
                            Spacer()
                            Text("dfvjhbdfj")
                        }
                    }
                   
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            .offset(y: dragOffset)
            .gesture(dragGesture)

            
        }.onAppear(perform: {
//            let imageURL = URL(string: "https://picsum.photos/300")!
//            let videoURL = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!
            
//            guard   let videoURL = Bundle.main.url(forResource: "gyn", withExtension: "mp4")else{
//                print("video is not frsth")
//                return
//            }
//            guard  let imageURL = Bundle.main.url(forResource: "Hamburger", withExtension: "jpg")else{
//                print("image not fetch")
//                return
//            }
//            // Image
//            ContentClassifier.shared.classifyImage(url: imageURL) { label in
//                print("Image category:", label ?? "Unknown")
//            }
//
//            // Video
//            ContentClassifier.shared.classifyVideo(url: videoURL) { label in
//                print("Video category:", label ?? "Unknown")
//            }
        })
        .onChange(of: showDetail) { oldValue, newValue in
            if newValue == true {
                // Bottom view opened → pause reel
                reels[currentIndex].player.pause()
            } else {
                // Bottom view closed → resume reel
                reels[currentIndex].player.play()
            }
            reels[currentIndex].isplaying.toggle()
        }
        .onChange(of: isMenuOpen, { oldValue, newval in
            if newval == true {
                // Menu opened → pause reel
                reels[currentIndex].player.pause()
            } else {
                // Menu closed → resume reel
                reels[currentIndex].player.play()
            }
            reels[currentIndex].isplaying.toggle()
        })
        .sheet(isPresented: $showDetail, onDismiss: {
            
        }, content: {
            UserProfile(isMenuOpen: $isMenuOpen)
                .transition(.move(edge: .bottom))
        })
        
       }
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height < 0 {  // Only UP swipe
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                
                let threshold: CGFloat = -120  // How much drag to trigger
                
                if value.translation.height < threshold {
                    
                    showDetail = true
                    
                }
                
                // Reset animation
                withAnimation(.spring()) {
                    dragOffset = 0
                }
            }
    }
}





