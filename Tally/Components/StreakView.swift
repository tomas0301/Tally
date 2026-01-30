import SwiftUI

struct StreakView: View {
    let streak: Int
    let weeklyStudyDays: Int
    let weeklyTargetDays: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // ストリーク
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.title3)
                    Text("\(streak)日連続")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text("連続学習")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            
            // 今週の学習日数
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("📅")
                        .font(.title3)
                    Text("今週 \(weeklyStudyDays)/\(weeklyTargetDays)日")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text("週間目標")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}
