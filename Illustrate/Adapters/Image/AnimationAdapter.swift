import SwiftUI

struct SmoothAnimatedGradientView: View {
    var colors: [Color]

    @State private var startPoint = UnitPoint.topLeading
    @State private var endPoint = UnitPoint.bottomTrailing

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .blur(radius: 80)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            animateGradient()
        }
    }

    func animateGradient() {
        withAnimation(
            Animation.timingCurve(0.5, 0, 0.5, 1, duration: 6)
                .repeatForever(autoreverses: true)
        ) {
            startPoint = UnitPoint(x: 0.5, y: 0.2)
            endPoint = UnitPoint(x: 0.2, y: 0.5)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(
                Animation.timingCurve(0.5, 0, 0.5, 1, duration: 6)
                    .repeatForever(autoreverses: true)
            ) {
                startPoint = UnitPoint.bottomTrailing
                endPoint = UnitPoint.topLeading
            }
        }
    }
}
