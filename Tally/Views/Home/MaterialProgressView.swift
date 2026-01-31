import SwiftUI

struct MaterialProgressView: View {
    let material: Material
    let onRecord: (Int) -> Void
    
    private var isTimeUnit: Bool {
        material.unit == "時間"
    }
    
    private var progressText: String {
        if isTimeUnit {
            return "\(formatMinutes(material.currentProgress)) / \(formatMinutes(material.totalAmount))"
        }
        return "\(material.currentProgress) / \(material.totalAmount) \(material.unit)"
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 {
            return "\(h)時間\(m)分"
        } else if h > 0 {
            return "\(h)時間"
        } else {
            return "\(m)分"
        }
    }
    
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
                    if isTimeUnit {
                        ProgressButton(title: "+5m") {
                            onRecord(5)
                        }
                        ProgressButton(title: "+15m") {
                            onRecord(15)
                        }
                    } else {
                        ProgressButton(title: "+1") {
                            onRecord(1)
                        }
                        ProgressButton(title: "+10") {
                            onRecord(10)
                        }
                    }
                }
            }
            
            Text(progressText)
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
