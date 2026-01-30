import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let accentColor: Color
    
    init(progress: Double, accentColor: Color = .blue) {
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 12)
    }
}
