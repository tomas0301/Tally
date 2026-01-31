import SwiftUI

struct QualificationEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    let qualification: Qualification?
    let onSave: (String, Date?, Int, String) -> Void
    
    @State private var name: String = ""
    @State private var hasExamDate: Bool = false
    @State private var examDate: Date = Date()
    @State private var weeklyTargetDays: Int = 4
    @State private var quotaMode: String = "manual"
    
    init(qualification: Qualification? = nil, onSave: @escaping (String, Date?, Int, String) -> Void) {
        self.qualification = qualification
        self.onSave = onSave
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        Form {
            Section("資格情報") {
                TextField("資格名", text: $name)
            }
            
            Section("試験日") {
                Toggle("試験日を設定する", isOn: $hasExamDate)
                if hasExamDate {
                    DatePicker("試験日", selection: $examDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }
            }
            
            Section("週間目標") {
                Stepper("週 \(weeklyTargetDays)日", value: $weeklyTargetDays, in: 1...7)
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
        .navigationTitle(qualification == nil ? "資格を追加" : "資格を編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave(
                        name.trimmingCharacters(in: .whitespaces),
                        hasExamDate ? examDate : nil,
                        weeklyTargetDays,
                        quotaMode
                    )
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            if let q = qualification {
                name = q.name
                hasExamDate = q.examDate != nil
                examDate = q.examDate ?? Date()
                weeklyTargetDays = q.weeklyTargetDays
                quotaMode = q.quotaCalculationMode
            }
        }
    }
}
