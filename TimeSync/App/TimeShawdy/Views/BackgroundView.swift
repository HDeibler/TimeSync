import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(GlobalColors.blue_highlight1)
                .frame(width: 400, height: 400)
                .position(x: UIScreen.main.bounds.width * 0.01, y: UIScreen.main.bounds.height * 0.01)

            Circle()
                .fill(GlobalColors.lightorange_highlight3)
                .frame(width: 450, height: 450)
                .position(x: UIScreen.main.bounds.width * 1, y: UIScreen.main.bounds.height * 1)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
struct GlobalBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            BackgroundView()
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}

extension View {
    func globalBackground() -> some View {
        self.modifier(GlobalBackgroundModifier())
    }
}
