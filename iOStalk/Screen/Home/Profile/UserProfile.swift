//
//  DetailView.swift
//  reelsView
//
//  Created by Ishpreet Singh on 27/11/25.


import SwiftUI
import AVKit

struct UserProfile: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var isMenuOpen : Bool
    
    @State private var  user : UserModal? = nil
    @State private var post : Post? = nil
    @State private var reels: [UserData]  = {

        guard let ima1 = Bundle.main.url(forResource: "Hamburger", withExtension: "jpg"),
                let ima2 = Bundle.main.url(forResource: "foos", withExtension: "jpg"),
                let ima3 = Bundle.main.url(forResource: "images", withExtension: "jpeg") else {
              return []
          }

          let images = [ima1, ima2, ima3, ima2, ima1]
        return images.map { url in
                UserData(
                    url: nil,
                    caption: "Local Image",
                    player: nil,
                    imageurl: url,
                    img: UIImage(contentsOfFile: url.path)
                )
            }
    }()
 

         
    @State private var selectedIndex: Int = 0
    @State private var isfscreenull: Bool = false
    @Namespace private var carouselNamespace
    
    private var columns: [GridItem] {
            let count = min(reels.count, 3) // max 3 columns
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
        }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack{
                    Image(systemName: "chevron.left")
                        .resizable()
                        .frame(width: 13, height: 20)
                        .foregroundStyle(.white)
                        .onTapGesture {
                            dismiss()
                        }
                    Spacer()
                }.padding(.horizontal, 20)
                    .padding(.top, 20)
              Spacer()
                    
                Text("Detail Screen")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(reels.indices, id: \.self) { index in
                            if let img = reels[index].img {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: (UIScreen.main.bounds.width - CGFloat(columns.count + 1) * 8) / CGFloat(columns.count),
                                        height: (UIScreen.main.bounds.width - CGFloat(columns.count + 1) * 8) / CGFloat(columns.count)
                                    )
                                    .clipped()
                                    .cornerRadius(19)
                                    .onTapGesture {
                                        withAnimation {
                                            isfscreenull = true
                                            selectedIndex = index
                                        }
                                       
                                    }
                            }
                        }
                    }
                }
                
                Spacer()
                
            }
           
            
            if  isfscreenull {
                            FullScreenCarousel(
                                reels: reels,
                                onDismiss: {
                                    withAnimation {
                                        isfscreenull = false
                                        
                                    }
                                    
                                },
                                currentindex: $selectedIndex
                            )
                        }
        }
        .onAppear(perform: {
            isMenuOpen = false
        })
        .navigationBarHidden(true)
    }
}

#Preview {
    UserProfile(isMenuOpen: .constant(false))
}


struct FullScreenCarousel: View {
    let reels: [UserData]
    let onDismiss: () -> Void
    @Binding var currentindex: Int
    @State private var showBottomCarousel = false
    
    @State var selecteduserind : UserData? = nil
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack{
                HStack{
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }.padding(.horizontal, 20)
                
                Spacer()
               
                ZStack {
                    if let imgURL = reels[currentindex].img {
                        Image(uiImage: imgURL)
                            .resizable()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.4)
                            .scaledToFit()
                    }
                }
                
                
                Spacer()
                
                HStack{
                    Spacer()
                    VStack{
                        Button {
                            print("First Button Tapped")
                            withAnimation(.spring()) {
                                showBottomCarousel.toggle()   // 👈 OPEN CAROUSEL
                            }
                        } label: {
                            Image(systemName: "chevron.compact.down")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .clipShape(Circle())
                        }


                    }
                }
                
               
            }
            
            if showBottomCarousel {
                VStack{
                    Spacer()
                    CarouselView(items: reels, closeCros: $showBottomCarousel, currentindex: $currentindex, onDismi: {
                        withAnimation {
                            showBottomCarousel = false
                        }
                       
                    })
                  
                }
             
                        }
           
        }
    }

}
struct CarouselView: View {
    var items: [UserData]
    @Binding var closeCros: Bool
    @Binding var currentindex: Int
    
    var onDismi: () -> Void
    
    let cardWidth: CGFloat = 240
    let cardHeight: CGFloat = 280

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack {
                // Header with Close Button
                HStack {
                    Button {
                        onDismi()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }.padding(.bottom, 30)
                
                // 1. Wrap the ScrollView in a ScrollViewReader
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(items.indices, id: \.self) { index in
                                ZStack {
                                    if let img = items[index].img {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: cardWidth, height: cardHeight)
                                            .clipShape(RoundedRectangle(cornerRadius: 25))
                                            .shadow(radius: 5)
                                            .onTapGesture {
                                                withAnimation {
                                                    closeCros = false
                                                    currentindex = index
                                                }
                                            }
                                    } else {
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: cardWidth, height: cardHeight)
                                    }
                                }
                                .id(index) // 2. IMPORTANT: Give every item a unique ID
                                
                                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                                        .opacity(phase.isIdentity ? 1.0 : 0.6)
                                        .rotation3DEffect(
                                            .degrees(phase.value * -5),
                                            axis: (x: 0, y: 1, z: 0)
                                        )
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, (UIScreen.main.bounds.width - cardWidth) / 2)
                    
                    // 3. FIX: Instantly jump to the index when the view appears (no animation)
                    .onAppear {
                        // Use a tiny delay to ensure the layout is loaded before calling scrollTo
                        
                            
                            proxy.scrollTo(currentindex, anchor: .center)
                        
                    }
                    
                    // 4. Keep the smooth transition for subsequent changes (e.g., if index changes from parent)
                    .onChange(of: currentindex) { oldValue, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) { // Optional: Keep smooth scroll when index is changed programmatically
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .frame(height: UIScreen.main.bounds.height / 2)
    }
}
//struct CarouselView: View {
//    var items: [UserData]
//    @Binding var closeCros:Bool
//    @Binding var currentindex :Int
//    
//     var onDismi : () -> Void
//    // Configuration for card size
//    let cardWidth: CGFloat = 240
//    let cardHeight: CGFloat = 280
//
//    var body: some View {
//        
//          
//            ZStack{
//                
//                Color.black.opacity(0.7)
//                VStack{
//                    HStack{
//                        
//                        Button {
//                            onDismi()
//                        } label: {
//                            Image(systemName: "xmark.circle.fill")
//                                .resizable()
//                                .frame(width: 35, height: 35)
//                                .foregroundColor(.white)
//                                .padding()
//                        }
//                        Spacer()
//                    }.padding(.bottom, 30)
//                    
//                   
//
//                    
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 20) { // Gap between items
//                            ForEach(items.indices, id: \.self) { index in
//                                ZStack {
//                                    if let img = items[index].img {
//                                        Image(uiImage: img)
//                                            .resizable()
//                                            .scaledToFill()
//                                            .frame(width: cardWidth, height: cardHeight)
//                                            .clipShape(RoundedRectangle(cornerRadius: 25))
//                                            .shadow(radius: 5)
//                                            .onTapGesture {
//                                                withAnimation {
//                                                    closeCros = false
//                                                    currentindex = index // update full screen
//                                                }
//                                            }
//                                    } else {
//                                        // Fallback if no image
//                                        RoundedRectangle(cornerRadius: 25)
//                                            .fill(Color.gray.opacity(0.3))
//                                            .frame(width: cardWidth, height: cardHeight)
//                                    }
//                                }
//                                // 1. This handles the "Center is Big, Sides are Small" animation visually
//                                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
//                                    content
//                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.85) // Scale: 1.0 (Center), 0.85 (Sides)
//                                        .opacity(phase.isIdentity ? 1.0 : 0.6)      // Optional: Fade sides slightly
//                                        .rotation3DEffect(
//                                            .degrees(phase.value * -5), // Optional: Slight 3D rotation
//                                            axis: (x: 0, y: 1, z: 0)
//                                        )
//                                }
//                            }
//                        }
//                        .scrollTargetLayout() // 2. Essential for snapping
//                    }
//                    // 3. This creates the "Pagination" feel (Snaps to center)
//                    .scrollTargetBehavior(.viewAligned)
//                    // 4. This padding ensures the side items are visible (Peeking)
//                    .safeAreaPadding(.horizontal, (UIScreen.main.bounds.width - cardWidth) / 2)
//                    
//                    Spacer()
//                }
//            }
//            .frame(height: UIScreen.main.bounds.height / 2)
//        
//      
//    }
//}


