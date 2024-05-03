import SwiftUI

struct TemporaryErrorMessageView: View {
    @Binding var errorMessage: String?
    @State private var opacity: Double = 0

    var body: some View {
        Group {
            if let message = errorMessage, !message.isEmpty {
                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.green.opacity(0.85)) // Change background color to green
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .frame(maxWidth: .infinity)
                    .opacity(opacity)
                    .onAppear {
                        // Fade in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            opacity = 1
                        }
                        // Fade out after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                opacity = 0
                            }
                            // Reset errorMessage after fading out
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                errorMessage = nil
                            }
                        }
                    }
                    .onChange(of: errorMessage) { _ in
                        opacity = 1
                        // Fade out after 2 seconds when errorMessage changes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                opacity = 0
                            }
                        }
                    }
            }
        }
        .transition(.opacity)
    }
}
