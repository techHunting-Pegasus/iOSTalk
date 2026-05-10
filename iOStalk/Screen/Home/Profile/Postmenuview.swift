//
//  Postmenuview.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 09/01/26.
//

import SwiftUI
import Foundation

struct Postmenuview: View {
    var post:Post
    var body: some View {
        Menu {
                Button {
                    // Edit action
                    print("Edit tapped")
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    // Delete action
                    print("Delete tapped")
                } label: {
                    Label("Delete", systemImage: "trash")
                }

            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }
}
