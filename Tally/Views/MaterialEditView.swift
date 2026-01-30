import SwiftUI

struct MaterialEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    let material: Material?
    let onSave: (String, Int, String, Int) -> Void
    
    @State private var name: String = ""
    @State private var totalAmount: String = ""
    @State private var unit: String = "ページ"
    @State private var dailyQuota: String = ""
    
    private let units = ["ページ", "問"]
    
    var isEditing: Bool {
        material != nil
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && (Int(totalAmount) ?? 0) > 0
        && (Int(dailyQuota) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("教材情報") {
                    TextField("教材名", text: $name)
                    
                    HStack {
                        Text("総量")
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
                
                Section("1日のノルマ") {
                    HStack {
                        Text("ノルマ")
                        Spacer()
                        TextField("0", text: $dailyQuota)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(unit)
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
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            Int(totalAmount) ?? 0,
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
                    totalAmount = String(material.totalAmount)
                    unit = material.unit
                    dailyQuota = String(material.dailyQuota)
                }
            }
        }
    }
}
