//
//  AppBackgroundView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 05/04/25.
//

import SwiftUI

import SwiftUI

struct AppBackgroundView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            content
        }
    }
}


#Preview {
    AppBackgroundView(content: {
        Text("dfvdf")
    })
}
