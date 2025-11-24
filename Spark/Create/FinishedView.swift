import SwiftUI

struct FinishedView: View {

    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            BrandStyle.accent
                .ignoresSafeArea()

            VStack(spacing: 32) {

                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90)
                    .foregroundColor(.white)

                Text("Entry successfully locked and saved!")
                    .font(BrandStyle.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    NotificationCenter.default.post(name: .resetCreateFlow, object: nil)
                    path = NavigationPath()     // ← return to root
                } label: {
                    Text("Return to Home")
                        .font(BrandStyle.button)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}
