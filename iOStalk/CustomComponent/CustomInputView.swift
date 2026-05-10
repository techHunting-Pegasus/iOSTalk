//
//  CustomInputView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 04/04/25.
//

import SwiftUI

struct CustomInputField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var textColor: Color? = nil
    var fontSize: CGFloat? = nil
    var placeholderColor: Color = .gray.opacity(0.7)

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false
    

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(textColor ?? .gray)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(placeholderColor)
                        .font(.system(size: fontSize ?? 16))
                        .padding(.leading, 2)
                }

                if isSecure && !isPasswordVisible    {
                    SecureField("", text: $text)
                        .focused($isFocused)
                        .foregroundColor(textColor ?? .white)
                        .font(.system(size: fontSize ?? 16))
                        .autocapitalization(.none)
                        .tint(.white)
                } else {
                    TextField("", text: $text)
                        .focused($isFocused)
                        .foregroundColor(textColor ?? .white)
                        .font(.system(size: fontSize ?? 16))
                        .autocapitalization(.none)
                        .tint(.white)
                }
            }
            if isSecure {
                           Button(action: {
                               isPasswordVisible.toggle()
                           }) {
                               Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                   .foregroundColor(.gray)
                           }
                       }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}


#Preview {
    @Previewable @State var feiledText = ""
    CustomInputField(icon: "envelope", placeholder: "sf", text: $feiledText, isSecure: false)
}
