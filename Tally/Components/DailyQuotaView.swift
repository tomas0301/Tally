import SwiftUI

struct DailyQuotaView: View {
    let quotas: [(name: String, amount: Int, unit: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("📖")
                    .font(.title3)
                Text("今日のノルマ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
            if quotas.isEmpty {
                Text("教材を追加してください")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(quotas, id: \.name) { quota in
                    HStack {
                        Text(quota.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(quota.amount)\(quota.unit)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
