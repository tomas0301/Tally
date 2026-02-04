import SwiftUI

struct MaterialQuotaEditView: View {
    @Environment(\.dismiss) private var dismiss

    let material: Material
    let examDate: Date?
    let weeklyTargetDays: Int
    let onSave: () -> Void

    @State private var quotaMode: String = "manual"
    @State private var dailyQuota: String = ""
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date()
    @State private var useWeeklyTarget: Bool = false

    private var autoQuotaPreview: Int {
        let deadlineDate = hasDeadline ? deadline : (examDate ?? Date())
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: deadlineDate)
        let daysLeft = max(1, calendar.dateComponents([.day], from: today, to: target).day ?? 1)
        let remaining = Double(material.remainingAmount)
        if useWeeklyTarget {
            let effectiveDays = max(1.0, Double(daysLeft) * Double(weeklyTargetDays) / 7.0)
            return Int(ceil(remaining / effectiveDays))
        } else {
            return Int(ceil(remaining / Double(daysLeft)))
        }
    }

    private func formatPreview(_ amount: Int) -> String {
        if material.unit == "時間" {
            let h = amount / 60
            let m = amount % 60
            if h > 0 && m > 0 { return "約 \(h)時間\(m)分" }
            if h > 0 { return "約 \(h)時間" }
            return "約 \(m)分"
        }
        return "約 \(amount) \(material.unit)"
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("教材名")
                    Spacer()
                    Text(material.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("残り")
                    Spacer()
                    if material.unit == "時間" {
                        let h = material.remainingAmount / 60
                        let m = material.remainingAmount % 60
                        Text(h > 0 ? "\(h)時間\(m)分" : "\(m)分")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(material.remainingAmount) \(material.unit)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("ノルマ計算方法") {
                Picker("計算方法", selection: $quotaMode) {
                    Text("手動設定").tag("manual")
                    Text("自動計算").tag("auto")
                }
                .pickerStyle(.segmented)
            }

            if quotaMode == "auto" {
                Section("自動計算設定") {
                    Toggle("終了期限を設定", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("期限", selection: $deadline, in: Date()..., displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                    } else if examDate != nil {
                        HStack {
                            Text("期限")
                            Spacer()
                            Text("試験日を使用")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("週間目標日数を反映", isOn: $useWeeklyTarget)
                    if useWeeklyTarget {
                        HStack {
                            Text("週間目標")
                            Spacer()
                            Text("週\(weeklyTargetDays)日で計算")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("→ 1日あたり")
                        Spacer()
                        Text(formatPreview(autoQuotaPreview))
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primary)
                    }
                }
            } else {
                Section("1日のノルマ") {
                    HStack {
                        Text("ノルマ")
                        Spacer()
                        TextField("0", text: $dailyQuota)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(material.unit == "時間" ? "分" : material.unit)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("ノルマ設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    material.quotaMode = quotaMode
                    if quotaMode == "manual" {
                        material.dailyQuota = Int(dailyQuota) ?? material.dailyQuota
                    }
                    material.deadline = hasDeadline ? deadline : nil
                    material.useWeeklyTarget = useWeeklyTarget
                    onSave()
                    dismiss()
                }
            }
        }
        .onAppear {
            quotaMode = material.quotaMode
            dailyQuota = String(material.dailyQuota)
            hasDeadline = material.deadline != nil
            deadline = material.deadline ?? examDate ?? Date()
            useWeeklyTarget = material.useWeeklyTarget
        }
    }
}
