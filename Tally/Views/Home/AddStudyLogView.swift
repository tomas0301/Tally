import SwiftUI
import SwiftData

struct AddStudyLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let materials: [Material]
    let onSave: () -> Void
    
    @State private var selectedDate: Date = Date()
    @State private var selectedMaterialId: UUID?
    @State private var amount: Int = 0
    
    private var selectedMaterial: Material? {
        guard let id = selectedMaterialId else { return nil }
        return materials.first { $0.id == id }
    }
    
    private var isTime: Bool {
        selectedMaterial?.unit == "時間"
    }
    
    private var isValid: Bool {
        selectedMaterialId != nil && amount > 0
    }
    
    private var amountDisplay: String {
        guard let material = selectedMaterial else { return "\(amount)" }
        if material.unit == "時間" {
            return formatMinutes(amount)
        }
        return "\(amount)"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("日付") {
                    DatePicker(
                        "日付",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                }
                
                Section("教材") {
                    Picker("教材", selection: $selectedMaterialId) {
                        Text("選択してください").tag(UUID?.none)
                        ForEach(materials, id: \.id) { material in
                            Text(material.name).tag(UUID?.some(material.id))
                        }
                    }
                }
                
                if selectedMaterialId != nil {
                    Section("記録量") {
                        HStack {
                            Spacer()
                            Text(amountDisplay)
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            if isTime {
                                quickButton(title: "+5m", add: 5)
                                quickButton(title: "+15m", add: 15)
                                quickButton(title: "+30m", add: 30)
                                quickButton(title: "+60m", add: 60)
                            } else {
                                quickButton(title: "+1", add: 1)
                                quickButton(title: "+5", add: 5)
                                quickButton(title: "+10", add: 10)
                                quickButton(title: "+50", add: 50)
                            }
                            Spacer()
                        }
                        
                        if amount > 0 {
                            HStack {
                                Spacer()
                                Button("リセット") {
                                    amount = 0
                                }
                                .font(.caption)
                                .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: selectedMaterialId) {
                amount = 0
            }
        }
    }
    
    private func quickButton(title: String, add: Int) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            amount += add
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 48, height: 32)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    private func save() {
        guard let material = selectedMaterial, amount > 0 else { return }
        
        let log = StudyLog(date: selectedDate, materialId: material.id, amount: amount)
        modelContext.insert(log)
        material.currentProgress = min(material.currentProgress + amount, material.totalAmount)
        try? modelContext.save()
        onSave()
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)時間\(m)分" }
        if h > 0 { return "\(h)時間" }
        return "\(m)分"
    }
}
