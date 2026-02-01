import SwiftUI

struct MarginAnnotationIcon: View {
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Connector Line Anchor (visual handled by overlay, but this is the target)
            
            // Main Bubble
            Circle()
                .fill(isSelected ? Color.blue : Color.blue.opacity(0.8))
                .frame(width: 32, height: 32)
                .shadow(radius: 2)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Badge
            if count > 1 {
                ZStack {
                    Circle()
                        .fill(Color.red)
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 16, height: 16)
                .offset(x: 10, y: -10)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

#Preview {
    HStack(spacing: 20) {
        MarginAnnotationIcon(count: 1, isSelected: false)
        MarginAnnotationIcon(count: 3, isSelected: true)
    }
    .padding()
}
