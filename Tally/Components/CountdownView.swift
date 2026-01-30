import SwiftUI

struct CountdownView: View {
    let daysUntilExam: Int?
    let onSetExamDate: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            if let days = daysUntilExam {
                Text("試験まで")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("あと")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(days)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(days <= 30 ? .red : .primary)
                    Text("日")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    onSetExamDate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                        Text("試験日を設定")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
