import SwiftUI
import SwiftData

struct QuotaSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let materials: [Material]
    let qualification: Qualification?
    let onUpdate: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(materials, id: \.id) { material in
                    NavigationLink {
                        MaterialQuotaEditView(
                            material: material,
                            examDate: qualification?.examDate,
                            weeklyTargetDays: qualification?.weeklyTargetDays ?? 4,
                            onSave: { onUpdate() }
                        )
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(material.name)
                                    .font(.body)
                                Text(material.quotaMode == "auto" ? "自動計算" : "手動設定")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatQuota(material))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            // (the formatQuota function shows the daily quota with unit)
                        }
                    }
                }
            }
            .navigationTitle("ノルマ設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        onUpdate()
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatQuota(_ material: Material) -> String {
        if material.quotaMode == "auto" {
            let quota = calculateAutoQuota(material)
            return formatAmount(quota, unit: material.unit)
        } else {
            return formatAmount(material.dailyQuota, unit: material.unit)
        }
    }

    private func calculateAutoQuota(_ material: Material) -> Int {
        let deadlineDate = material.deadline ?? qualification?.examDate
        guard let deadline = deadlineDate else { return material.dailyQuota }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: deadline)
        let daysLeft = calendar.dateComponents([.day], from: today, to: target).day ?? 0
        guard daysLeft > 0 else { return material.remainingAmount }
        let remaining = Double(material.remainingAmount)
        if material.useWeeklyTarget {
            let weeklyTarget = qualification?.weeklyTargetDays ?? 7
            let effectiveDays = max(1.0, Double(daysLeft) * Double(weeklyTarget) / 7.0)
            return Int(ceil(remaining / effectiveDays))
        } else {
            return Int(ceil(remaining / Double(daysLeft)))
        }
    }

    private func formatAmount(_ amount: Int, unit: String) -> String {
        if unit == "時間" {
            let h = amount / 60
            let m = amount % 60
            if h > 0 && m > 0 { return "\(h)時間\(m)分/日" }
            if h > 0 { return "\(h)時間/日" }
            return "\(m)分/日"
        }
        return "\(amount)\(unit)/日"
    }
}
