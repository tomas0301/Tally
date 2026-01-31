import SwiftUI

struct HeatmapView: View {
    let data: [Date: Int]
    let months: Int
    let onTap: () -> Void
    
    init(data: [Date: Int], months: Int = 4, onTap: @escaping () -> Void = {}) {
        self.data = data
        self.months = months
        self.onTap = onTap
    }
    
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    private let weekDayLabels = ["月", "", "水", "", "金", "", ""]
    
    private var calendar: Calendar { Calendar.current }
    
    private var dateRange: (start: Date, end: Date) {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .month, value: -months, to: today) ?? today
        let weekday = calendar.component(.weekday, from: start)
        let daysToMonday = (weekday == 1) ? 6 : weekday - 2
        let adjustedStart = calendar.date(byAdding: .day, value: -daysToMonday, to: start) ?? start
        return (adjustedStart, today)
    }
    
    private var weeks: [[Date?]] {
        let range = dateRange
        var result: [[Date?]] = []
        var currentDate = range.start
        
        while currentDate <= range.end {
            var week: [Date?] = []
            for _ in 0..<7 {
                if currentDate <= range.end {
                    week.append(currentDate)
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                } else {
                    week.append(nil)
                }
            }
            result.append(week)
        }
        
        return result
    }
    
    private var maxValue: Int {
        data.values.max() ?? 1
    }
    
    private func intensity(for date: Date) -> Double {
        guard let value = data[calendar.startOfDay(for: date)], maxValue > 0 else { return 0 }
        return Double(value) / Double(maxValue)
    }
    
    private func cellColor(for date: Date) -> Color {
        let level = intensity(for: date)
        if level == 0 {
            return Color(.systemGray5)
        }
        return Color.blue.opacity(0.2 + level * 0.8)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("学習記録")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .top, spacing: cellSpacing) {
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(weekDayLabels[i])
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing) {
                        ForEach(0..<weeks.count, id: \.self) { weekIndex in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    if let date = weeks[weekIndex][dayIndex] {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(cellColor(for: date))
                                            .frame(width: cellSize, height: cellSize)
                                    } else {
                                        Color.clear
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}
