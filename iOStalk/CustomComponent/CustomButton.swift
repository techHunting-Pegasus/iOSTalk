//
//  CustomButton.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 05/04/25.
//

import SwiftUI

import SwiftUI

struct ThreeDButton: View {
    var title: String
    var isLoading: Bool = false
    var action: () -> Void
    
    
    var background: Color = Color.white.opacity(0.15)
    var textColor: Color = .white
    var cornerRadius: CGFloat = 14
    
    @State private var isPressed: Bool = false
    
    
    var body: some View {
        
        Button {
            withAnimation(.easeIn(duration: 0.2)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressed = false
                }
                action()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    Text(title)
                        .bold()
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(background)
                        .shadow(color: .white.opacity(0.1), radius: 1, x: -1, y: -1)
                        .shadow(color: .black.opacity(0.4), radius: 5, x: 4, y: 4)
                    
                    if isPressed {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.black.opacity(0.1))
                    }
                }
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .cornerRadius(cornerRadius)
        }
        
        
        
    }
}


#Preview {
    ThreeDButton(title: "sdsd", action: {
        print("sdcsd")
    })
}
