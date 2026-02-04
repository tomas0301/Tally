import SwiftUI

struct DailyQuotaView: View {
    let quotas: [(name: String, todayAmount: Int, quota: Int, unit: String)]
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("📖")
                    .font(.title3)
                Text("今日のノルマ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
            }

            if quotas.isEmpty {
                Text("教材を追加してください")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(quotas, id: \.name) { item in
                    let isAchieved = item.todayAmount >= item.quota && item.quota > 0
                    HStack {
                        Text(item.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formatDisplay(todayAmount: item.todayAmount, quota: item.quota, unit: item.unit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(isAchieved ? .green : .primary)
                        if isAchieved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .modifier(Theme.shadow())
        .onTapGesture {
            onTap?()
        }
    }

    private func formatDisplay(todayAmount: Int, quota: Int, unit: String) -> String {
        if unit == "時間" {
            return "\(formatMinutes(todayAmount)) / \(formatMinutes(quota))"
        }
        return "\(todayAmount) / \(quota) \(unit)"
    }

    private func formatMinutes(_ total: Int) -> String {
        let h = total / 60
        let m = total % 60
        if h > 0 && m > 0 { return "\(h)時間\(m)分" }
        if h > 0 { return "\(h)時間" }
        return "\(m)分"
    }
}
