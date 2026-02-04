import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let accentColor: Color
    
    init(progress: Double, accentColor: Color = Theme.primary) {
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Theme.primary, Theme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 8)
    }
}
