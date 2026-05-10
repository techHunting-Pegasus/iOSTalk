//
//  SwiftUIView.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 15/01/26.
//

import SwiftUI



struct SettingView: View {
    @Binding var isMenuOpen : Bool
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject var settingvm = SettingVM()

    var body: some View {
        AppBackgroundView {
            NavigationView {
                ZStack {
                    // IMPORTANT: Transparent Navigation background
                    LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()

                    List {
                        Accountsview()
                       

                        Section(header: Text(Appstrins.Notifications).foregroundStyle(.white)) {
                            NavigationLink(Appstrins.notificationsetting) {
                                Text("Notification Screen")
                            }
                        }
                        Privacypolicayvi()
                        

                        Section {
                            Button(role: .destructive) {
                                print("Logout tapped")
                                settingvm.logout()
                                
                            } label: {
                                Text(Appstrins.logout)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .listStyle(.insetGrouped)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing:20){
                            Image(systemName: "chevron.left")
                                .resizable()
                                .frame(width: 13, height: 20)
                                .foregroundStyle(.white)
                                .onTapGesture {
                                    dismiss()
                                }
                                .padding(.leading, 20)
                                
                            Text(Appstrins.settings)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                               
                            Spacer()
                        }
                        .frame(width: UIScreen.main.bounds.width)
                        .padding()
                        
                       
                    }
                }
                
            }
            
        }
        .navigationBarHidden(true)
        .onAppear(perform: {
            isMenuOpen = false
           
        })
        
    }
}



struct Accountsview : View {
    @State private var isPrivateAccount = false
    var body: some View {
        Section(header: Text(Appstrins.account).foregroundStyle(.white)) {

            NavigationLink(Appstrins.profile) {
                Text("Profile Screen")
            }

            HStack {
                Text(Appstrins.privateaccount)
                Spacer()
                Toggle("", isOn: $isPrivateAccount)
                    .labelsHidden()
            }

            Button(role: .destructive) {
                print("Delete Account tapped")
            } label: {
                Text(Appstrins.deleteaccount)
            }
        }
    }
}

struct Privacypolicayvi : View {
    var body: some View {
        Section(header: Text(Appstrins.about).foregroundStyle(.white)) {
            NavigationLink(Appstrins.privacypolicy) {
                Text("Privacy Policy Screen")
            }

            NavigationLink(Appstrins.termcondion) {
                Text("Terms Screen")
            }
        }
    }
}


#Preview {
    SettingView(isMenuOpen: .constant(true))
}
