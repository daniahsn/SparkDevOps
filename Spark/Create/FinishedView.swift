import SwiftUI

struct FinishedView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            BrandStyle.accent
                .ignoresSafeArea()

            VStack(spacing: 32) {

                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90)
                    .foregroundColor(.white)

                Text("Your memory has been preserved and is waiting for its moment!")
                    .font(BrandStyle.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    // Reset the create flow state
                    NotificationCenter.default.post(name: .resetCreateFlow, object: nil)

                    // Pop all the way back to CreateView
                    while path.count > 0 {
                        path.removeLast()
                    }

                    // Switch to Home tab after creating a note
                    NotificationCenter.default.post(name: .switchToHomeTab, object: nil)

                } label: {
                    Text("Done")
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
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    FinishedView(path: .constant(NavigationPath()))
}
