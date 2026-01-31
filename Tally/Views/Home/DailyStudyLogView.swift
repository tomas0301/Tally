import SwiftUI
import SwiftData

struct DailyStudyLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    let materials: [Material]
    let onUpdate: () -> Void
    
    @State private var logs: [StudyLog] = []
    
    private var calendar: Calendar { Calendar.current }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（E）"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 既存の記録
                if !logs.isEmpty {
                    Section("この日の記録") {
                        ForEach(logs, id: \.id) { log in
                            logRow(log: log)
                        }
                        .onDelete(perform: deleteLogs)
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
            .onAppear {
                fetchLogs()
            }
        }
    }
    
    // MARK: - Log Row
    
    private func logRow(log: StudyLog) -> some View {
        let material = materials.first { $0.id == log.materialId }
        let unitName = material?.unit ?? ""
        let isTime = unitName == "時間"
        
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(material?.name ?? "不明な教材")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(isTime ? formatMinutes(log.amount) : "\(log.amount) \(unitName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    adjustLog(log, by: isTime ? -5 : -1)
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                
                Button {
                    adjustLog(log, by: isTime ? 5 : 1)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
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
            addLog(materialId: material.id, amount: amount)
            // 今日の場合はMaterialの進捗も更新
            if isToday {
                material.currentProgress = min(material.currentProgress + amount, material.totalAmount)
            }
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
    
    private func addLog(materialId: UUID, amount: Int) {
        let log = StudyLog(date: date, materialId: materialId, amount: amount)
        modelContext.insert(log)
        try? modelContext.save()
        fetchLogs()
    }
    
    private func adjustLog(_ log: StudyLog, by amount: Int) {
        let newAmount = log.amount + amount
        if newAmount <= 0 {
            modelContext.delete(log)
        } else {
            log.amount = newAmount
        }
        try? modelContext.save()
        fetchLogs()
    }
    
    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
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
