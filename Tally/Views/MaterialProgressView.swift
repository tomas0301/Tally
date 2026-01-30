import SwiftUI

struct MaterialProgressView: View {
    let material: Material
    let onRecord: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(material.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))
            
            HStack(spacing: 12) {
                ProgressBarView(progress: material.progressRate)
                
                Text("\(material.progressPercent)%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
                
                HStack(spacing: 6) {
                    ProgressButton(title: "+1") {
                        onRecord(1)
                    }
                    ProgressButton(title: "+10") {
                        onRecord(10)
                    }
                }
            }
            
            Text("\(material.currentProgress) / \(material.totalAmount) \(material.unit)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct ProgressButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 40, height: 32)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
