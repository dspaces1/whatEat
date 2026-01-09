import SwiftUI

struct ImportRecipePlaceholderView: View {
    private let gradientColors = [
        Color(red: 0.99, green: 0.86, blue: 0.80),
        Color(red: 0.96, green: 0.74, blue: 0.69)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            VStack(spacing: 8) {
                Text("Import your favorite recipe")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("Drop a link or grab a photo to build a new recipe. This tab is ready for its big moment.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Button(action: {}) {
                Text("Coming Soon")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ImportRecipePlaceholderView()
}
