//
//  HomeBoradcast.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 25/03/26.
//

import SwiftUI
import WebKit

struct EmbedPlayerView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

struct HomeBoradcast: View {
    @Binding var isMenuOpen : Bool
    
    @StateObject var vm = HomeBroadcasterVM()
    var body: some View {
        AppBackgroundView {
            
            VStack{
                HStack{
                    Text("Popular")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    
                    Text("View all")
                        .font(.system(size: 15, weight: .medium))
                        
                }
                .foregroundStyle(.white)
                
                Spacer()
                if let url = vm.activeURL {
                       EmbedPlayerView(urlString: url)
                           .frame(height: 250)
                           .cornerRadius(12)
                           .padding(.bottom)
                   }
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) { // horizontal scroll
                    LazyHGrid(rows: [
                        GridItem(.flexible(minimum: 150)) // number of rows, adjust height
                    ], spacing: 16) { // spacing between items
                        ForEach(vm.popularlist, id: \.id) { item in
                            
                            NavigationLink {
                                MovieSearchView()
                                    .navigationTitle("Movie Checker")
                                    .navigationBarTitleDisplayMode(.large)
                            } label: {
                                
                                VStack { // each item vertically stacked
                                    CachedImageView(url: BroadcastEndpoint.getimage(id: item.posterPath ?? ""))
                                        .frame(width: 120, height: 180) // image size
                                        .cornerRadius(8)
                                    
                                    
                                    Text(item.title ?? "")
                                        .font(.caption)
                                        .frame(width: 120) // same width as image
                                        .lineLimit(2) // wrap text
                                        .multilineTextAlignment(.center)
                                }
                                

                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
               
                
                
            }.padding(.horizontal, 16)
            
          
        }.onAppear {
            vm.fetchpopular()
        }
    }
    
      
}

#Preview {
    HomeBoradcast(isMenuOpen: .constant(false))
}
