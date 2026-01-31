import SwiftUI

struct StudyCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    let heatmapData: [Date: Int]
    let onSelectDate: (Date) -> Void
    
    @State private var displayedMonth: Date = Date()
    
    private var calendar: Calendar { Calendar.current }
    
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
        // 月曜始まり: 月=0, 火=1, ..., 日=6
        let offset = (firstWeekday == 1) ? 6 : firstWeekday - 2
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        // 末尾を7の倍数に揃える
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }
    
    private var today: Date {
        calendar.startOfDay(for: Date())
    }
    
    private func isFuture(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) > today
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) == today
    }
    
    private func studyAmount(for date: Date) -> Int {
        heatmapData[calendar.startOfDay(for: date)] ?? 0
    }
    
    private func cellColor(for date: Date) -> Color {
        let amount = studyAmount(for: date)
        if amount == 0 { return Color(.systemGray5) }
        let maxVal = max(heatmapData.values.max() ?? 1, 1)
        let intensity = Double(amount) / Double(maxVal)
        return Color.blue.opacity(0.2 + intensity * 0.8)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
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
                        if calendar.startOfDay(for: nextMonth) <= today {
                            withAnimation {
                                displayedMonth = nextMonth
                            }
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
                .padding(.horizontal)
                
                // 曜日ヘッダー
                let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(0..<daysInMonth.count, id: \.self) { index in
                        if let date = daysInMonth[index] {
                            Button {
                                if !isFuture(date) {
                                    onSelectDate(date)
                                }
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
                                .frame(height: 40)
                                .background(
                                    isToday(date) ? Color.blue.opacity(0.1) : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .disabled(isFuture(date))
                        } else {
                            Color.clear
                                .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                            let nextMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
                            if nextMonthStart <= today {
                                withAnimation {
                                    displayedMonth = nextMonth
                                }
                            }
                        } else if value.translation.width > 50 {
                            withAnimation {
                                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                            }
                        }
                    }
            )
            .navigationTitle("学習カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
