import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let appSettings: AppSettings?
    let onUpdateExamDate: (Date?) -> Void
    let onUpdateWeeklyTarget: (Int) -> Void
    let onUpdateQuotaMode: (String) -> Void
    
    @State private var examDate: Date = Date()
    @State private var hasExamDate: Bool = false
    @State private var weeklyTargetDays: Int = 4
    @State private var quotaMode: String = "manual"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("試験日") {
                    Toggle("試験日を設定する", isOn: $hasExamDate)
                    
                    if hasExamDate {
                        DatePicker(
                            "試験日",
                            selection: $examDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                }
                
                Section("週間目標") {
                    Stepper(
                        "週 \(weeklyTargetDays)日",
                        value: $weeklyTargetDays,
                        in: 1...7
                    )
                }
                
                Section("ノルマ計算方法") {
                    Picker("計算方法", selection: $quotaMode) {
                        Text("手動設定").tag("manual")
                        Text("自動計算").tag("auto")
                    }
                    .pickerStyle(.segmented)
                    
                    if quotaMode == "auto" {
                        Text("残りの量と試験日までの日数から自動でノルマを計算します。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onUpdateExamDate(hasExamDate ? examDate : nil)
                        onUpdateWeeklyTarget(weeklyTargetDays)
                        onUpdateQuotaMode(quotaMode)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let settings = appSettings {
                    hasExamDate = settings.examDate != nil
                    examDate = settings.examDate ?? Date()
                    weeklyTargetDays = settings.weeklyTargetDays
                    quotaMode = settings.quotaCalculationMode
                }
            }
        }
    }
}
