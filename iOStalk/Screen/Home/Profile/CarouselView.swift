//
//  CarouselView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 09/01/26.
//

import Foundation
import SwiftUI


struct CarouselView: View {
    var items: [Post]
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
                                    if let img = items[index].imgurl {
                                        CachedImageView(url: img)
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
