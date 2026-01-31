import SwiftUI

struct MaterialEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    let material: Material?
    let onSave: (String, Int, String, Int) -> Void
    
    @State private var name: String = ""
    @State private var totalAmount: String = ""
    @State private var unit: String = "ページ"
    @State private var dailyQuota: String = ""
    
    private let units = ["ページ", "問", "時間"]
    
    var isEditing: Bool {
        material != nil
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && (Int(totalAmount) ?? 0) > 0
        && (Int(dailyQuota) ?? 0) > 0
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
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            total,
                            unit,
                            Int(dailyQuota) ?? 0
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
                }
            }
        }
    }
}
