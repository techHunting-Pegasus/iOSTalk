//
//  GlobalErrorView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 04/04/25.
//

import SwiftUI

import SwiftUI

struct GlobalErrorView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .imageScale(.large)

            Text(message)
                .foregroundColor(.white)
                .font(.callout)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(radius: 5)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
struct ErrorBannerModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let msg = message {
                GlobalErrorView(message: msg)
                    .padding(.top, 40) // Adjust for notch
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                message = nil
                            }
                        }
                    }
                    .zIndex(1)
            }
        }
    }
}


extension View {
    func showErrorBanner(_ message: Binding<String?>) -> some View {
        self.modifier(ErrorBannerModifier(message: message))
    }
}


#Preview {
    GlobalErrorView(message: "this is dumy message")
}
