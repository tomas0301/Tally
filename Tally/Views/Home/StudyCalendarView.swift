import SwiftUI
import SwiftData

struct StudyCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let materials: [Material]
    let onSelectDate: (Date) -> Void
    let onUpdate: () -> Void

    @State private var displayedMonth: Date = Date()
    @State private var showAddLog = false
    @State private var studyLogs: [StudyLog] = []

    private var calendar: Calendar { Calendar.current }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var heatmapData: [Date: Int] {
        var result: [Date: Int] = [:]
        for log in studyLogs {
            let d = calendar.startOfDay(for: log.date)
            result[d, default: 0] += log.amount
        }
        return result
    }

    private var groupedByDate: [(date: Date, entries: [(materialId: UUID, materialName: String, total: Int, unit: String)])] {
        let materialIds = Set(materials.map(\.id))
        let filtered = studyLogs.filter { materialIds.contains($0.materialId) }
        let byDate = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.date) }

        return byDate.keys.sorted(by: >).map { date in
            let logsForDate = byDate[date]!
            let byMaterial = Dictionary(grouping: logsForDate, by: \.materialId)
            let entries = byMaterial.compactMap { (materialId, logs) -> (materialId: UUID, materialName: String, total: Int, unit: String)? in
                guard let material = materials.first(where: { $0.id == materialId }) else { return nil }
                let total = logs.reduce(0) { $0 + $1.amount }
                return (materialId: materialId, materialName: material.name, total: total, unit: material.unit)
            }
            .sorted { $0.materialName < $1.materialName }
            return (date: date, entries: entries)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offset = (firstWeekday == 1) ? 6 : firstWeekday - 2

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private var rowCount: Int {
        daysInMonth.count / 7
    }

    private func isFuture(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) > today
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) == today
    }

    private func cellColor(for date: Date) -> Color {
        let amount = heatmapData[calendar.startOfDay(for: date)] ?? 0
        if amount == 0 { return Color(.systemGray5) }
        let maxVal = max(heatmapData.values.max() ?? 1, 1)
        let intensity = Double(amount) / Double(maxVal)
        return Theme.primary.opacity(0.2 + intensity * 0.8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d（E）"
        return formatter.string(from: date)
    }

    private func formatAmount(_ total: Int, unit: String) -> String {
        if unit == "時間" {
            let h = total / 60
            let m = total % 60
            if h > 0 && m > 0 { return "\(h)時間\(m)分" }
            if h > 0 { return "\(h)時間" }
            return "\(m)分"
        }
        return "\(total) \(unit)"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // カレンダー部分（固定）
                calendarSection
                    .padding()
                    .background(Color(.systemGroupedBackground))

                Divider()

                // 学習記録リスト（スクロール）
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // 記録追加ボタン
                        Button {
                            showAddLog = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Theme.primary)
                                Text("学習記録を登録")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding()
                        }

                        Divider().padding(.leading)

                        // 日付ごとの記録
                        ForEach(groupedByDate, id: \.date) { group in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(formatDate(group.date))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)

                                ForEach(group.entries, id: \.materialId) { entry in
                                    Button {
                                        onSelectDate(group.date)
                                    } label: {
                                        HStack {
                                            Text(entry.materialName)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text(formatAmount(entry.total, unit: entry.unit))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundStyle(.quaternary)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 10)
                                    }

                                    Divider().padding(.leading)
                                }
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("学習カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        onUpdate()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddLog) {
                AddStudyLogView(materials: materials) {
                    fetchStudyLogs()
                }
            }
            .onAppear {
                fetchStudyLogs()
            }
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 12) {
            // 月ナビゲーション
            HStack {
                Button {
                    withAnimation {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }

                Spacer()

                Text(monthTitle)
                    .font(.headline)

                Spacer()

                Button {
                    let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    let nextMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
                    if nextMonthStart <= today {
                        withAnimation { displayedMonth = nextMonth }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
                .disabled({
                    let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    let nextMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
                    return nextMonthStart > today
                }())
            }

            // 曜日ヘッダー
            let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // カレンダーグリッド（固定行数）
            let days = daysInMonth
            VStack(spacing: 8) {
                ForEach(0..<rowCount, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            if index < days.count, let date = days[index] {
                                Button {
                                    if !isFuture(date) { onSelectDate(date) }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.subheadline)
                                            .fontWeight(isToday(date) ? .bold : .regular)
                                            .foregroundStyle(isFuture(date) ? .quaternary : .primary)

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isFuture(date) ? Color.clear : cellColor(for: date))
                                            .frame(height: 4)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(isToday(date) ? Theme.primary.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .disabled(isFuture(date))
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                            }
                        }
                    }
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                        let nextMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
                        if nextMonthStart <= today {
                            withAnimation { displayedMonth = nextMonth }
                        }
                    } else if value.translation.width > 50 {
                        withAnimation {
                            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                        }
                    }
                }
        )
    }

    private func fetchStudyLogs() {
        let materialIds = materials.map(\.id)
        let descriptor = FetchDescriptor<StudyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allLogs = (try? modelContext.fetch(descriptor)) ?? []
        studyLogs = allLogs.filter { materialIds.contains($0.materialId) }
    }
}
