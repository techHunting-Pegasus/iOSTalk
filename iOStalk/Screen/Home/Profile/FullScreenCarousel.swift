//
//  FullScreenCarousel.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 09/01/26.
//

import SwiftUI
import Kingfisher


struct FullScreenCarousel: View {
    let post: [Post]
    let onDismiss: () -> Void
    @Binding var currentindex: Int
    @State private var showBottomCarousel = false
    
    @State var selecteduserind : UserData? = nil
    
    @State private var imageSize: CGSize = .zero
    

    private func calculatedHeight(
        containerWidth: CGFloat,
        imageSize: CGSize
    ) -> CGFloat {

        guard imageSize.width > 0 else { return 300 }

        let aspectRatio = imageSize.height / imageSize.width
        let height = containerWidth * aspectRatio

        // Clamp height (TikTok style)
        return min(max(height, 250), 520)
    }

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

                VStack(alignment: .leading, spacing: 8) {

                    // Caption
                    if let caption = post[currentindex].caption, !caption.isEmpty {
                        Text(caption)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(3)
                            .padding(.horizontal)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .topTrailing) {

                            if let imgURL = post[currentindex].imgurl {
                                KFImage(URL(string: imgURL))
                                    .resizable()
                                    .onSuccess { result in
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            imageSize = result.image.size
                                        }
                                    }
                                    .scaledToFill()
                                    .frame(
                                        width: geo.size.width,
                                        height: calculatedHeight(
                                            containerWidth: geo.size.width,
                                            imageSize: imageSize
                                        )
                                    )
                                    .clipped()
                            }

                            Postmenuview(post: post[currentindex])
                                .padding(12)
                        }
                    }
                    .frame(height: calculatedHeight(
                        containerWidth: UIScreen.main.bounds.width,
                        imageSize: imageSize
                    ))
                    
                    Likecomentview(post: post[currentindex])
                }

                
                
                Spacer()
                
                HStack{
                    Spacer()
 
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showBottomCarousel.toggle()
                        }
                    } label: {
                        Image(systemName: "text.rectangle.page.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
                    }.padding(.trailing, 20)
                        
                    
                }
                
                
            }
            
            if showBottomCarousel {
                VStack{
                    Spacer()
                    CarouselView(items: post, closeCros: $showBottomCarousel, currentindex: $currentindex, onDismi: {
                        withAnimation {
                            showBottomCarousel = false
                        }
                        
                    })
                    
                }
                
            }
            
        }
    }
    
}
