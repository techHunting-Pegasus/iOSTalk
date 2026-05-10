//
//  Likecomentview.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 09/01/26.
//

import SwiftUI

struct Likecomentview: View {
    var post : Post
    var body: some View {
        HStack{
            //likes
            HStack{
                Image(systemName: "heart.fill")
                    .resizable()
                    .frame(width: 30,height: 30)
                    
                Text("\(post.likes ?? 0)")
                    .foregroundStyle(.white)
                    .font(.system(size: 14,weight: .bold))
            }
            //coments
            HStack{
                Image(systemName: "message.fill")
                    .resizable()
                    .frame(width: 30,height: 30)
                Text("\(post.comments ?? 0)")
                    .foregroundStyle(.white)
                    .font(.system(size: 14,weight: .bold))
            }
            Spacer()
        }
        .foregroundStyle(.white)
       
    }
}
