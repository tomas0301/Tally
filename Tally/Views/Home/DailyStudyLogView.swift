import SwiftUI
import SwiftData

struct DailyStudyLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    let materials: [Material]
    let onUpdate: () -> Void
    
    @State private var logs: [StudyLog] = []
    @State private var deleteTarget: (materialId: UUID, materialName: String, totalAmount: Int)?
    @State private var showDeleteConfirm = false
    
    private var calendar: Calendar { Calendar.current }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（E）"
        return formatter.string(from: date)
    }
    
    // 教材ごとに合算したデータ
    private var groupedLogs: [(materialId: UUID, material: Material?, totalAmount: Int)] {
        let grouped = Dictionary(grouping: logs, by: \.materialId)
        return grouped.map { (materialId, logs) in
            let total = logs.reduce(0) { $0 + $1.amount }
            let material = materials.first { $0.id == materialId }
            return (materialId: materialId, material: material, totalAmount: total)
        }
        .sorted { ($0.material?.name ?? "") < ($1.material?.name ?? "") }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 既存の記録（合算表示）
                if !groupedLogs.isEmpty {
                    Section("この日の記録") {
                        ForEach(groupedLogs, id: \.materialId) { entry in
                            groupedLogRow(entry: entry)
                        }
                    }
                }
                
                // 記録を追加
                Section("記録を追加") {
                    ForEach(materials, id: \.id) { material in
                        addRecordRow(material: material)
                    }
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        onUpdate()
                        dismiss()
                    }
                }
            }
            .alert("記録を削除", isPresented: $showDeleteConfirm) {
                Button("削除", role: .destructive) {
                    if let target = deleteTarget {
                        deleteLogsForMaterial(materialId: target.materialId, totalAmount: target.totalAmount)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                if let target = deleteTarget {
                    let material = materials.first { $0.id == target.materialId }
                    let unitName = material?.unit ?? ""
                    let isTime = unitName == "時間"
                    let amountText = isTime ? formatMinutes(target.totalAmount) : "\(target.totalAmount) \(unitName)"
                    Text("\(target.materialName)の\(amountText)分の記録を削除しますか？")
                }
            }
            .onAppear {
                fetchLogs()
            }
        }
    }
    
    // MARK: - Grouped Log Row
    
    private func groupedLogRow(entry: (materialId: UUID, material: Material?, totalAmount: Int)) -> some View {
        let unitName = entry.material?.unit ?? ""
        let isTime = unitName == "時間"
        let amountText = isTime ? formatMinutes(entry.totalAmount) : "\(entry.totalAmount) \(unitName)"
        
        return HStack {
            Text(entry.material?.name ?? "不明な教材")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(amountText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                deleteTarget = (
                    materialId: entry.materialId,
                    materialName: entry.material?.name ?? "不明な教材",
                    totalAmount: entry.totalAmount
                )
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Add Record Row
    
    private func addRecordRow(material: Material) -> some View {
        let isTime = material.unit == "時間"
        
        return HStack {
            Text(material.name)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 6) {
                if isTime {
                    recordButton(title: "+5m", material: material, amount: 5)
                    recordButton(title: "+15m", material: material, amount: 15)
                } else {
                    recordButton(title: "+1", material: material, amount: 1)
                    recordButton(title: "+10", material: material, amount: 10)
                }
            }
        }
    }
    
    private func recordButton(title: String, material: Material, amount: Int) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            addLog(material: material, amount: amount)
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 40, height: 28)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Data Operations
    
    private func fetchLogs() {
        let targetDate = calendar.startOfDay(for: date)
        let nextDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        let materialIds = materials.map(\.id)
        
        let descriptor = FetchDescriptor<StudyLog>(
            predicate: #Predicate { $0.date >= targetDate && $0.date < nextDate },
            sortBy: [SortDescriptor(\.date)]
        )
        let allLogs = (try? modelContext.fetch(descriptor)) ?? []
        logs = allLogs.filter { materialIds.contains($0.materialId) }
    }
    
    private func addLog(material: Material, amount: Int) {
        let log = StudyLog(date: date, materialId: material.id, amount: amount)
        modelContext.insert(log)
        
        // 日付に関係なく進捗を反映
        material.currentProgress = min(material.currentProgress + amount, material.totalAmount)
        
        try? modelContext.save()
        fetchLogs()
    }
    
    private func deleteLogsForMaterial(materialId: UUID, totalAmount: Int) {
        let targetDate = calendar.startOfDay(for: date)
        let nextDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        
        let descriptor = FetchDescriptor<StudyLog>(
            predicate: #Predicate { $0.date >= targetDate && $0.date < nextDate && $0.materialId == materialId }
        )
        if let logsToDelete = try? modelContext.fetch(descriptor) {
            for log in logsToDelete {
                modelContext.delete(log)
            }
        }
        
        // 進捗から減算
        if let material = materials.first(where: { $0.id == materialId }) {
            material.currentProgress = max(0, material.currentProgress - totalAmount)
        }
        
        try? modelContext.save()
        fetchLogs()
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)時間\(m)分" }
        if h > 0 { return "\(h)時間" }
        return "\(m)分"
    }
}
