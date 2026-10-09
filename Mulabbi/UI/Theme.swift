import SwiftUI

extension Color {
    static let mulabbiMaroon = Color(red: 0.72, green: 0.0, blue: 0.0)
    static let mulabbiRose = Color(red: 0.95, green: 0.67, blue: 0.68)
    static let mulabbiCardRose = Color(red: 0.84, green: 0.42, blue: 0.44)
    static let mulabbiRoseTint = Color(red: 0.93, green: 0.68, blue: 0.69)
}

enum AppColors {
    static let brandRed = Color.mulabbiMaroon
    static let chatBubbleGray = Color(red: 0.91, green: 0.91, blue: 0.93)
    static let surface = Color(red: 0.97, green: 0.97, blue: 0.98)
}

struct MulabbiAuthBackdrop: View {
    var body: some View {
        ZStack {
            Color.black

            Image("RoleBackground")
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .environment(\.layoutDirection, .leftToRight)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
