//
//  MainTabbedView.swift
//  reelsView
//
//  Created by Ishpreet Singh on 28/11/25.
//

import SwiftUI

struct MainTabbedView: View {
    
    @State var selectedTab = 0
    @State  var showMenu = false
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .trailing){
                
                VStack{
                    HStack {
                        Spacer()
                        
                            Button {
                                withAnimation {
                                    showMenu = true
                                }
                                // Action for your menu button
                            } label: {
                                
                                Image(uiImage: .add)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .padding(20)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 16)
                            
                       
                       
                    }
                    
                    
                    ZStack(alignment:.bottom){
                        
                        TabView(selection: $selectedTab) {
                            HomeView()
                                .tag(0)

                            ContentView(isMenuOpen: $showMenu)
                                .tag(1)
                            
                        }
                        .toolbar(.hidden, for: .tabBar)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                
                       
                      
                        ZStack{
                            HStack{
                                ForEach((TabbedItems.allCases), id: \.self){ item in
                                    Button{
                                        selectedTab = item.rawValue
                                    } label: {
                                        CustomTabItem(imageName: item.iconName, title: item.title, isActive: (selectedTab == item.rawValue))
                                    }
                                }
                            }
                            .padding(6)
                        }
                        .frame(height: 70)
                        .background(.purple.opacity(0.2))
                        .cornerRadius(35)
                        .padding(.horizontal, 26)
                    }
                    
                    
                }
                .blur(radius: showMenu ? 10 : 0)
                
                if showMenu {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showMenu = false
                            }
                        }
                        .zIndex(1)
                        
                    RightSideMenu(isShowing: $showMenu)
                        .transition(.move(edge: .trailing)) // Slide from the trailing edge
                        .zIndex(2) // Ensure the menu is always on top
                        .gesture(
                            // Optional: Tap outside to close the menu
                            TapGesture().onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showMenu = false
                                }
                            }
                        )
                }
                
            }
          
        }
       
       
      
    }
}
struct RightSideMenu: View {
    // Allows the menu to dismiss itself
    @Binding var isShowing: Bool
    
    // We use a NavigationStack to manage navigation from the menu buttons
    var body: some View {
        // Menu Background and Shape
        VStack(alignment:.trailing,spacing: 30) {
            // Spacer to align content to the top
            Spacer()
            
            // Menu Buttons
            MenuButton(
                    title: "Settings",
                    iconName: "gearshape.fill",
                    destination: Text("Settings View"),
                    shapeType: .circle // <-- ADD THIS
                )

                // 2. Profile button (Rounded Rectangle shape)
                MenuButton(
                    title: "Profile",
                    iconName: "person.fill",
                    destination: Text("Profile View"),
                    shapeType: .roundedRectangle // <-- ADD THIS
                )

                // 3. Help button (Octagonal shape)
                MenuButton(
                    title: "Help",
                    iconName: "questionmark.circle.fill",
                    destination: Text("Help View"),
                    shapeType: .octagon // <-- ADD THIS
                )
            
            Spacer() // Pushes content up
        }
        .padding(30)
        .frame(width: UIScreen.main.bounds.width * 0.25, height: UIScreen.main.bounds.height / 2.5)
        .background(Color.white.opacity(0.5).blur(radius: 50))
        .clipShape(
            .rect(topLeadingRadius: 35, bottomLeadingRadius: 35)
        )
        .padding(.vertical, 30)
        .ignoresSafeArea(.all, edges: .vertical)
        
    }
}
struct AnyShape: Shape {
    private let makePath: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        makePath = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        makePath(rect)
    }
}
// Helper view for menu buttons
struct MenuButton<Destination: View>: View {
    let title: String
    let iconName: String
    let destination: Destination
    let shapeType: ButtonShapeType
    let size: CGFloat = 60
    
    // FIX: The return type must be the single, concrete AnyShape
    private func buttonShape() -> AnyShape {
        switch shapeType {
        case .circle:
            return AnyShape(Circle()) // Wrap in AnyShape
        case .roundedRectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 15)) // Wrap in AnyShape
        case .triangle:
            return AnyShape(Triangle()) // Wrap in AnyShape
        case .octagon:
            return AnyShape(Octagon()) // Wrap in AnyShape
        }
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack{
                VStack(spacing: 4) {
                    // Icon and Text content
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(.black)
                }
                .frame(width: size, height: size)
                
                // 2. Apply the Neumorphic (3D) Background
                .background(
                    buttonShape() // This is now a concrete AnyShape
                        .fill(Color.white)
                        // Outer Shadow
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 5, y: 5)
                        // Inner Highlight
                        .shadow(color: Color.white.opacity(0.7), radius: 5, x: -2, y: -2)
                )
                // 3. Clip the entire view with the same shape
                .clipShape(buttonShape()) // This is now a concrete AnyShape
                .buttonStyle(PressedStateStyle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .fixedSize(horizontal: true, vertical: true)
           
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// An Octagon (8-sided polygon)
struct Octagon: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        
        // Start at 90 degrees (top center) and add 8 points
        for i in 0..<8 {
            let angle = CGFloat(i) * (.pi / 4) - (.pi / 2) // Start at the top
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// Enum to easily select the shape
enum ButtonShapeType {
    case circle
    case roundedRectangle
    case triangle
    case octagon
}
struct PressedStateStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Shrink when pressed
            .brightness(configuration.isPressed ? -0.05 : 0) // Darken when pressed
    }
}

#Preview {
    MainTabbedView()
}

struct HomeView: View {
    
    
    
    var body: some View {
        
        ZStack(alignment: .bottom){
            Color.red.ignoresSafeArea()
           
            Text("Home")
        }
    }
}
struct FavoriteView: View {
   
    
    var body: some View {
       
        
        ZStack(alignment: .bottom){
            Color.green
            Text("favw")
        }
    }
}

extension MainTabbedView{
    func CustomTabItem(imageName: Image, title: String, isActive: Bool) -> some View{
        HStack(spacing: 10){
            Spacer()
            imageName
                .resizable()
                .renderingMode(.template)
                .foregroundColor(isActive ? .black : .gray)
                .frame(width: 20, height: 20)
            if isActive{
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .black : .gray)
            }
            Spacer()
        }
        .frame(width: isActive ? nil : 110, height: 60)
        .background(isActive ? .purple.opacity(0.4) : .clear)
        .cornerRadius(30)
    }
}
extension View {
    func bubbleStyle(backgroundColor: Color, foregroundTxtColor: Color = .white) -> some View {
        self.modifier(BubbleViewModifier(backgroundColor: backgroundColor, foregroundTxtColor: foregroundTxtColor))
    }
}
struct BubbleViewModifier: ViewModifier {
    let backgroundColor: Color
    let foregroundTxtColor: Color
    
    func body(content: Content) -> some View {
        content
            .padding(10)
            .foregroundColor(foregroundTxtColor)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor)
            )
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)) // Adjust external padding
    }
}
