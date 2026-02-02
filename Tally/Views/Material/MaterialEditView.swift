import SwiftUI

struct MaterialEditView: View {
    @Environment(\.dismiss) private var dismiss

    let material: Material?
    let examDate: Date?
    let weeklyTargetDays: Int
    let onSave: (String, Int, String, Int, String, Date?, Bool) -> Void

    @State private var name: String = ""
    @State private var totalAmount: String = ""
    @State private var unit: String = "ページ"
    @State private var dailyQuota: String = ""
    @State private var quotaMode: String = "manual"
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date()
    @State private var useWeeklyTarget: Bool = false

    private let units = ["ページ", "問", "時間"]
    private let quotaModes = ["manual", "auto"]

    var isEditing: Bool {
        material != nil
    }

    var isValid: Bool {
        let nameValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let totalValid = (Int(totalAmount) ?? 0) > 0
        if quotaMode == "manual" {
            return nameValid && totalValid && (Int(dailyQuota) ?? 0) > 0
        } else {
            return nameValid && totalValid
        }
    }

    private var totalLabel: String {
        unit == "時間" ? "目標時間（時間）" : "総量"
    }

    private var quotaLabel: String {
        unit == "時間" ? "1日のノルマ（分）" : "1日のノルマ"
    }

    private var quotaUnit: String {
        unit == "時間" ? "分" : unit
    }

    private var autoQuotaPreview: Int {
        let total = unit == "時間" ? (Int(totalAmount) ?? 0) * 60 : (Int(totalAmount) ?? 0)
        let remaining = total
        let actualRemaining = material != nil ? material!.remainingAmount : remaining
        let deadlineDate = hasDeadline ? deadline : (examDate ?? Date())
        let today = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: deadlineDate)
        let daysLeft = max(1, Calendar.current.dateComponents([.day], from: today, to: target).day ?? 1)
        if useWeeklyTarget {
            let effectiveDays = max(1.0, Double(daysLeft) * Double(weeklyTargetDays) / 7.0)
            return Int(ceil(Double(actualRemaining) / effectiveDays))
        } else {
            return Int(ceil(Double(actualRemaining) / Double(daysLeft)))
        }
    }

    private var autoQuotaPreviewText: String {
        let value = autoQuotaPreview
        if unit == "時間" {
            let hours = value / 60
            let minutes = value % 60
            if hours > 0 && minutes > 0 {
                return "→ 1日あたり 約 \(hours)時間\(minutes)分"
            } else if hours > 0 {
                return "→ 1日あたり 約 \(hours)時間"
            } else {
                return "→ 1日あたり 約 \(minutes)分"
            }
        } else {
            return "→ 1日あたり 約 \(value) \(unit)"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("教材情報") {
                    TextField("教材名", text: $name)

                    HStack {
                        Text(totalLabel)
                        Spacer()
                        TextField("0", text: $totalAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Picker("単位", selection: $unit) {
                        ForEach(units, id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("ノルマ計算方法") {
                    Picker("計算方法", selection: $quotaMode) {
                        Text("手動設定").tag("manual")
                        Text("自動計算").tag("auto")
                    }
                    .pickerStyle(.segmented)
                }

                if quotaMode == "manual" {
                    Section(quotaLabel) {
                        HStack {
                            Text("ノルマ")
                            Spacer()
                            TextField("0", text: $dailyQuota)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text(quotaUnit)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section("自動計算設定") {
                        Toggle("終了期限を設定", isOn: $hasDeadline)

                        if hasDeadline {
                            DatePicker(
                                "期限日",
                                selection: $deadline,
                                displayedComponents: .date
                            )
                        }

                        Toggle("週間目標日数を反映", isOn: $useWeeklyTarget)
                    }

                    Section("ノルマプレビュー") {
                        Text(autoQuotaPreviewText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(isEditing ? "教材を編集" : "教材を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let total: Int
                        if unit == "時間" {
                            total = (Int(totalAmount) ?? 0) * 60
                        } else {
                            total = Int(totalAmount) ?? 0
                        }
                        let savedDailyQuota: Int
                        if quotaMode == "auto" {
                            savedDailyQuota = autoQuotaPreview
                        } else {
                            savedDailyQuota = Int(dailyQuota) ?? 0
                        }
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            total,
                            unit,
                            savedDailyQuota,
                            quotaMode,
                            hasDeadline ? deadline : nil,
                            useWeeklyTarget
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let material {
                    name = material.name
                    if material.unit == "時間" {
                        totalAmount = String(material.totalAmount / 60)
                    } else {
                        totalAmount = String(material.totalAmount)
                    }
                    unit = material.unit
                    dailyQuota = String(material.dailyQuota)
                    quotaMode = material.quotaMode
                    useWeeklyTarget = material.useWeeklyTarget
                    if let materialDeadline = material.deadline {
                        hasDeadline = true
                        deadline = materialDeadline
                    }
                } else {
                    if let examDate {
                        deadline = examDate
                    }
                }
            }
        }
    }
}
