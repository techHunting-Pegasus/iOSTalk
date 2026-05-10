import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @AppStorage("isLogin") private var isLogin: Bool = false

    var body: some View {
        if isActive {
            
                if isLogin{
                    MainTabbedView()
                }else{
                    EmailVC()
                }
                
            
        } else {
            ZStack {
                LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                    
                    Text("iOStalk")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
#Preview {
    SplashScreen()
}
